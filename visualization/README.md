# Visualization

## Link


## Elm

To (re)compile the visualization, run `elm make src/Main.elm --optimize --output=elm.js` from the visualization directory.

The code assumes that a JSON log file such as `easy.json` (from the [solver directory](https://github.com/tkuriyama/sudoku/tree/master/solver) in this repo) is being served at the addressed defined by `url` in `Main.js`: `http://localhost:3000/model` (see [this page](https://elmprogramming.com/decoding-json-part-1.html) for an example of serving using `json-server`).

