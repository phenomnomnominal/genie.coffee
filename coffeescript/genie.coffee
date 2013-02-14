class Chromosome
  constructor: (@genes) ->

  @Random = (numberOfGenes) ->
    genes = []
    for n in [0...numberOfGenes]
      genes[n] = Math.random() * Math.pow(2, 32) - Math.pow(2, 31)
    new Chromosome(genes)

  @Breed = (parentOne, parentTwo, mutationRate) ->
    genes = []
    for n in [0...parentOne.genes.length]
      random = Math.random()
      gene = if random < 0.5 then parentOne.genes[n] else parentTwo.genes[n]
      if random < mutationRate
        gene = Math.random() * Math.pow(2, 32) - Math.pow(2, 31)
      genes[n] = gene
    new Chromosome(genes)

Genie = do (Genie = {}, _ = {}, bestFit = null, generation = null) ->  
  _.defaultOptions =
    populationSize: 32
    mutationRate: 0.1
    survivalRate: 0.33
    useWorkers: false
    
  getBestFit = -> bestFit
  getGeneration = -> generation

  init = (options) ->
    _.options = {}

    constant = (key, value) ->
      Object.defineProperty this, key,
        get: -> value
        set: -> throw Error 'Cannot set value of constant!'
    
    constant.call _.options, 'LOGGING', _checkOptions.logging(options.logging)
    constant.call _.options, 'MUTATION_RATE', _checkOptions.mutationRate(options.mutationRate)
    constant.call _.options, 'NUMBER_OF_GENES', _checkOptions.numberOfGenes(options.numberOfGenes)
    constant.call _.options, 'POPULATION_SIZE', _checkOptions.populationSize(options.populationSize)
    constant.call _.options, 'SURVIVAL_RATE', _checkOptions.survivalRate(options.survivalRate)
    constant.call _.options, 'USE_WORKERS', _checkOptions.useWorkers(options.useWorkers)

    constant.call _.options, 'EVALUATE_FITNESS', _checkOptions.evaluateFitness(options.evaluateFitness)
    constant.call _.options, 'WORKER_SCRIPT_PATH', _checkOptions.workerScriptPath(options.workerScriptPath)
    constant.call _.options, 'WORKER_MESSAGE_HANDLER', _checkOptions.workerMessageHandler(options.workerMessageHandler)

    _.population = (Chromosome.Random(_.options.NUMBER_OF_GENES) for n in [0..._.options.POPULATION_SIZE])

    if _.options.USE_WORKERS > 0
      _.currentChromosomeIndex = []

    bestFit = fit: 0
    generation = 0
    
    constant.call _.options, 'INITIALISED', true

  run = ->
    unless _.options.INITIALISED
      throw Error 'Genie - Genie must first be initialised before the `run()` function is called.'
    generation += 1
    if _.options.LOGGING
      console.info "Genie - Starting generation #{generation}."

    if _.options.USE_WORKERS > 0
      _.workers = (null for n in [0..._.options.USE_WORKERS])
      _getParallelFitness()
    else
      _getFitness()

  reportFitness = (fitness, index) ->
    _.population[index].fit = fitness
    _.population[index].running = false

    if _.options.USE_WORKERS > 0
      _getParallelFitness()
    else
      _getFitness()


  _checkOptions =
    evaluateFitness: (evaluateFitness) ->
      unless _.options.USE_WORKERS
        unless evaluateFitness? and typeof evaluateFitness is 'function'
          throw Error 'Genie - Options Error: The fitness evalutation function must be defined.'
      evaluateFitness
    logging: (logging) ->
      if logging?
        logging = !!logging
      logging and console? and console.log? and console.warn?
    mutationRate: (mutationRate) ->
      unless 0 <= mutationRate <= 1
        if _.options.LOGGING
          console.warn 'Genie - Options Warning: Mutation rate must be a probability from 0 to 1'
          console.info 'Genie - Setting mutation rate to default value of 0.1.'
        mutationRate = _.defaultOptions.mutationRate
      mutationRate
    numberOfGenes: (numberOfGenes) ->
      unless numberOfGenes > 0
        throw Error 'Genie - Options Error: The number of genes for each Chromosome must be greater than 0.'
      numberOfGenes
    populationSize: (populationSize) ->
      unless populationSize > 0
        if _.options.LOGGING
          console.warn 'Genie - Options Warning: Population size must be greater than 0.'
          console.info 'Genie - Setting population size to default value of 32.'
        populationSize = _.defaultOptions.populationSize
      populationSize
    survivalRate: (survivalRate) ->
      unless 0 <= survivalRate <= 1
        if _.options.LOGGING
          console.warn 'Genie - Options Warning: Survival rate must be a probability from 0 to 1.'
          console.info 'Genie - Setting survival rate to default value of 0.33.'
        survivalRate = _.defaultOptions.survivalRate
      survivalRate
    useWorkers: (useWorkers) ->
      unless useWorkers? and useWorkers > 0 and Worker? and (typeof Worker is 'function' or typeof Worker is 'object')
        useWorkers = false
      useWorkers
    workerScriptPath: (workerScriptPath) ->
      if _.options.USE_WORKERS > 0
        unless workerScriptPath? and typeof workerScriptPath is 'string'
          throw Error 'Genie - Options Error: the worker script path must be defined to use WebWorkers.'
      workerScriptPath
    workerMessageHandler: (workerMessageHandler) ->
      if _.options.USE_WORKERS > 0
        unless workerMessageHandler? and typeof workerMessageHandler is 'function'
          throw Error 'Genie - Options Error: The worker message handler function must be defined to use WebWorkers.'
      workerMessageHandler

  _getNextChromosome = (population) ->
    for c in [0...population.length]
      chromosome = population[c]
      unless (chromosome.fit? or chromosome.running)
        chromosome.running = true
        return c
    for chromosome in population
      if chromosome.running
        return "STILL RUNNING"
    return "GENERATION FINISHED"

  _getFitness = ->
    chromosomeIndex = _getNextChromosome _.population
    if chromosomeIndex >= 0
      if _.options.LOGGING
        console.info "Genie - Evaluating fitness of chromosome #{chromosomeIndex + 1}."
      _.options.EVALUATE_FITNESS _.population[chromosomeIndex], chromosomeIndex
    else
      if chromosomeIndex is "GENERATION FINISHED"
        if _.options.LOGGING
          console.info "Genie - Generation #{generation} complete."
        _complete.call this
      
  _getParallelFitness = ->
    while _.workers.length < _.options.USE_WORKERS or _.workers.indexOf(null) >= 0
      chromosomeIndex = _getNextChromosome _.population
      if chromosomeIndex >= 0
        if _.options.LOGGING
          console.info "Genie - Evaluating fitness of chromosome #{chromosomeIndex + 1}."
        worker = new Worker _.options.WORKER_SCRIPT_PATH
        workerTasks = (e) ->
          if e.data.func is 'complete'
            this.terminate()
            _.workers[_.workers.indexOf(this)] = null
          if e.data.func is 'log'
            console.log(e.data.log)
        worker.addEventListener 'message', workerTasks
        worker.addEventListener 'message', _.options.WORKER_MESSAGE_HANDLER
        _.workers[_.workers.indexOf(null)] = worker
        worker.postMessage 
          func: 'evaluateFitness'
          chromosome: _.population[chromosomeIndex]
          index: 
            chromosomeIndex: chromosomeIndex
            workerIndex: _.workers.indexOf(worker)
      else
        if chromosomeIndex is "STILL RUNNING"
          for w in [0..._.workers.length]
            if _.workers[w] is null
              _.workers[w] = undefined
        if chromosomeIndex is "GENERATION FINISHED"
          if _.options.LOGGING
            console.info "Genie - Generation #{generation} complete."
          _complete()

  _complete = ->
    _.population.sort (a, b) -> b.fit - a.fit

    if _.population[0].fit > bestFit.fit
      bestFit = { genes: _.population[0].genes, fit: _.population[0].fit }
      if _.options.LOGGING
        console.info "Genie - New best fitting chomosome found with fit = #{bestFit.fit}"

    _.population = _.population[0...Math.floor(_.population.length * _.options.SURVIVAL_RATE)]

    populationWeights = (1 / Math.pow(2, n) for n in [1.._.population.length])

    getIndex = (bag) ->
      random = Math.random()
      selected = null
      for w in [0...bag.length]
        unless selected?
          if random > populationWeights[w]
            selected = w
      bag.splice(selected, 1)[0]

    while _.population.length < _.options.POPULATION_SIZE
      bag = (n for n in [0..._.population.length])
      parentOne = _.population[getIndex(bag)]
      parentTwo = _.population[getIndex(bag)]
      _.population.push Chromosome.Breed(parentOne, parentTwo, _.options.MUTATION_RATE)

    for chromosome in _.population
      delete chromosome.fit
      delete chromosome.running

    run()

  Genie =
    init: init
    run: run
    reportFitness: reportFitness
    getBestFit: getBestFit
    getGeneration: getGeneration

root = exports ? this
root.Genie = Genie