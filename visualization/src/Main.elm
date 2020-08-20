module Main exposing (main)

import Color
import Html exposing (Html)
import TypedSvg exposing (circle, svg, rect, line)
import TypedSvg.Attributes exposing (x, y, x1, y1, x2, y2, cx, cy, fill, r, rx,
                                     stroke, strokeWidth, opacity,
                                     width, height, viewBox)
import TypedSvg.Types exposing (Paint(..), px, Opacity(..))
import TypedSvg.Core exposing (Svg)

type alias Point = (Float, Float)

type alias Cell = (Int, Int, List Int)
type alias Board = List Cell
type alias Stack = Int
type Transform = Rows | Cols | Boxes
type Action = Transition | Prune | Fill | Extend | Nothing
type Log = Log {actions: List Action
               , transforms: List Transform
               , stack: List Stack
               , boards: List Board}
 
-- Board Image

box : Float -> Float -> Svg msg
box myX myY =
    rect [ x (px 0.5), y (px 0.5)
          , width (px myX), height (px myY)
          , rx (px 10)
          , fill <| Paint Color.lightGrey
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

genCell : Float -> Float -> Cell -> Svg msg
genCell myX myY (myCXInt, myCYInt, ns) =
    let myCX = toFloat myCXInt
        myCY = toFloat myCYInt
        offset = myX / 9 / 2 
    in circle [ cx (px <| myCX * myX / 9 + offset)
              , cy (px <| myCY * myY / 9 + offset)
              , r (px 20)
              , fill <| Paint Color.darkBlue
              , opacity <| Opacity ((10-(List.length ns |> toFloat)) / 9)
              ] [] 
    
populate : Float -> Float -> Board -> List (Svg msg)
populate myX myY cs = List.map (genCell myX myY) cs         

testB : Board
        
testB = let empty = List.range 0 9 
            vals = [1] :: List.repeat 8 empty |> List.repeat 9
                   |> List.concat
            f n = List.range 0 8 |> List.map (\ m -> (n, m))
            inds = List.range 0 8 |> List.concatMap f 
        in List.map2 (\ (myCX, myCY) v -> (myCX, myCY, v)) inds vals
                
myBoard : Float -> Float -> List (Svg msg)
myBoard myX myY = (box myX myY) ::
                  ((minorLines myX myY 0.5) ++
                   (majorLines myX myY 1.5) ++
                   (populate myX myY testB))
                        
main : Html msg
main =
    svg [ viewBox 0 0 600 600 ] (myBoard 500 500)
