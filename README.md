
# Sudoku

## Solver

A refactoring of the [Sudoku solver notebook](https://github.com/tkuriyama/notebooks/blob/master/ipython/sudoku_revised.ipynb), inspired by Richard Bird's solution in [*Pearls of Functional Algorithm Design*](https://www.amazon.com/Pearls-Functional-Algorithm-Design-Richard/dp/0521513383).

The solver is written in Python in a functional style. It solves easy problems in a few milliseconds. Given some 17-hint (minimal-hint) puzzles, it can take ~1 second to find a solution.

From the `solver` directory, `python solver` will run the solver against the four puzzles pf varying difficulty in the `samples.txt`, printing out the original and completed state for each puzzle.


## Visualization

Visualization of the solver's iterations.


