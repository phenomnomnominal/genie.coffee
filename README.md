## genie.coffee (v0.2.0)

Need to run a simple *[Genetic Algorithm](http://en.wikipedia.org/wiki/Genetic_algorithm)* in **[CoffeeScript](http://www.coffeescript.org)**? I did, so I wrote this library. Define your **Chromosome**, write your evaluation function and let the algorithm do its thing! Genie can now use Web Workers!

First, some definitions:

* ### **Chromosome** - 
       A Chromosome is a set of genes, which belongs to the current population.

* ### **Gene** - 
       A **Gene** is an individual piece of a **Chromosome**, which provides a single piece of information to the evaluation function. A group of **Genes** make up a **Chromosome**. When two parent **Chromosomes** come together to make a new child Chromosome, **Genes** are inherited from both parents, and can also be mutated. For now, each **Gene** is a numerical value.

* ### **Population** - 
       A set of **Chromosomes**. The whole point of a genetic algorithm is to determine the best solution to a problem by evaluating the *fitness* of each member of the population. The weakest members of the population (the **Chromosome** with the lowest fitness) are killed, and replaced by the children of the stronger **Chromosome**.

* ### **Evaluation Function** -
       The evaluation function determines the fitness of a particular **Chromosome** to the problem at hand.

## API:

### Genie.init - 

>  Initialises the genetic algorithm. Takes one required argument:
>  1. `options` - An oject containing the following properties
>    * `logging` - (boolean) - Whether Genie will log to the console or not. (Default: `false`)
>    * `mutationRate` - (number) - The chance that a given **Gene** will mutate. Must be from `0` to `1`. (Default: `0.1`)
>    * `numberOfGenes` - **REQUIRED** (number) - The number of **Genes** that are in each **Chromosome**.
>    * `populationSize` - (number) - The number of **Chromosomes** in the population. Must be positive. (Default: `32`)
>    * `survivalRate` - (number) - The chance that a given **Chromosome** survives. Must be from `0` to `1`. (Default: `0.1`)
>    * `useWorkers` - (number) - Whether Genie will try to use WebWorkers or not. (Default: `false`)
>
>    There are `3` additional properties that are required or not, depending on the value of `useWorkers`:
>    * `evaluateFitness` - **REQUIRED** if `useWorkers` is `false`. (function) - The function that determines and reports the fitness of a given **Chromsome**.
>    * `workerScriptPath` - **REQUIRED** if `useWorkers` isn't `false`. (string) - The path to the location of the Worker script that determines and reports the fitness of a given **Chromosome**.
>    * `workerMessageHandler` - **REQUIRED** if `useWorkers` isn't `false`. (function) - The function that handlers messages from the Worker script.
>
>  These options are further explained in the examples below.

### Genie.run - 

>  Starts the genetic algorithm. An error will be thrown is `Genie.init` isn't called first!

### Genie.reportFitness -

>  Records the result for a **Chromosome**. Takes two required arguments:
>  1. `fitness` - the numerical fitness score for a **Chromosome**.
>  2. `index` - the numerical index that identifies the **Chromosome**.

### Genie.getBestFit - 

>  Returns the current best fitting **Chromosome** and it's fitness score.

### Genie.getGeneration - 

>  Returns the current generation number.

## A (very) convoluted example - without WebWorkers:

Say we want to find the largest sum of a set of 8 numbers.

First, we add the compiled *genie.js* file to our page, giving us access to the Genie module:

```
<script type='text/javascript' src='libraries/genie.js'></script>
```

Then, we initialise the options for the GA. There are only **TWO** required options:

**1.** `numberOfGenes` - the number of **Genes** that are in each **Chromosome**.

**2.** `evaluateFitness` - the function that is run to evaluate the fitness of a given **Chromosome**. When the function is complete, it must call `Genie.reportFitness()` with the fitness value of that **Chromosome**. Within `evaluateFitness` you also have access to:

  * the generation number - `Genie.getGeneration()`

  * the current best fitting **Chromosome** - `Genie.getBestFit`.

  * As well as these, the actual `chromosome` and the `chromosomeIndex` are passed as parameters to the function.

There are several other optional options:

  * `populationSize` - the number of **Chromosomes** in the population. Must be a positive number. (Defaults to `32`)

  * `mutationRate` - the chance that a given **Gene** will mutate. Must be from `0` to `1`. (Defaults to `0.1`)

  * `survivalRate` - the chance that a given **Chromosome** will survive. Must be from `0` to `1`. (Defaults to `0.1`)

  * `logging` - whether or not the GA will output what it is doing. (Defaults to `false`)

For our example of finding the largest sum of `8` numbers, our `numberOfGenes` should be `8`. This means that each time our `evaluateFitness` function is run, a set of `8` numbers will be passed in as a parameter.

Our evaluation function will look something like this:

```
evaluateFitness = (chromosome, chromosomeIndex) ->
  # Define a `sum` function to add up the numbers in an array:
  sum = (arr, s = 0) ->
    for val in arr
      s += val
    s
  # Report the result of the summation back to Genie, along with the `chromosomeIndex`: 
  Genie.reportFitness sum(chromosome.genes), chromosomeIndex)
  # Log some information about the progress:
  console.log Genie.getBestFit    
   
```

The other properties can be set as you please:

```
options = 
  evaluateFitness: evaluateFitness    
  mutationRate: 0.2
  numberOfGenes: 8
  populationSize: 64
```

`options` should be passed into the `Genie.init` function:

```
Genie.init options
```
Finally, we start the algorithm:

```
Genie.run()
```

## Anothing example - this time with WebWorkers:

Assuming that we have the Genie script in the page, we again need to initialise it with the right options.

The first difference is that we need to pass in the `useWorkers` option. This defaults to `false`, but if you want to use Workers, it should be a numerical value.
One option is to use [this](https://github.com/phenomnomnominal/workerbench.coffee) library to get the right number for the device that you are using, but you can just pass any set number.

When we assign the `useWorkers` option, Genie will no longer look for an `evaluateFunction` option. Instead it requires:

**1.** `workerScriptPath`: The path to the worker script.

**2.** `workerMessageHandler`: A function that handles the result coming from the Worker threads.

In order to be as flexible in this regard as possible, the Worker script and the handler function can be whatever you want, as long as they follow a few small rules:
___
### WORKER SCRIPT:

When Genie starts the Worker, it passes the string `'evaluateFitness'` as a `func` property.
The Worker `message` handler needs to look for that property (`e.data.func`), and then run the function to evaluate the fitness of the **Chromosome**.

Other useful data is sent along with the `func` property:

* `e.data.chromsome` - The actual **Chromosome** object to be evaluated
* `e.data.index.chromosomeIndex` - The index of the **Chromosome** in the population
* `e.data.index.workerIndex` - The index of the Worker.

When the worker is finished evaluating the **Chromosome**, it has to report the result back to the main thread using `self.postMessage`.
As you will define the function that handles how that message is processed, you can send back the result however you want. However, you need to make sure you also send back the `index` of the chromosome.


So, our base Worker script (genieWorkerScript.js) should look something like this:

```
importScripts 'myEvaluationFunctionModule.js'

messageHandler = (e) ->
  { func } = e.data
  
  switch func
    when 'evaluateFitness'
      { chromosome, index} = e.data
      { workerIndex, chromosomeIndex } = index
      result = someBigFunctionThatWillEvaluateThis chromosome
      self.postMessage 
        func: 'complete'
        result: result
        index: chromosomeIndex
self.addEventListener 'message', messageHandler, false
```
___
### WORKER MESSAGE HANDLER:

The message handler can do whatever you want! It is here that you will have access to the Genie module outside your worker script, so you need to call `Genie.reportFitness` with the result and the chromosome index.

Our handler might look something like this:

```
messageHandler = (e) ->
  { func } = e.data
  
  switch func
    when 'complete'
      Genie.reportFitness e.data.result, e.data.index
```

___
Then we can initialise and run Genie just like the other example:

```
options = 
  useWorkers: 4
  workerScriptPath: 'genieWorkerScript.js'
  workerMessageHandler: messageHandler    
  mutationRate: 0.2
  numberOfGenes: 8
  populationSize: 64
Genie.init options
Genie.run()
```

And that's all there is to it!

## CHANGELOG:

* **0.2.0** - 
  * WebWorkers! Genie can now use WebWorkers to run the evaluation functions heaps faster! (You might want to use [this](https://github.com/phenomnomnominal/workerbench.coffee) library to work out how many WebWorkers you should use!)
  * Instead of having a **Genie** class, there is now a **Genie** module
  * General refactoring!

## TODO:

* **Tests**

* **Make it better**

  *  Add the ability to provide existing population members.
  *  Before and after functions.
  *  Handle different **Gene** types.