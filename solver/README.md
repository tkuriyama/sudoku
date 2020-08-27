# JSON Log

The Elm visualization expects log data as a list of steps, where `type alias Step = { count : Int, action : Action, transform : Transform, stack : Int, score: Int, board : Board }`. Action, Transform, and Board are type aliases defined in `Main.elm`). In Python terms, this is a list of dicts, where each list logs state for a single step in the solver.

`solver_logging.py` adds the logging logic ot the original solver, ultimately writing the list of 
dicts to a JSON object with key `model`. 

As an example, `easy.json` logs the iterations of an easy puzzle defined in `solver_logging.py`.

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
