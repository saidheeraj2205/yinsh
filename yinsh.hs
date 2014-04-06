import Haste
import Haste.Graphics.Canvas
import Data.List (minimumBy)

-- Color theme
-- http://www.colourlovers.com/palette/15/tech_light
green = RGB 209 231  81
blue  = RGB  38 173 228
white = RGB 255 255 255

-- Dimensions
spacing         = 60 :: Double
markerWidth     = 20 :: Double
ringInnerRadius = 22 :: Double
ringWidth       = 6 :: Double
start           = (-15, 140) :: (Double, Double)

-- | Yinsh hex coordinates
type YCoord = (Int, Int)

-- | Translate hex coordinates to screen coordiates
fromCoord :: YCoord -> Point
fromCoord (ya, yb) = (0.5 * sqrt 3 * x' + fst start,
                      y' - 0.5 * x' + snd start)
                where x' = spacing * fromIntegral ya
                      y' = spacing * fromIntegral yb

-- could be generated by generating all triangular lattice points smaller
-- than a certain cutoff (~ 5)
numPoints :: [[Int]]
numPoints = [[2..5], [1..7], [1..8], [1..9],
             [1..10], [2..10], [2..11], [3..11],
             [4..11], [5..11], [7..10]]

-- | All points on the board
coords :: [YCoord]
coords = concat $ zipWith (\list ya -> map (\x -> (ya, x)) list) numPoints [1..]

-- | Check if two points are connected by a line
--
-- Examples:
-- >>> connected (3, 4) (8, 4)
-- True
--
connected :: YCoord -> YCoord -> Bool
connected (x, y) (a, b) =        x == a
                          ||     y == b
                          || x - y == a - b

-- | List of points reachable from a certain point
reachable :: YCoord -> [YCoord]
reachable c = filter (connected c) coords

points :: [Point]
points = map fromCoord coords

-- | Translate by hex coordinate
translateC :: YCoord -> Picture () -> Picture ()
translateC = translate . fromCoord

ring :: Color -> Picture ()
ring col = do
    setFillColor col
    fill circL
    stroke circL
    setFillColor white
    fill circS
    stroke circS
    cross ringInnerRadius
        where circL = circle (0, 0) (ringInnerRadius + ringWidth)
              circS = circle (0, 0) ringInnerRadius

marker :: Color -> Picture ()
marker col = do
    setFillColor col
    fill circ
    stroke circ
        where circ = circle (0, 0) markerWidth

cross :: Double -> Picture ()
cross len = do
    l
    rotate (2 * pi / 3) l
    rotate (4 * pi / 3) l
        where l = stroke $ line (0, -len) (0, len)

dot :: Picture ()
dot = do
    setFillColor $ RGB 0 0 0
    fill $ circle (0, 0) 5

board :: Picture ()
board = do
    sequence_ $ mapM translate points (cross (0.5 * spacing))
    -- sequence_ $ mapM (translate . fromCoord) (reachable (3, 6)) dot
    translateC (3, 4) $ ring blue
    translateC (4, 9) $ ring blue
    translateC (8, 7) $ ring green
    translateC (6, 3) $ ring green
    translateC (4, 8) $ ring blue
    translateC (6, 4) $ marker green
    translateC (6, 5) $ marker green
    translateC (6, 7) $ marker green
    translateC (6, 6) $ marker blue

getClosestCoord :: Point -> YCoord
getClosestCoord (x, y) = coords !! snd lsort
    where lind = zipWith (\p i -> (dist p, i)) points [0..]
          lsort = minimumBy cmpFst lind
          dist (x', y') = (x-x')^2 + (y-y')^2
          cmpFst t1 t2 = compare (fst t1) (fst t2)

showMoves :: Canvas -> (Int, Int) -> IO ()
showMoves can (x, y) =
    render can $ do
        board
        translateC (getClosestCoord (fromIntegral x, fromIntegral y)) dot

main :: IO ()
main = do
    Just can <- getCanvasById "canvas"
    render can board -- TODO: needed?
    Just ce <- elemById "canvas"
    ce `onEvent` OnMouseMove $ showMoves can
    return ()
