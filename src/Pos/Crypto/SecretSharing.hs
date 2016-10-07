{-# LANGUAGE DeriveGeneric   #-}
{-# LANGUAGE TemplateHaskell #-}

-- | Dummy implementation of VSS. It doesn't have any logic now.

module Pos.Crypto.SecretSharing
       ( VssPublicKey
       , getVssPublicKey
       , VssSecretKey
       , getVssSecretKey
       , deriveVssPublicKey
       , vssKeyGen

       , EncShare
       , Secret (..)
       , SecretProof
       , Share
       , decryptShare
       , encryptShare
       , recoverSecret
       , shareSecret
       , verifyProof
       ) where

import           Data.Binary          (Binary)
import           Data.SafeCopy        (base, deriveSafeCopySimple)
import           Data.Text.Buildable  (Buildable)
import qualified Data.Text.Buildable  as Buildable
import qualified Serokell.Util.Base16 as B16
import           Universum

-- | This key is used as part of VSS. Corresponding VssSecretKey may
-- be used to decrypt one of the shares.
newtype VssPublicKey = VssPublicKey
    { getVssPublicKey :: ()
    } deriving (Show, Eq, Binary)

-- | This key is to decrypt share generated by VSS.
newtype VssSecretKey = VssSecretKey
    { getVssSecretKey :: ()
    } deriving (Show, Eq, Binary)

-- | Derive VssPublicKey from VssSecretKey.
deriveVssPublicKey :: VssSecretKey -> VssPublicKey
deriveVssPublicKey _ = VssPublicKey ()

vssKeyGen :: MonadIO m => m (VssPublicKey, VssSecretKey)
vssKeyGen = pure (VssPublicKey (), VssSecretKey ())

-- | Secret can be split into encrypted shares to be reconstructed later.
newtype Secret = Secret
    { getSecret :: ByteString
    } deriving (Show, Eq, Ord, Binary)

instance Buildable Secret where
    build = B16.formatBase16 . getSecret

-- | Shares can be used to reconstruct Secret.
newtype Share = Share
    { getShare :: Secret
    } deriving (Eq, Ord, Show, Binary)

instance Buildable Share where
    build _ = "share ¯\\_(ツ)_/¯"

-- | Encrypted share which needs to be decrypted using VssSecretKey first.
newtype EncShare = EncShare
    { getEncShare :: Secret
    } deriving (Show, Eq, Ord, Binary)

instance Buildable EncShare where
    build _ = "encrypted share ¯\\_(ツ)_/¯"

-- | Decrypt share using secret key.
decryptShare :: VssSecretKey -> EncShare -> Share
decryptShare _ = Share . getEncShare

-- | Encrypt share using public key.
encryptShare :: VssPublicKey -> Share -> EncShare
encryptShare _ = EncShare . getShare

-- | This proof may be used to check that particular given secret has
-- been generated.
newtype SecretProof =
    SecretProof Secret
    deriving (Show, Eq, Generic, Binary)

shareSecret
    :: [VssPublicKey]  -- ^ Public keys of parties
    -> Word            -- ^ How many parts should be enough
    -> Secret          -- ^ Secret to share
    -> (SecretProof, [EncShare])  -- ^ i-th share is encrypted using i-th key
shareSecret keys _ s = (SecretProof s, map mkShare keys)
  where
    mkShare key = encryptShare key (Share s)

recoverSecret :: [Share] -> Maybe Secret
recoverSecret [] = Nothing
recoverSecret (x:xs) = do
    guard (all (== x) xs)
    -- guard (length (ordNub (map shareIndex (x:xs))) >= minNeeded x)
    return (getShare x)

verifyProof :: SecretProof -> Secret -> Bool
verifyProof (SecretProof p) s = p == s

----------------------------------------------------------------------------
-- SafeCopy instances
----------------------------------------------------------------------------

deriveSafeCopySimple 0 'base ''VssPublicKey
deriveSafeCopySimple 0 'base ''VssSecretKey
deriveSafeCopySimple 0 'base ''EncShare
deriveSafeCopySimple 0 'base ''Secret
deriveSafeCopySimple 0 'base ''SecretProof
deriveSafeCopySimple 0 'base ''Share
