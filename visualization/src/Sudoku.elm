module Sudoku exposing (..)

import Http as Http exposing (Error)

type alias Count = Int
type Action = Prune | Fill | Extend | None | Invalid

type Transform = Rows | Cols | Boxes

type alias Stack = Int

type alias Cell = (Int, Int, List Int)
type alias Board = List Cell
    
type alias Step = { count : Int
                  , action : Action
                  , transform : Transform
                  , stack : Int
                  , score: Int
                  , board : Board } 

type alias Point = (Float, Float)

type alias Model = { log : List Step,
                     pastLog : List Step,
                     logDiff : List (Int, Int),
                     errorMsg : Maybe String }
    
type Msg = SendHttpRequest
         | DataReceived (Result Http.Error (List Step))
         | RevKeyPressed
         | IterKeyPressed
