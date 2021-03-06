{-# LANGUAGE ForeignFunctionInterface #-}
{-# LANGUAGE JavaScriptFFI #-}
{-# LANGUAGE InterruptibleFFI #-}
{-# LANGUAGE DeriveDataTypeable #-}

{- |
     Animation frames are the browser's mechanism for smooth animation.
     An animation frame callback is run just before the browser repaints.

     When the content window is inactive, for example when the user is looking
     at another tab, it can take a long time for an animation frame callback
     to happen. Be careful structuring evaluation around this! Typically this
     means carefully forcing the data before the animation frame is requested,
     so the callback can run quickly and predictably.
  -}

module JavaScript.Web.AnimationFrame
    ( waitForAnimationFrame
    , inAnimationFrame
    , cancelAnimationFrame
    , AnimationFrameHandle
    ) where

import GHCJS.Foreign.Callback
import GHCJS.Marshal.Pure
import GHCJS.Types

import Control.Exception (onException)
import Data.Typeable

newtype AnimationFrameHandle = AnimationFrameHandle JSRef
  deriving (Typeable)

{- |
     Wait for an animation frame callback to continue running the current
     thread. Use 'GHCJS.Concurrent.synchronously' if the thread should
     not be preempted.
 -}
waitForAnimationFrame :: IO ()
waitForAnimationFrame = do
  h <- js_makeAnimationFrameHandle
  js_waitForAnimationFrame h `onException` js_cancelAnimationFrame h

{- |
     Run the action in an animationframe callback. The action runs in a
     synchronous thread.
 -}
inAnimationFrame :: OnBlocked -- ^ what to do when encountering a blocking call
                 -> IO ()     -- ^ the action to run
                 -> IO AnimationFrameHandle
inAnimationFrame onBlocked x = do
  cb <- syncCallback onBlocked x
  h  <- js_makeAnimationFrameHandleCallback (jsref cb)
  js_requestAnimationFrame h
  return h

cancelAnimationFrame :: AnimationFrameHandle -> IO ()
cancelAnimationFrame h = js_cancelAnimationFrame h
{-# INLINE cancelAnimationFrame #-}

-- -----------------------------------------------------------------------------

foreign import javascript unsafe "{ handle: null, callback: null }"
  js_makeAnimationFrameHandle :: IO AnimationFrameHandle
foreign import javascript unsafe "{ handle: null, callback: $1 }"
  js_makeAnimationFrameHandleCallback :: JSRef -> IO AnimationFrameHandle
foreign import javascript unsafe "h$animationFrameCancel"
  js_cancelAnimationFrame :: AnimationFrameHandle -> IO ()
foreign import javascript interruptible
  "$1.handle = window.requestAnimationFrame($c);"
  js_waitForAnimationFrame :: AnimationFrameHandle -> IO ()
foreign import javascript unsafe "h$animationFrameRequest"
  js_requestAnimationFrame :: AnimationFrameHandle -> IO ()
