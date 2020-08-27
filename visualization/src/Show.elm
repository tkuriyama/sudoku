module Show exposing (..)

import Sudoku exposing (..)

import Color
import String exposing (fromInt)

import TypedSvg exposing (circle, svg, rect, line, text_)
import TypedSvg.Attributes exposing (x, y, x1, y1, x2, y2, cx, cy, fill, r, rx,
                                     stroke, strokeWidth, opacity, class, fillOpacity,
                                     width, height, viewBox)
import TypedSvg.Types exposing (Paint(..), px, Opacity(..))
import TypedSvg.Core exposing (Svg, text)

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

showDiff : Float -> Float -> List (Int, Int) -> List (Svg msg)
showDiff myX myY ps =
    let fx n = (toFloat n) * (myX / 9)
        fy n = (toFloat n) * (myY / 9)
        showEffect (myCXInt, myCYInt) =
            rect [ x (px (fx myCXInt))
                 , y (px (fy myCYInt))
                 , width (px (myX / 9))
                 , height (px (myY / 9))
                 , stroke <| Paint Color.darkGreen
                 , strokeWidth (px 5)
                 , opacity <| Opacity 1
                 , fillOpacity <| Opacity 0
                  ] []
    in List.map showEffect ps
        
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
                                       , y (px (i*24))
                                       , class ["statText"]] 
                                      [ text <| label ++ ": " ++ s]
    in List.map showText stats

showInfo : Float -> Float -> List (Svg msg)
showInfo myX myY =
    let info = [(1, "Press any key to move forward."),
                 (2, "Press 'p' to move back.")
                 ]
        showText (i, txt) = text_ [ x (px (myX + 15))
                                  , y (px (i*20 + 200))
                                  , strokeWidth (px 12)
                                  , class ["infoText"]] 
                                 [ text txt]
    in List.map showText info
