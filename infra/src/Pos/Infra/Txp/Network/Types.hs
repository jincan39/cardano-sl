module Pos.Infra.Txp.Network.Types
       ( TxMsgContents (..)
       ) where

import           Universum

import           Data.Text.Buildable (Buildable (..))
import           Formatting (bprint, (%))

import           Pos.Core.Txp (TxAux (..), txaF)

-- | Data message. Can be used to send one transaction per message.
-- Transaction is sent with auxilary data.
newtype TxMsgContents = TxMsgContents
    { getTxMsgContents :: TxAux
    } deriving (Generic, Show, Eq)

instance Buildable TxMsgContents where
    build (TxMsgContents txAux) =
        bprint ("TxMsgContents { txAux ="%txaF%", .. }") txAux