
{-| The abstract syntax. This is what you get after desugaring and scope
    analysis of the concrete syntax. The type checker works on abstract syntax,
    producing internal syntax ("Syntax.Internal").
-}
module Syntax.Abstract
    ( module Syntax.Abstract
    , module Syntax.Abstract.Name
    ) where

import Syntax.Info
import Syntax.Common
import Syntax.Position
import Syntax.Abstract.Name
import Syntax.Literal

data Expr
        = Var  NameInfo  Name		    -- ^ Bound variables
        | Def  NameInfo QName		    -- ^ Constants (i.e. axioms, functions, and datatypes)
        | Con  NameInfo QName		    -- ^ Constructors
	| Lit Literal			    -- ^ Literals
	| QuestionMark MetaInfo		    -- ^ meta variable for interaction
        | Underscore   MetaInfo		    -- ^ meta variable for hidden argument (must be inferred locally)
        | App  ExprInfo Expr (NamedArg Expr)
        | Lam  ExprInfo LamBinding Expr	    -- ^
        | Pi   ExprInfo Telescope Expr	    -- ^
	| Fun  ExprInfo (Arg Expr) Expr	    -- ^ independent function space
        | Set  ExprInfo Nat		    -- ^
        | Prop ExprInfo			    -- ^
        | Let  ExprInfo [LetBinding] Expr   -- ^

data Declaration
	= Axiom      DefInfo Name Expr				-- ^ postulate
	| Primitive  DefInfo Name Expr				-- ^ primitive function
	| Definition DeclInfo [TypeSignature] [Definition]	-- ^ a bunch of mutually recursive definitions
	| Module     ModuleInfo ModuleName [TypedBindings] [Declaration]
	| ModuleDef  ModuleInfo ModuleName [TypedBindings] ModuleName [NamedArg Expr]
	| Import     ModuleInfo ModuleName
	| Open	     DeclSource	    -- ^ this one is here only to enable translation
				    --   back to concrete syntax
	| Pragma     Range	Pragma

data Pragma = OptionsPragma [String]
	    | BuiltinPragma String Expr

data LetBinding = LetBind LetInfo Name Expr Expr    -- ^ LetBind info name type defn

-- | A definition without its type signature.
data Definition
	= FunDef     DefInfo Name [Clause]
	| DataDef    DefInfo Name [LamBinding] [Constructor]
	    -- ^ the 'LamBinding's are 'DomainFree' and binds the parameters of the datatype.

-- | Only 'Axiom's.
type TypeSignature  = Declaration
type Constructor    = TypeSignature

-- | A lambda binding is either domain free or typed.
data LamBinding
	= DomainFree Hiding Name    -- ^ . @x@ or @{x}@
	| DomainFull TypedBindings  -- ^ . @(xs:e)@ or @{xs:e}@

-- | Typed bindings with hiding information.
data TypedBindings = TypedBindings Range Hiding [TypedBinding]
	    -- ^ . @(xs:e;..;ys:e')@ or @{xs:e;..;ys:e'}@

-- | A typed binding. Appears in dependent function spaces, typed lambdas, and
--   telescopes. I might be tempting to simplify this to only bind a single
--   name at a time. This would mean that we would have to typecheck the type
--   several times (@x,y:A@ vs. @x:A; y:A@). In most cases this wouldn't
--   really be a problem, but it's good principle to not do extra work unless
--   you have to.
data TypedBinding = TBind Range [Name] Expr
		  | TNoBind Expr

type Telescope	= [TypedBindings]

-- | We could throw away @where@ clauses at this point and translate them to
--   @let@. It's not obvious how to remember that the @let@ was really a
--   @where@ clause though, so for the time being we keep it here.
data Clause	= Clause LHS RHS [Declaration]
data RHS	= RHS Expr
		| AbsurdRHS

data LHS	= LHS LHSInfo Name [NamedArg Pattern]
data Pattern	= VarP Name	-- ^ the only thing we need to know about a
				-- pattern variable is its 'Range'. This is
				-- stored in the 'Name', so we don't need a
				-- 'NameInfo' here.
		| ConP PatInfo QName [NamedArg Pattern]
		| DefP PatInfo QName [NamedArg Pattern]  -- ^ defined pattern
		| WildP PatInfo
		| AsP PatInfo Name Pattern
		| AbsurdP PatInfo
		| LitP Literal

-- | why has Var in Expr above a NameInfo but VarP no Info?
-- | why has Con in Expr above a NameInfo but ConP an Info?
-- | why Underscore above and WildP here? (UnderscoreP better?)


{--------------------------------------------------------------------------
    Instances
 --------------------------------------------------------------------------}

instance HasRange LamBinding where
    getRange (DomainFree _ x) = getRange x
    getRange (DomainFull b)   = getRange b

instance HasRange TypedBindings where
    getRange (TypedBindings r _ _) = r

instance HasRange TypedBinding where
    getRange (TBind r _ _) = r
    getRange (TNoBind e)   = getRange e

instance HasRange Expr where
    getRange (Var i _)		= getRange i
    getRange (Def i _)		= getRange i
    getRange (Con i _)		= getRange i
    getRange (Lit l)		= getRange l
    getRange (QuestionMark i)	= getRange i
    getRange (Underscore  i)	= getRange i
    getRange (App i _ _)	= getRange i
    getRange (Lam i _ _)	= getRange i
    getRange (Pi i _ _)		= getRange i
    getRange (Fun i _ _)	= getRange i
    getRange (Set i _)		= getRange i
    getRange (Prop i)		= getRange i
    getRange (Let i _ _)	= getRange i

instance HasRange Declaration where
    getRange (Axiom      i _ _	  ) = getRange i
    getRange (Definition i _ _	  ) = getRange i
    getRange (Module     i _ _ _  ) = getRange i
    getRange (ModuleDef  i _ _ _ _) = getRange i
    getRange (Import     i _	  ) = getRange i
    getRange (Open	 i	  ) = getRange i
    getRange (Primitive  i _ _	  ) = getRange i
    getRange (Pragma	 i _	  ) = getRange i

instance HasRange Definition where
    getRange (FunDef  i _ _   ) = getRange i
    getRange (DataDef i _ _ _ ) = getRange i

instance HasRange Pattern where
    getRange (VarP x)	    = getRange x
    getRange (ConP i _ _)   = getRange i
    getRange (DefP i _ _)   = getRange i
    getRange (WildP i)	    = getRange i
    getRange (AsP i _ _)    = getRange i
    getRange (AbsurdP i)    = getRange i
    getRange (LitP l)	    = getRange l

instance HasRange LHS where
    getRange (LHS i _ _)    = getRange i

instance HasRange Clause where
    getRange (Clause lhs rhs ds) = getRange (lhs,rhs,ds)

instance HasRange RHS where
    getRange AbsurdRHS = noRange
    getRange (RHS e)   = getRange e

instance HasRange LetBinding where
    getRange (LetBind i _ _ _) = getRange i

