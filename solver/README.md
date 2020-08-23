# JSON Log

The Elm visualization expects log data as `type Model = List (Step Action Transform Stack Board)` 
(where Action, Transform, Stack, and Board are type aliases defined in `Main.elm`). In Python terms,
this is a list of lists, where each list logs state for a single step in the solver.

The `solver_logging.py` version of the solver implements the logging, ultimately writing the list of 
lists to a JSON consisting a single object with key `model`. 

The `test.json` file (included in this directory) looks like this:

```
√ solver % jbro test.json -c 100                         

> Show first 100 chars of file
{
  "model": [
    [
      0,
      "Nothing",
      "Rows",
      1,
      [
        [
          1,
```

