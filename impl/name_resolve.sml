structure NameResolve = struct
structure T = NamefulType
structure E = NamefulExpr
open Type
open Expr

local

    exception Error of string

    fun runError m _ =
	OK (m ())
	handle
	Error msg => Failed msg

    fun on_var ctx x =
	case List.find (fn (_, y) => y = x) (add_idx ctx) of
	    SOME (i, _) => i
	  | NONE => raise Error ("Unbound variable " ^ x)

    fun on_idx ctx i =
	case i of
	    T.VarI x => VarI (on_var ctx x)
	  | T.T0 => T0
	  | T.T1 => T1
	  | T.Tadd (i1, i2) => Tadd (on_idx ctx i1, on_idx ctx i2)
	  | T.Tmult (i1, i2) => Tmult (on_idx ctx i1, on_idx ctx i2)
	  | T.Tmax (i1, i2) => Tmax (on_idx ctx i1, on_idx ctx i2)
	  | T.Tmin (i1, i2) => Tmin (on_idx ctx i1, on_idx ctx i2)
	  | T.TrueI => TrueI
	  | T.FalseI => FalseI
	  | T.TT => Type.TT
	  | T.Tconst n => Tconst n

    fun on_prop ctx p =
	case p of
	    T.True => True
	  | T.False => False
	  | T.And (p1, p2) => And (on_prop ctx p1, on_prop ctx p2)
	  | T.Or (p1, p2) => Or (on_prop ctx p1, on_prop ctx p2)
	  | T.Imply (p1, p2) => Imply (on_prop ctx p1, on_prop ctx p2)
	  | T.Iff (p1, p2) => Iff (on_prop ctx p1, on_prop ctx p2)
	  | T.TimeLe (i1, i2) => TimeLe (on_idx ctx i1, on_idx ctx i2)
	  | T.Eq (i1, i2) => Eq (on_idx ctx i1, on_idx ctx i2)

    fun on_sort ctx s =
	case s of
	    T.Basic s => Basic s
	  | T.Subset (s, name, p) => Subset (s, name, on_prop (name :: ctx) p)

    fun on_type (ctx as (sctx, kctx)) t =
	case t of
	    T.Arrow (t1, d, t2) => Arrow (on_type ctx t1, on_idx sctx d, on_type ctx t2)
	  | T.Prod (t1, t2) => Prod (on_type ctx t1, on_type ctx t2)
	  | T.Sum (t1, t2) => Sum (on_type ctx t1, on_type ctx t2)
	  | T.Unit => Unit
	  | T.Uni (name, t) => Uni (name, on_type (sctx, name :: kctx) t)
	  | T.UniI (s, name, t) => UniI (on_sort sctx s, name, on_type (name :: sctx, kctx) t)
	  | T.ExI (s, name, t) => ExI (on_sort sctx s, name, on_type (name :: sctx, kctx) t)
	  | T.AppRecur (name, name_sorts, t, is) => AppRecur (name, map (mapSnd (on_sort sctx)) name_sorts, on_type (rev (map #1 name_sorts) @ sctx, name :: kctx) t, map (on_idx sctx) is)
	  | T.AppV (x, ts, is) => AppV (on_var kctx x, map (on_type ctx) ts, map (on_idx sctx) is)
	  | T.Int => Int

    fun on_ptrn cctx pn =
	case pn of
	    E.Constr (x, inames, ename) => Constr (on_var cctx x, inames, ename)

    fun on_expr (ctx as (sctx, kctx, cctx, tctx)) e =
	let fun add_t name (sctx, kctx, cctx, tctx) = (sctx, kctx, cctx, name :: tctx)
	    val skctx = (sctx, kctx)
	in
	    case e of
		E.Var x => Var (on_var tctx x)
	      | E.Abs (t, name, e) => Abs (on_type skctx t, name, on_expr (add_t name ctx) e)
	      | E.App (e1, e2) => App (on_expr ctx e1, on_expr ctx e2)
	      | E.TT => TT
	      | E.Pair (e1, e2) => Pair (on_expr ctx e1, on_expr ctx e2)
	      | E.Fst e => Fst (on_expr ctx e)
	      | E.Snd e => Snd (on_expr ctx e)
	      | E.Inr (t, e) => Inr (on_type skctx t, on_expr ctx e)
	      | E.Inl (t, e) => Inl (on_type skctx t, on_expr ctx e)
	      | E.SumCase (e, name1, e1, name2, e2) => SumCase (on_expr ctx e, name1, on_expr (add_t name1 ctx) e1, name2, on_expr (add_t name2 ctx) e2)
	      | E.Fold (t, e) => Fold (on_type skctx t, on_expr ctx e)
	      | E.Unfold e => Unfold (on_expr ctx e)
	      | E.AbsT (name, e) => AbsT (name, on_expr (sctx, name :: kctx, cctx, tctx) e)
	      | E.AppT (e, t) => AppT (on_expr ctx e, on_type skctx t)
	      | E.AbsI (s, name, e) => AbsI (on_sort sctx s, name, on_expr (name :: sctx, kctx, cctx, tctx) e)
	      | E.AppI (e, i) => AppI (on_expr ctx e, on_idx sctx i)
	      | E.Pack (t, i, e) => Pack (on_type skctx t, on_idx sctx i, on_expr ctx e)
	      | E.Unpack (e1, t, d, iname, ename, e2) => Unpack (on_expr ctx e1, on_type skctx t, on_idx sctx d, iname, ename, on_expr (iname :: sctx, kctx, cctx, ename :: tctx) e2)
	      | E.Fix (t, name, e) => Fix (on_type skctx t, name, on_expr (add_t name ctx) e)
	      | E.Let (e1, name, e2) => Let (on_expr ctx e1, name, on_expr (add_t name ctx) e2)
	      | E.Ascription (e, t) => Ascription (on_expr ctx e, on_type skctx t)
	      | E.AscriptionTime (e, d) => AscriptionTime (on_expr ctx e, on_idx sctx d)
	      | E.Const n => Const n
	      | E.Plus (e1, e2) => Plus (on_expr ctx e1, on_expr ctx e2)
	      | E.AppConstr (x, ts, is, e) => AppConstr (on_var cctx x, map (on_type skctx) ts, map (on_idx sctx) is, on_expr ctx e)
	      | E.Case (e, t, d, rules) => Case (on_expr ctx e, on_type skctx t, on_idx sctx d, map (fn (pn, e) => (on_ptrn cctx pn, let val (inames, enames) = E.ptrn_names pn in on_expr (inames @ sctx, kctx, cctx, enames @ tctx ) e end)) rules)
	      | E.Never t => Never (on_type skctx t)
	end

    fun on_constr (ctx as (sctx, kctx)) (family, tnames, name_sorts, t, is) =
	let val sctx' = rev (map #1 name_sorts) @ sctx
	in
	    (on_var kctx family, tnames, 
	     (rev o #1) (foldl (fn ((name, s), (acc, names)) => ((name, on_sort (names @ sctx) s) :: acc, name :: names)) ([], []) name_sorts),
	     on_type (sctx', rev tnames @ kctx) t,
	     map (on_idx sctx') is
	    )
	end

    fun on_kind ctx k =
	case k of
	    T.ArrowK (n, sorts) => ArrowK (n, map (on_sort ctx) sorts)

in
fun resolve_type ctx e = runError (fn () => on_type ctx e) ()
fun resolve_expr ctx e = runError (fn () => on_expr ctx e) ()
fun resolve_constr ctx e = runError (fn () => on_constr ctx e) ()
fun resolve_kind ctx e = runError (fn () => on_kind ctx e) ()
end

end
