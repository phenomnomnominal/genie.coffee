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

class Genie
  init: (options, @_ = {}) ->
    @_.options = checkOptions options
    @_.population = (Chromosome.Random(@_.options.numberOfGenes) for n in [0...@_.options.populationSize])

    @bestFit = fit: 0
    @currentChromosomeIndex = 0
    @generation = 0

  checkOptions = (options) ->
    options.populationSize ?= 32
    unless options.populationSize > 0
      if options.logging?
        console.warn 'Genie - Options Warning: Population size must be greater than 0.'
        console.info 'Genie - Setting population size to 32.'
      options.populationSize = 32

    options.mutationRate ?= 0.1
    unless 0 <= options.mutationRate <= 1
      if options.logging?
        console.warn 'Genie - Options Warning: Mutation rate must be a probability from 0 to 1'
        console.info 'Genie - Setting mutation rate to 0.1.'
      options.mutationRate = 0.1

    options.survivalRate ?= 0.33
    unless 0 <= options.survivalRate <= 1
      if options.logging?
        console.warn 'Genie - Options Warning: Survival rate must be a probability from 0 to 1.'
        console.info 'Genie - Setting survival rate to 0.33.'
      options.surivalRate = 0.33

    unless options.numberOfGenes? and options.numberOfGenes > 0
      throw Error 'Genie - Options Error: The number of genes for each Chromosome must be greater than 0.'

    unless options.evaluateFitness
      throw Error 'Genie - Options Error: The fitness evalutation function for each Chromosome must be defined.'

    options

  run: ->
    @generation++
    if @_.options.logging
      console.info "Genie - Starting generation #{@generation}."
    getFitness.call this

  getFitness = ->
    getNextChromosome = (population) ->
      for c in [0...population.length]
        chromosome = population[c]
        unless chromosome.fit?
          return [chromosome, c + 1]
      []

    [@_.currentChromosome, @currentChromosomeIndex] = getNextChromosome @_.population
    if @_.currentChromosome?
      if @_.options.logging
        console.info "Genie - Evaluating fitness of chromosome #{@currentChromosomeIndex}."
      @_.options.evaluateFitness @_.currentChromosome
    else
      if @_.options.logging
        console.info "Genie - Generation #{@generation} complete."
      complete.call this

  reportFitness: (fitness) ->
    @_.currentChromosome.fit = fitness
    getFitness.call this

  complete = ->
    @_.population.sort (a, b) -> b.fit - a.fit

    if @_.population[0].fit > @bestFit.fit
      @bestFit = { genes: @_.population[0].genes, fit: @_.population[0].fit }
      if @_.options.logging
        console.info "Genie - New best fitting chomosome found with fit = #{@bestFit.fit}"
        console.info @bestFit

    @_.population = @_.population[0...Math.floor(@_.population.length * @_.options.survivalRate)]

    populationWeights = (1 / Math.pow(2, n) for n in [1..@_.population.length])

    getIndex = (bag) ->
      random = Math.random()
      selected = null
      for w in [0...bag.length]
        unless selected?
          if random > populationWeights[w]
            selected = w
      bag.splice(selected, 1)[0]

    while @_.population.length < @_.options.populationSize
      bag = (n for n in [0...@_.population.length])
      parentOne = @_.population[getIndex(bag)]
      parentTwo = @_.population[getIndex(bag)]
      @_.population.push Chromosome.Breed(parentOne, parentTwo, @_.options.mutationRate)

    chromosome.fit = null for chromosome in @_.population

    @run()

root = exports ? this
root.Genie = Genie