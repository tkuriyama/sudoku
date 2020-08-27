module Main exposing (main)

import Sudoku exposing (..)
import Parser exposing (..)

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

import Json.Decode as Decode exposing (Decoder, Error(..))
import Browser.Events exposing (onKeyPress)

    
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

expScale : Int -> Float
expScale n = let x = toFloat n
                 div = if n > 2 then 2 else 1
             in ((81 - (x^2)) / 81) / div
             
genCellBG : Float -> Float -> Action -> Cell -> Svg msg
genCellBG myX myY a (myCXInt, myCYInt, ns) =
    let myCX = toFloat myCXInt
        myCY = toFloat myCYInt
        offset = 0.5
        (bgColor, op) = case a of
                     Invalid -> (Color.lightRed, 0.25)
                     _ -> (Color.lightGreen, expScale (List.length ns))
    in rect [ x (px <| myCX * myX / 9 + offset)
            , y (px <| myCY * myY / 9 + offset)
            , width (px <| myX / 9 - (offset) * 2 )
            , height (px <| myX / 9 - (offset) * 2)
            , rx (px <| 1)
            , fill <| Paint bgColor
            , opacity <| Opacity op
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
    
populate : Float -> Float -> Action -> Board -> List (Svg msg)
populate myX myY a cs =
         List.map (genCellBG myX myY a) cs ++
         List.map (genCell myX myY) cs         
    
showBoard : Float -> Float -> Action -> Board -> List (Svg msg)
showBoard myX myY a b =
    (minorLines myX myY 0.5) ++
    (majorLines myX myY 1.5) ++
    (populate myX myY a b) ++
    [box myX myY]

showAction : Action -> String
showAction a = case a of
                   Prune -> "Prune"
                   Fill -> "Fill"
                   Extend -> "Extend"
                   None -> "None"
                   Invalid -> "Invalid Board"

showTransform : Transform -> String
showTransform t = case t of
                      Rows -> "Rows"
                      Cols -> "Cols"
                      Boxes -> "Boxes"
                              
showStat : Float -> Float -> Step -> List (Svg msg)
showStat myX myY { count, action, transform, score, stack } =
    let stats = [(1, "Iter", fromInt count),
                 (2, "Score", fromInt score),
                 (3, "Stack", fromInt stack),
                 (4, "Action", showAction action),
                 (5, "Transform", showTransform transform)]
        showText (i, label, s) = text_ [ x (px (myX + 15))
                                       , y (px (i*20))
                                       , strokeWidth (px 12)
                                       , class ["infoText"]] 
                                      [ text <| label ++ ": " ++ s]
    in List.map showText stats
    
renderLog : Float -> Float -> List Step -> List (Svg msg)
renderLog myX myY l =
    case l of
        (s::_) -> (showBoard myX myY s.action s.board) ++ (showStat myX myY s)
        [] -> showBoard myX myY None []  

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
            , pastLog = []
            , errorMsg = Nothing }
    
init : () -> (Model, Cmd Msg)
init _ = (initModel, getModel)

view : Model -> Html Msg
view m = svg [ viewBox 0 0 900 900 ] (render 650 650 m) 

url : String
url = "http://localhost:3000/model"
    
getModel : Cmd Msg
getModel = 
    Http.get
        { url = url
        , expect = Http.expectJson DataReceived logDecoder
        }

iterModel : Model -> Model
iterModel { log, pastLog } =
    case log of
        [] -> { log = [], pastLog = [], errorMsg = Just "Empty log!" }
        (s::[]) -> { log = [s], pastLog = pastLog, errorMsg = Nothing }
        (x::y::ys) -> { log = (y::ys), pastLog = (x::pastLog), errorMsg = Nothing }

revModel : Model -> Model
revModel { log, pastLog } =
    case pastLog of
        [] -> { log = log, pastLog = [], errorMsg = Nothing }
        (s::[]) -> { log = (s::log), pastLog = [], errorMsg = Nothing }
        (x::xs) -> { log = (x::log), pastLog = xs, errorMsg = Nothing }
                              

                            
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

