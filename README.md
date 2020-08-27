
# Sudoku

## Link



## Solver

A refactoring of the [Sudoku solver notebook](https://github.com/tkuriyama/notebooks/blob/master/ipython/sudoku_revised.ipynb), inspired by Richard Bird's solution in [*Pearls of Functional Algorithm Design*](https://www.amazon.com/Pearls-Functional-Algorithm-Design-Richard/dp/0521513383).

The Python solver records the steps performed in its iterations, to be fed as input into the visualization engine. 

The Elm visualization expects log data as a list of steps, where `type alias Step = { count : Int, action : Action, transform : Transform, stack : Int, score: Int, board : Board }`. Action, Transform, and Board are type aliases defined in `Main.elm`. 

In Python terms, the log consists of a list of dicts, where each dict logs state for a single step in the solver. `solver_logging.py` adds the logging logic to the original solver, ultimately writing the list of dicts to a JSON object with key `model`. 

As an example, `easy.json` logs the iterations of the easy puzzle defined in `solver_logging.py`.

```
√ solver % jbro -c 100 easy.json                                                                                    (master)sudoku

> Show first 100 chars of file
{
  "model": [
    {
      "action": "None",
      "board": [
        [
          0,
          0,
```

This nefarious puzzle takes the solver 7630 steps to solve (vs 28 steps for the easy puzzle). The log format is not optimized for conciseness (e.g. by logging deltas instead of whole boards), so the `nefarious.json` file size exceeds 100MB and is omitted from the repo. 

`000060080020000000001000000070000102500030000000000400004201000300700600000000050`

## Visualization

The Elm code compiles an SVG visualization of the solver's iterations. 

To (re)compile the visualization, run `elm make src/Main.elm --optimize --output=elm.js` from the visualization directory.

The code assumes that a JSON log file such as `easy.json` is being served at the addressed defined by `url` in `Main.elm`. For one way of testing locally, see [this page](https://elmprogramming.com/decoding-json-part-1.html) for an example of serving using `json-server`.
