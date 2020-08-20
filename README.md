
# Sudoku

## Solver

A refactoring of the [Sudoku solver notebook](https://github.com/tkuriyama/notebooks/blob/master/ipython/sudoku_revised.ipynb), inspired by Richard Bird's solution in [*Pearls of Functional Algorithm Design*](https://www.amazon.com/Pearls-Functional-Algorithm-Design-Richard/dp/0521513383).

The Python solver records the steps performed throughout its iterations, to be fed as input into the visualization engine. 


## Visualization

The Elm code compiles a visualization of the solver's iterations (in SVG animations). The goal is to represent the process of filtering down the board possibilities at each iteration of the solver. 


