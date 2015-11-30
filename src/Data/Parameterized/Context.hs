------------------------------------------------------------------------
-- |
-- Module           : Data.Parameterized.Context
-- Copyright        : (c) Galois, Inc 2014-15
-- Maintainer       : Joe Hendrix <jhendrix@galois.com>
--
-- This module reexports either "Data.Parameterized.SafeContext"
-- or "Data.Parameterized.UnsafeContext" depending on the
-- the unsafe-operations compile-time flag.
--
-- It also defines some utility typeclasses for transforming
-- between curried and uncurried versions of functions over contexts.
------------------------------------------------------------------------
{-# LANGUAGE CPP #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE UndecidableInstances #-}
{-# LANGUAGE Safe #-}
module Data.Parameterized.Context
(
#ifdef UNSAFE_OPS
module Data.Parameterized.UnsafeContext
#else
module Data.Parameterized.SafeContext
#endif

  -- * Currying and uncurrying for assignments
, CurryAssignment
, CurryAssignmentClass(..)
) where

#ifdef UNSAFE_OPS
import Data.Parameterized.UnsafeContext
#else
import Data.Parameterized.SafeContext
#endif


-- | This type family is used to define currying\/uncurrying operations
-- on assignments.  It is best understood by seeing its evaluation on
-- several examples:
--
-- > CurryAssignment EmptyCtx f x = x
-- > CurryAssignment (EmptyCtx ::> a) f x = f a -> x
-- > CurryAssignment (EmptyCtx ::> a ::> b) f x = f a -> f b -> x
-- > CurryAssignment (EmptyCtx ::> a ::> b ::> c) f x = f a -> f b -> f c -> x
type family CurryAssignment (ctx :: Ctx k) (f :: k -> *) (x :: *) :: * where
   CurryAssignment EmptyCtx    f x = x
   CurryAssignment (ctx ::> a) f x = CurryAssignment ctx f (f a -> x)

-- | This class implements two methods that witness the isomorphism between
--   curried and uncurried functions.
class CurryAssignmentClass (ctx :: Ctx k) where

  -- | Transform a function that accepts an assignment into one with a separate
  --   variable for each element of the assignment.
  curryAssignment   :: (Assignment f ctx -> x) -> CurryAssignment ctx f x

  -- | Transform a curried function into one that accepts an assignment value.
  uncurryAssignment :: CurryAssignment ctx f x -> (Assignment f ctx -> x)


instance CurryAssignmentClass EmptyCtx where
  curryAssignment k = k empty
  uncurryAssignment k _ = k

instance CurryAssignmentClass ctx => CurryAssignmentClass (ctx ::> a) where
  curryAssignment k = curryAssignment (\asgn a -> k (asgn %> a))
  uncurryAssignment k asgn =
    case view asgn of
      AssignExtend asgn' x -> uncurryAssignment k asgn' x
