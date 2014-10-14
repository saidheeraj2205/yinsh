-- | Simply the best AI for Yinsh, seriously.

module Floyd ( aiFloyd
             , mhNumber
             , rhRingMoves
             , rhConnected
             , rhZero
             )
    where

import AI
import Yinsh

-- TODO: adjust numbers: 5, 10
floydHeuristic :: Floyd -> AIValue
floydHeuristic ai | points' W >= pointsForWin = hugeNumber
                  | points' B >= pointsForWin = -hugeNumber
                  | otherwise                = value W - value B
    where gs' = getGamestate ai
          board' = board gs'
          points W = pointsW gs'
          points B = pointsB gs'

          points' p = points p + futurePoints p
          -- If we are in a pseudo turn, the *opponent* of the current player
          -- will necessarily have one more point next turn. We can already
          -- include this in our evaluation.
          futurePoints p | (turnMode gs' == PseudoTurn) &&
                           (activePlayer gs' /= p)          = 1
                         | otherwise                        = 0

          valuePoints p = 100000 * points' p

          valueMarkers = markerH ai
          valueRings = ringH ai

          value p = valuePoints         p
                  + valueMarkers board' p
                  + valueRings   board' p


type MarkerHeuristic = Board -> Player -> AIValue
type RingHeuristic   = Board -> Player -> AIValue

mhNumber :: MarkerHeuristic
mhNumber b p = (10 *) $ length $ markers p b

rhRingMoves :: RingHeuristic
rhRingMoves b p = (1 *) $ sum $ map (length . ringMoves b) $ rings p b

rhConnected :: RingHeuristic
rhConnected b p = (1 *) $ length $ filter connectedToRings coords
     where connectedToRings c = any (c `connected`) (rings p b)

-- rhControlledMarkers :: RingHeuristic
-- rhControlledMarkers b p = length $ nub $ controlledM =<< (rings p b)
--     controlledM :: YCoord -> [YCoord]
--     controlledM c = ringMoves b c

rhZero :: RingHeuristic
rhZero _ _ = 0

data Floyd = Floyd { gs :: GameState
                   , plies :: Int
                   , markerH :: MarkerHeuristic
                   , ringH :: RingHeuristic
                   }

instance AIPlayer Floyd where
    valueForWhite = floydHeuristic
    getGamestate = gs
    getPlies = plies
    update ai gs' = ai { gs = gs' }

aiFloyd :: Int -> MarkerHeuristic -> RingHeuristic -> AIFunction
aiFloyd plies' mh' rh' gs' = aiTurn Floyd { gs = gs'
                                          , plies = plies'
                                          , markerH = mh'
                                          , ringH = rh'
                                          }
