-- |
-- Module     : Control.FRPNow.Vty
-- Copyright  : (c) Jaro Reinders, 2018
-- License    : GPL-3
-- Maintainer : jaro.reinders@gmail.com
--
-- This module provides interoperability of FRPNow and the vty terminal UI
-- library.
module Control.FRPNow.Vty where

import Control.FRPNow
import qualified Graphics.Vty as Vty
import Control.Monad (forever)

-- | Alias for 'Vty.Event' to prevent name clash with 'Event'.
type VEvent = Vty.Event

-- | Run a Now computation which produces a behavior of type Picture, and draw
-- that on the screen.
runNowVty
  :: Vty.Config -- ^ The vty configuration to use.
  -> (EvStream VEvent -> Now (BehaviorEnd Vty.Picture a))
  -- ^ A now computation that takes a stream of vty events and produces
  -- a behavior of pictures and an ending event.
  -> IO a
runNowVty conf m = do
  vty <- Vty.mkVty conf
  runNowMaster $ do
    (evs, cbk) <- callbackStream
    async (forever (Vty.nextEvent vty >>= cbk))
    (b `Until` e) <- m evs
    sync . Vty.update vty =<< sample b
    callIOStream (Vty.update vty) (toChanges b)
    plan ((<$ sync (Vty.shutdown vty)) <$> e)

-- | Like 'runNowVty', but does not allow IO.
runNowVtyPure
  :: Vty.Config -- ^ The vty configuration to use.
  -> (EvStream VEvent -> Behavior (BehaviorEnd Vty.Picture a))
  -- ^ A computation that takes a stream of vty events and produces
  -- a behavior of pictures and an ending event.
  -> IO a
runNowVtyPure conf b = runNowVty conf (sample . b)

