module Parser exposing (..)

import Sudoku exposing (..)

import Json.Decode as Decode exposing (Decoder, Error(..), list, string, int, field, map4, map6)

countDecoder : Decoder Stack
countDecoder = Decode.int

transformDecoder : Decoder Transform
transformDecoder =
    Decode.string
    |> Decode.andThen
       (\ s ->
            case s of
                "Rows" -> Decode.succeed Rows
                "Cols" -> Decode.succeed Cols
                "Boxes" -> Decode.succeed Boxes
                _ -> Decode.fail <| "Unknown transformation.")

actionDecoder : Decoder Action
actionDecoder =
    Decode.string
    |> Decode.andThen
       (\ s ->
            case s of
                "Prune" -> Decode.succeed Prune
                "Fill" -> Decode.succeed Fill
                "Extend" ->  Decode.succeed Extend
                "None" ->  Decode.succeed None
                "Invalid" -> Decode.succeed Invalid
                _ -> Decode.fail <| "Unknown action.")

arrayAsTuple3 a b c =
    Decode.index 1 a
        |> Decode.andThen (\ aVal -> Decode.index 0 b
        |> Decode.andThen (\ bVal -> Decode.index 2 c
        |> Decode.andThen (\ cVal -> Decode.succeed (aVal, bVal, cVal))))
              
boardDecoder : Decoder Board
boardDecoder = Decode.list <| arrayAsTuple3 Decode.int Decode.int (Decode.list Decode.int)

stepDecoder : Decoder Step
stepDecoder =
    Decode.map6 Step
         (Decode.field "count" Decode.int)
         (Decode.field "action" actionDecoder)
         (Decode.field "transform" transformDecoder)
         (Decode.field "stack" Decode.int)
         (Decode.field "score" Decode.int)
         (Decode.field "board" boardDecoder)

logDecoder : Decoder (List Step)
logDecoder = Decode.list stepDecoder
