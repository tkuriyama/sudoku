module Main exposing (main)

import String exposing (fromInt)

import Color
import Browser exposing (element)
import Http
import Html exposing (Html, h2, h3, div)
import Html.Events exposing (onClick)
import TypedSvg exposing (circle, svg, rect, line, text_)
import TypedSvg.Attributes exposing (x, y, x1, y1, x2, y2, cx, cy, fill, r, rx,
                                     stroke, strokeWidth, opacity, class, fillOpacity,
                                     width, height, viewBox)
import TypedSvg.Types exposing (Paint(..), px, Opacity(..))
import TypedSvg.Core exposing (Svg, text)

import Json.Decode as Decode exposing (Decoder, Error(..), list, string, int, field, map4, map6)

import Browser.Events exposing (onKeyPress)

type alias Point = (Float, Float)

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

type alias Model = { log : List Step,
                     errorMsg : Maybe String } 
type Msg = SendHttpRequest
         | DataReceived (Result Http.Error (List Step))
         | KeyPressed

    
-- Board Image

box : Float -> Float -> Svg msg
box myX myY =
    rect [ x (px 0.5), y (px 0.5)
          , width (px myX), height (px myY)
          , rx (px 1)
--         , fill <| Paint Color.white
         , fillOpacity <| Opacity 0
         , strokeWidth (px 1.5)
          , stroke <| Paint Color.black
         ] []

genLine : Float -> (Point, Point) -> Svg msg
genLine myStroke ((myX1, myY1), (myX2, myY2)) =
    line [ x1 (px myX1), x2 (px myX2)
         , y1 (px myY1), y2 (px myY2)
         , strokeWidth (px myStroke)
         , stroke <| Paint Color.black
         ] []

genPoints : Float -> Float -> List Float -> List (Point, Point)
genPoints myX myY ns = List.map (\ n -> ((myX*n/9, 0), (myX*n/9, myY))) ns ++
                      List.map (\ n -> ((0, myY*n/9), (myX, myY*n/9))) ns
        
majorLines : Float -> Float -> Float -> List (Svg msg)
majorLines myX myY myStroke =
    genPoints myX myY [3, 6] |> List.map (genLine myStroke) 

minorLines : Float -> Float -> Float -> List (Svg msg)
minorLines myX myY myStroke =
    genPoints myX myY [1,2,4,5,7,8] |> List.map (genLine myStroke)

-- Board Content

showCell : List Int -> String
showCell ns =
    case ns of
        (x::[]) -> String.fromInt x
        _ -> "."

genCellBG : Float -> Float -> Cell -> Svg msg
genCellBG myX myY (myCXInt, myCYInt, ns) =
    let myCX = toFloat myCXInt
        myCY = toFloat myCYInt
        offset = 0.5
    in rect [ x (px <| myCX * myX / 9 + offset)
            , y (px <| myCY * myY / 9 + offset)
            , width (px <| myX / 9 - (offset) * 2 )
            , height (px <| myX / 9 - (offset) * 2)
            , rx (px <| 1)
            , fill <| Paint Color.lightGreen
            , opacity <| Opacity <| (10 - (List.length ns |> toFloat)) / 10
            ] [] 

genCell : Float -> Float -> Cell -> Svg msg
genCell myX myY (myCXInt, myCYInt, ns) =
    let myCX = toFloat myCXInt
        myCY = toFloat myCYInt
        offset = myX / 18 
        disp = showCell ns               
    in text_ [ x (px <| myCX * myX / 9 + offset - 5)
             , y (px <| myCY * myY / 9 + offset + 5)
             , class ["boardNum"]
             , strokeWidth (px 12)
             ] [text disp] 
    
populate : Float -> Float -> Board -> List (Svg msg)
populate myX myY cs =
         List.map (genCellBG myX myY) cs ++
         List.map (genCell myX myY) cs         
    
myBoard : Float -> Float -> Board -> List (Svg msg)
myBoard myX myY b = (minorLines myX myY 0.5) ++
                    (majorLines myX myY 1.5) ++
                    (populate myX myY b) ++
                    [box myX myY]

renderLog : Float -> Float -> List Step -> List (Svg msg)
renderLog myX myY l =
    case l of
        ({board}::_) -> myBoard myX myY board
        [] -> myBoard myX myY []  

renderError : String -> List (Svg msg)
renderError s = [text_ [ x (px 10)
                       , y (px 10)
                       , class ["errorText"]
                       ]
                       [text s ]
                ]
                    
render : Float -> Float -> Model -> List (Svg msg)
render myX myY m =
    case m.errorMsg of
        Nothing ->  renderLog myX myY m.log
        (Just e) -> renderError e 

-- JSON

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
                "Extend" ->  Decode.succeed Fill
                "None" ->  Decode.succeed None
                "Invalid" -> Decode.succeed Invalid
                _ -> Decode.fail <| "Unknown action.")

stackDecoder : Decoder Int
stackDecoder = Decode.int               
           
arrayAsTuple3 a b c =
    Decode.index 0 a
        |> Decode.andThen (\ aVal -> Decode.index 1 b
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
  
-- Main IVUS

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
            , errorMsg = Nothing }
    
init : () -> (Model, Cmd Msg)
init _ = (initModel, getModel)

view : Model -> Html Msg
view m = svg [ viewBox 0 0 600 600 ] (render 500 500 m) 

url : String
url = "http://localhost:3000/model"
    
getModel : Cmd Msg
getModel = 
    Http.get
        { url = url
        , expect = Http.expectJson DataReceived logDecoder
        }

iterModel : Model -> Model
iterModel { log } = case log of
                        [] -> { log = [], errorMsg = Just "Empty log!" }
                        (s::[]) -> { log = [s], errorMsg = Nothing }
                        (x::y::ys) -> { log = (y::ys), errorMsg = Nothing }
                              
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SendHttpRequest -> ( model, getModel )
        KeyPressed -> ( iterModel model, Cmd.none ) 
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

subscriptions : Model -> Sub Msg
subscriptions model =
    onKeyPress (Decode.succeed KeyPressed)
           
main = element 
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }

