# JSON Log

The Elm visualization expects log data as a list of steps, where `type alias Step = { count : Int, action : Action, transform : Transform, stack : Int, score: Int, board : Board }`. Action, Transform, Stack, Score, and Board are type aliases defined in `Main.elm`). In Python terms, this is a list of dicts, where each list logs state for a single step in the solver.

The `solver_logging.py` version of the solver implements the logging, ultimately writing the list of 
dicts to a JSON consisting of a single object with key `model`. 

The `easy.json` file (included in this directory) logs the iterations of an easy puzzle defined in `solver_logging.py`.

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
