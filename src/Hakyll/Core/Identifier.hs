-- | An identifier is a type used to uniquely identify a resource, target...
--
-- One can think of an identifier as something similar to a file path. An
-- identifier is a path as well, with the different elements in the path
-- separated by @/@ characters. Examples of identifiers are:
--
-- * @posts/foo.markdown@
--
-- * @index@
--
-- * @error/404@
--
-- The most important difference between an 'Identifier' and a file path is that
-- the identifier for an item is not necesserily the file path.
--
-- For example, we could have an @index@ identifier, generated by Hakyll. The
-- actual file path would be @index.html@, but we identify it using @index@.
--
-- @posts/foo.markdown@ could be an identifier of an item that is rendered to
-- @posts/foo.html@. In this case, the identifier is the name of the source
-- file of the page.
--
-- An `Identifier` carries the type of the value it identifies. This basically
-- means that an @Identifier (Page String)@ refers to a page.
--
-- It is a phantom type parameter, meaning you can safely change this if you
-- know what you are doing. You can change the type using the 'castIdentifier'
-- function.
--
-- If the @a@ type is not known, Hakyll traditionally uses @Identifier ()@.
--
{-# LANGUAGE GeneralizedNewtypeDeriving, DeriveDataTypeable #-}
module Hakyll.Core.Identifier
    ( Identifier (..)
    , castIdentifier
    , parseIdentifier
    , toFilePath
    , setGroup
    ) where

import Control.Arrow (second)
import Control.Applicative ((<$>), (<*>))
import Control.Monad (mplus)
import Data.Monoid (Monoid, mempty, mappend)
import Data.List (intercalate)

import Data.Binary (Binary, get, put)
import GHC.Exts (IsString, fromString)
import Data.Typeable (Typeable)

-- | An identifier used to uniquely identify a value
--
data Identifier a = Identifier
    { identifierGroup :: Maybe String
    , identifierPath  :: String
    } deriving (Eq, Ord, Typeable)

instance Monoid (Identifier a) where
    mempty = Identifier Nothing ""
    Identifier g1 p1 `mappend` Identifier g2 p2 =
        Identifier (g1 `mplus` g2) (p1 `mappend` p2)

instance Binary (Identifier a) where
    put (Identifier g p) = put g >> put p
    get = Identifier <$> get <*> get

instance Show (Identifier a) where
    show i@(Identifier Nothing _)  = toFilePath i
    show i@(Identifier (Just g) _) = toFilePath i ++ " (" ++ g ++ ")"

instance IsString (Identifier a) where
    fromString = parseIdentifier

-- | Discard the phantom type parameter of an identifier
--
castIdentifier :: Identifier a -> Identifier b
castIdentifier (Identifier g p) = Identifier g p
{-# INLINE castIdentifier #-}

-- | Parse an identifier from a string
--
parseIdentifier :: String -> Identifier a
parseIdentifier = Identifier Nothing
                . intercalate "/" . filter (not . null) . split'
  where
    split' [] = [[]]
    split' str = let (pre, post) = second (drop 1) $ break (== '/') str
                 in pre : split' post

-- | Convert an identifier to a relative 'FilePath'
--
toFilePath :: Identifier a -> FilePath
toFilePath = identifierPath

-- | Set the identifier group for some identifier
--
setGroup :: Maybe String -> Identifier a -> Identifier a
setGroup g (Identifier _ p) = Identifier g p
