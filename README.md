## genie.coffee (v0.1.0)

Need to run a simple *[Genetic Algorithm](http://en.wikipedia.org/wiki/Genetic_algorithm)* in **[CoffeeScript](http://www.coffeescript.org)**? I did, so I wrote this library. Define your **Chromosome**, write your evaluation function and let the algorithm do its thing!

First, some definitions:

* ### **Chromosome** - 
       A Chromosome is a set of genes, which belongs to the current population.

* ### **Gene** - 
       A **Gene** is an individual piece of a **Chromosome**, which provides a single piece of information to the evaluation function. A group of **Genes** make up a **Chromosome**. When two parent **Chromosomes** come together to make a new child Chromosome, **Genes** are inherited from both parents, and can also be mutated. For now, each **Gene** is a numerical value.

* ### **Population** - 
       A set of **Chromosomes**. The whole point of a genetic algorithm is to determine the best solution to a problem by evaluating the *fitness* of each member of the population. The weakest members of the population (the **Chromosome** with the lowest fitness) are killed, and replaced by the children of the stronger **Chromosome**.

* ### **Evaluation Function** -
       The evaluation function determines the fitness of a particular **Chromosome** to the problem at hand.

## A convoluted example:

Say we want to find the largest sum of a set of 8 numbers.

First, we create a new Genie:

```
genie = new Genie()
```

Then, we initialise the options for the GA. There are only **TWO** required options:

**1.** `numberOfGenes` - the number of **Genes** that are in each **Chromosome**.

**2.** `evaluateFitness` - the function that is run to evaluate the fitness of a given **Chromosome**. When the function is complete, it must call `genie.reportFitness()` with the fitness value of that **Chromosome**. Within `evaluateFitness` you also have access to:

  * the generation number - `genie.generation`

  * the **Chromosome** number - `genie.currentChromosomeIndex`

  * the current best fitting **Chromosome** - `genie.bestFit`. 


There are several other optional options:

  * `populationSize` - the number of **Chromosomes** in the population. Must be a positive number. (Defaults to `32`)

  * `mutationRate` - the chance that a given **Gene** will mutate. Must be from `0` to `1`. (Defaults to `0.1`)

  * `survivalRate` - the percent of that a given **Chromosome** will survive. Must be from `0` to `1`. (Defaults to `0.1`)

  * `logging` - whether or not the GA will output what it is doing. (Defaults to `false`)

```
options = 
  evaluateFitness: (chromosome) ->
    sum = (arr, s = 0) ->
      for val in arr
        s += val
      s
    console.log genie.currentChromosomeIndex
    genie.reportFitness sum(chromosome.genes)
  mutationRate: 0.2
  numberOfGenes: 8
  populationSize: 64
```

Finally, we start the algorithm:

```
genie.run()
```

## TODO:

* **Tests**

* **Docs**

* **Make it better**

  *  Add the ability to provide existing population members.
  *  Before and after functions.
  *  Handle different **Gene** types.