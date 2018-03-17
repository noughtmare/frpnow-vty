module Control.FRPNow.Vty where

import Control.FRPNow
import qualified Graphics.Vty as Vty
import Control.Monad (forever)

type VEvent = Vty.Event

runNowVty
  :: Vty.Config
  -> (EvStream VEvent -> Now (BehaviorEnd Vty.Picture a))
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

runNowVtyPure
  :: Vty.Config
  -> (EvStream VEvent -> Behavior (BehaviorEnd Vty.Picture a))
  -> IO a
runNowVtyPure conf b = runNowVty conf (sample . b)

