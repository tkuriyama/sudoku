module Main exposing (main)

import String exposing (fromInt)

import Color
import Browser exposing (element)
import Html exposing (Html)
import TypedSvg exposing (circle, svg, rect, line, text_)
import TypedSvg.Attributes exposing (x, y, x1, y1, x2, y2, cx, cy, fill, r, rx,
                                     stroke, strokeWidth, opacity, class, fillOpacity,
                                     width, height, viewBox)
import TypedSvg.Types exposing (Paint(..), px, Opacity(..))
import TypedSvg.Core exposing (Svg, text)

type alias Point = (Float, Float)

type alias Cell = (Int, Int, List Int)
type alias Board = List Cell
type alias Stack = Int
type Transform = Rows | Cols | Boxes
type Action = Transition | Prune | Fill | Extend | Nothing
type Log = Log (List Action) (List Transform) (List Stack) (List Board)

type Msg = Update
type alias Model = Log
    
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

myModel : Float -> Float -> Model -> List (Svg msg)
myModel myX myY l =
    case l of
        (Log _ _ _ (b::_)) -> myBoard myX myY b
        (Log _ _ _ []) -> myBoard myX myY []
              
-- Main

testB : Board
testB = let empty = List.range 0 9 
            vals = [1] :: List.repeat 8 empty |> List.repeat 9
                   |> List.concat
            f n = List.range 0 8 |> List.map (\ m -> (n, m))
            inds = List.range 0 8 |> List.concatMap f 
        in List.map2 (\ (myCX, myCY) v -> (myCX, myCY, v)) inds vals
            
init : () -> (Model, Cmd Msg)
init _ = (Log [Nothing] [Rows] [1] [testB], Cmd.none)

view : Model -> Html Msg
view m = svg [ viewBox 0 0 600 600 ] (myModel 500 500 m) 

update : Msg -> Model -> (Model, Cmd Msg)
update s m = (m, Cmd.none)

-- subscriptions : Model -> Sub Msg
-- subscriptions m = none
           
main = element 
    { init = init
    , view = view
    , update = update
    , subscriptions = \_ -> Sub.none
    }

