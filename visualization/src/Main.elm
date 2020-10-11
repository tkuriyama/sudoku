module Main exposing (main)

import Sudoku exposing (..)
import Parser exposing (..)
import Show exposing (..)

import Http
import Browser exposing (element)
import Browser.Events exposing (onKeyPress)
import Json.Decode as Decode exposing (Decoder, Error(..))
import String exposing (fromInt)

import Html exposing (Html, div)
import Html.Events exposing (onClick)
import TypedSvg exposing (svg)
import TypedSvg.Core exposing (Svg)
import TypedSvg.Attributes exposing (viewBox)

testB : Board
testB = let empty = List.range 0 9 
            vals = List.repeat 9 empty |> List.repeat 9 |> List.concat
            f n = List.range 0 8 |> List.map (\ m -> (n, m))
            inds = List.range 0 8 |> List.concatMap f 
        in List.map2 (\ (myCX, myCY) v -> (myCX, myCY, v)) inds vals

initModel : Model            
initModel = { log = [{ count = 0
                     , action = None
                     , transform = Rows
                     , stack = 1
                     , score = 9*9*9
                     , board = testB}]
            , pastLog = []
            , logDiff = []
            , errorMsg = Nothing }
    
init : () -> (Model, Cmd Msg)
init _ = (initModel, getModel)

view : Model -> Html Msg
view m = svg [ viewBox 0 0 1100 800 ] (render 750 750 m) 

url : String
url = "https://tarokuriyama.com/projects/sudoku/hard.json"
    
getModel : Cmd Msg
getModel = 
    Http.get
        { url = url
        , expect = Http.expectJson DataReceived logDecoder
        }

getDiff : Board -> Board -> List (Int, Int)
getDiff b1 b2 =
    let f (x1, y1, c1) (x2, y2, c2) = if c1 == c2 then (-1, -1) else (x2, y2)
    in List.map2 f b1 b2 |> List.filter ((/=) (-1, -1))

    
iterModel : Model -> Model
iterModel { log, pastLog } =
    case log of
        [] -> { log = [], pastLog = [],logDiff = [], errorMsg = Just "Empty log!" }
        (x::[]) -> { log = [x], pastLog = pastLog, logDiff = [], errorMsg = Nothing }
        (x::y::ys) -> { log = (y::ys), pastLog = (x::pastLog)
                      , logDiff = getDiff x.board y.board, errorMsg = Nothing }

revModel : Model -> Model
revModel { log, pastLog } =
    case pastLog of
        [] -> { log = log, pastLog = [], logDiff = [], errorMsg = Nothing }
        (x::[]) -> { log = (x::log), pastLog = [], logDiff = [], errorMsg = Nothing }
        (x::y::ys) -> { log = (x::log), pastLog = (y::ys)
                      , logDiff = getDiff y.board x.board, errorMsg = Nothing }
                            
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SendHttpRequest -> ( model, getModel )
        IterKeyPressed -> ( iterModel model, Cmd.none )
        RevKeyPressed -> ( revModel model, Cmd.none ) 
        DataReceived (Ok log) ->
            ( { model | log = log }, Cmd.none )
        DataReceived (Err httpError) ->
            ( { model | errorMsg = Just (buildErrorMessage httpError)
              }
            , Cmd.none
            )

buildErrorMessage : Http.Error -> String
buildErrorMessage httpError =
    case httpError of
        Http.BadUrl message ->
            message
        Http.Timeout ->
            "Server is taking too long to respond. Please try again later."
        Http.NetworkError ->
            "Unable to reach server."
        Http.BadStatus statusCode ->
            "Request failed with status code: " ++ String.fromInt statusCode
        Http.BadBody message ->
            message

keyDecoder : Decode.Decoder Msg
keyDecoder =
    Decode.map toKey (Decode.field "key" Decode.string)

toKey : String -> Msg
toKey keyValue =
    case keyValue of
        "p" -> RevKeyPressed
        _ -> IterKeyPressed
                
subscriptions : Model -> Sub Msg
subscriptions model =
    onKeyPress keyDecoder
           
main = element 
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }

