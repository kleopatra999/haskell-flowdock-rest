{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE RecordWildCards #-}
module Chat.Flowdock.REST.Request (
  -- * Request creation
  parseApiUrl,
  -- * Messages
  messagesRequest,
  MessageEvent(..),
  MessageOptions(..),
  msgOptLimit,
  msgOptEvent,
  ) where

import Control.Applicative
import Control.Lens
import Control.Monad
import Control.Monad.Catch
import Data.ByteString
import Data.Maybe
import Data.String
import Data.Tagged
import Network.HTTP.Client

import Chat.Flowdock.REST.Internal
import Chat.Flowdock.REST.User
import Chat.Flowdock.REST.Organisation
import Chat.Flowdock.REST.Flow
import Chat.Flowdock.REST.Message

import Chat.Flowdock.REST.URLs

-- | Convert a 'ApiUrl' into a 'Request'.
--
-- See 'Network.HTTP.Client.parseUrl'
--
-- Since this function uses 'MonadThrow', the return monad can be anything that is an instance of 'MonadThrow', such as 'IO' or 'Maybe'.
parseApiUrl :: MonadThrow m => ApiUrl a -> m (Tagged a Request)
parseApiUrl (ApiUrl url) = Tagged `liftM` parseUrl url

data MessageEvent = EventMail
  deriving (Eq, Ord, Show, Enum, Bounded)
  
messageEventToString :: MessageEvent -> ByteString
messageEventToString EventMail = "mail"

data MessageOptions = MessageOptions
  { _msgOptEvent :: Maybe MessageEvent
  , _msgOptLimit :: Maybe Int
  }
  deriving (Eq, Ord, Show)

makeLenses ''MessageOptions

messagesRequest :: MonadThrow m => ParamName Organisation -> ParamName Flow -> MessageOptions -> m (Tagged [Message] Request)
messagesRequest org flow MessageOptions {..} = do
  req <- parseApiUrl (messagesUrl org flow)
  return $ setQueryString queryString <$> req
  where queryString = catMaybes [ (\e -> ("event", Just $ messageEventToString e)) <$> _msgOptEvent 
                                , (\l -> ("limit", Just $ fromString $ show l)) <$> _msgOptLimit
                                ]
