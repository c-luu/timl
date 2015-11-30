structure Elaborate = struct
structure S = Ast
structure E = NamefulExpr
open S
open E

exception Error of region * string

local

    fun runError m _ =
	OK (m ())
	handle
	Error e => Failed e

    fun elab_i i =
	case i of
	    S.VarI (x, r) =>
	    if x = "true" then
		TrueI r
	    else if x = "false" then
		FalseI r
            else if x = "_" then
                UVarI ((), r)
	    else
		VarI (x, r)
	  | S.ConstIN n =>
	    ConstIN n
	  | S.ConstIT x =>
	    ConstIT x
          | S.UnOpI (opr, i, r) => UnOpI (opr, elab_i i, r)
	  | S.BinOpI (opr, i1, i2, _) =>
	    BinOpI (opr, elab_i i1, elab_i i2)
	  | S.TTI r =>
	    TTI r

    fun elab_p p =
	case p of
	    ConstP (name, r) =>
	    if name = "True" then
		True r
	    else if name = "False" then
		False r
	    else raise Error (r, sprintf "Unrecognized proposition: $" [name])
          | S.Not (p, r) => Not (elab_p p, r)
	  | S.BinConn (opr, p1, p2, _) => BinConn (opr, elab_p p1, elab_p p2)
	  | S.BinPred (opr, i1, i2, _) => BinPred (opr, elab_i i1, elab_i i2)

    fun elab_b (name, r) =
	if name = "Time" then
	    (Base Time, r)
	else if name = "Nat" then
	    (Base Nat, r)
	else if name = "Bool" then
	    (Base Bool, r)
	else if name = "Unit" then
	    (Base BSUnit, r)
	else if name = "Profile" then
	    (Base Profile, r)
        else if name = "_" then
            (UVarBS (), r)
	else raise Error (r, sprintf "Unrecognized base sort: $" [name])

    fun elab_s s =
	case s of
	    S.Basic b =>
            (case elab_b b of
                 (UVarBS (), r) => UVarS ((), r)
               | b => Basic b
            )
	  | S.Subset (b, name, p, _) => Subset (elab_b b, BindI (name, elab_p p))

    fun get_is t =
	case t of 
	    AppTI (t, i, _) =>
	    let val (t, is) = get_is t in
		(t, is @ [i])
	    end
	  | _ => (t, [])

    fun get_ts t =
	case t of 
	    AppTT (t, t2, _) =>
	    let val (t, ts) = get_ts t in
		(t, ts @ [t2])
	    end
	  | _ => (t, [])

    fun is_var_app_ts t = 
	let val (t, ts) = get_ts t in
	    case t of
		S.VarT x => SOME (x, ts)
	      | _ => NONE
	end

    fun elab_mt t =
      case t of
	  S.VarT (x, r) =>
          if x = "unit" then
              Unit r
          else if x = "int" then
              Int r
          else if x = "_" then
              UVar ((), r)
          else
              AppV ((x, r), [], [], r)
	| S.Arrow (t1, d, t2, _) => Arrow (elab_mt t1, elab_i d, elab_mt t2)
	| S.Prod (t1, t2, _) => Prod (elab_mt t1, elab_mt t2)
	| S.Quan (quan, binds, t, _) =>
	  let fun f (b, t) =
		case b of
		    Sorting (x, s, _) =>
		    (case quan of
			 Forall => UniI (elab_s s, BindI (x, t))
		       | Exists => ExI (elab_s s, BindI (x, t)))
	  in
	      foldr f (elab_mt t) binds
	  end
	| S.AppTT (t1, t2, r) =>
	  (case is_var_app_ts t1 of
	       SOME (x, ts) => AppV (x, map elab_mt (ts @ [t2]), [], r)
	     | NONE => raise Error (r, "Head of type-type application must be a variable"))
	| S.AppTI (t, i, r) =>
	  let val (t, is) = get_is t 
	      val is = is @ [i]
	  in
	      case is_var_app_ts t of
		  SOME (x, ts) => AppV (x, map elab_mt ts, map elab_i is, r)
		| NONE => raise Error (r, "The form of type-index application can only be (recursive-type indices) or (variable types indices)")
	  end

    fun elab_return return = mapPair (Option.map elab_mt, Option.map elab_i) return
                                        
    fun elab_pn pn =
      case pn of
          S.ConstrP (cname, inames, pn, r) =>
          ConstrP (cname, inames, Option.map elab_pn pn, r)
        | S.TupleP (pns, r) =>
          (case pns of
               [] => TTP r
             | pn :: pns => foldl (fn (pn2, pn1) => PairP (pn1, elab_pn pn2)) (elab_pn pn) pns)
        | S.AliasP (name, pn, r) =>
          AliasP (name, elab_pn pn, r)
        | S.AnnoP (pn, t, r) =>
          AnnoP (elab_pn pn, elab_mt t)
                                                              
    fun elab e =
	case e of
	    S.Var x => Var x
	  | S.Tuple (es, r) =>
	    (case es of
		 [] => TT r
	       | e :: es => foldl (fn (e2, e1) => Pair (e1, elab e2)) (elab e) es)
	  | S.Abs (binds, (t, d), e, r) =>
	    let 
                fun f (b, e) =
		  case b of
		      Typing pn => Abs (elab_pn pn, e)
		    | TBind (Sorting (x, s, _)) => AbsI (elab_s s, x, e)
                val e = elab e
                val e = case d of SOME d => AscriptionTime (e, elab_i d) | _ => e
                val e = case t of SOME t => Ascription (e, elab_mt t) | _ => e
	    in
		foldr f e binds
	    end
	  | S.App (e1, e2, _) =>
	    let 
		fun default () = App (elab e1, elab e2)
	    in
		case e1 of
		    S.Var (x, _) => 
		    if x = "fst" then Fst (elab e2)
		    else if x = "snd" then Snd (elab e2)
		    else default ()
		  | S.AppI (S.AppT (S.Var (x, _), t, _), i, _) =>
		    if x = "pack" then Pack (elab_mt t, elab_i i, elab e2)
		    else default ()
		  | _ => default ()
	    end
	  | S.AppI (e, i, _) =>
	    AppI (elab e, elab_i i)
	  | S.AppT (e, t, r) =>
	    raise Error (r, "Don't support explicit type arguments")
	  | S.Case (HUnpack, e, return, rules, r) =>
	    let
	    in
		case rules of
		    [(S.ConstrP ((c, r), [iname], SOME (S.ConstrP ((ename, _), [], NONE, _)), _), e1)] =>
		    if c = "pack" then
			Unpack (elab e, elab_return return, iname, ename, elab e1)
		    else
			raise Error (r, "Constructor name must be pack")
		  | _ => raise Error (r, "Pattern can only be (pack {idx} x => ...)")
	    end
	  | S.Case (HCase, e, return, rules, r) =>
	    let 
	    in
		Case (elab e, elab_return return, map (fn (pn, e) => (elab_pn pn, elab e)) rules, r)
	    end
	  | S.Ascription (e, t, _) =>
	    Ascription (elab e, elab_mt t)
	  | S.AscriptionTime (e, i, _) =>
	    AscriptionTime (elab e, elab_i i)
	  | S.Let (decs, e, r) =>
            Let (map elab_decl decs, elab e, r)
	  | S.Const n => Const n
          | S.BinOp (opr, e1, e2, _) => BinOp (opr, elab e1, elab e2)

    and elab_decl decl =
        case decl of
	    S.Val (tnames, pn, e, r) =>
            Val (tnames, elab_pn pn, elab e, r)
	  | S.Rec (tnames, name, binds, (t, d), e, r) =>
            let
                fun f bind =
                    case bind of
		        Typing pn => TypingST (elab_pn pn)
		      | TBind (Sorting (nm, s, _)) => SortingST (nm, elab_s s)
                val binds = map f binds
                val t = default (UVar ((), r)) (Option.map elab_mt t)
                val d = default (UVarI ((), r)) (Option.map elab_i d)
                val e = elab e
            in
	        Rec (tnames, name, (binds, ((t, d), e)), r)
            end
          | S.Datatype (name, tnames, sorts, constrs, r) =>
            let fun default_t2 r = foldl (fn (arg, f) => S.AppTT (f, S.VarT (arg, r), r)) (S.VarT (name, r)) tnames
                fun elab_constr (((cname, _), core, r) : S.constr_decl) : constr_decl =
                  let val (binds, t1, t2) = default ([], S.VarT ("unit", r), SOME (default_t2 r)) core
                      val t2 = default (default_t2 r) t2
                      fun f bind =
                        case bind of
                            Sorting ((name, _), sort, r) => (name, elab_s sort)
                      val binds = map f binds
                      val t2_orig = t2
                      val (t2, is) = get_is t2
                      val (t2, ts) = get_ts t2
                      val () = if case t2 of S.VarT (x, _) => x = name | _ => false then
                                   ()
                               else
                                   raise Error (S.get_region_t t2, "Result type of constructor must be " ^ name)
                      val () = if length ts = length tnames then () else raise Error (S.get_region_t t2_orig, "Must have type arguments " ^ join " " tnames)
                      fun f (t, tname) =
                        let val targ_mismatch = "This type argument must be " ^ tname in
                            case t of
                                S.VarT (x, r) => if x = tname then () else raise Error (r, targ_mismatch)
                              | _ => raise Error (S.get_region_t t, targ_mismatch)
                        end
                      val () = app f (zip (ts, tnames))
                  in
                      (cname, fold_ibinds (binds, (elab_mt t1, map elab_i is)), r)
                  end
            in
                Datatype (name, tnames, map elab_s sorts, map elab_constr constrs, r)
            end
          | S.IdxDef ((name, r), s, i) =>
            let
                val s = case s of SOME s => elab_s s | NONE => UVarS ((), r)
            in
                IdxDef ((name, r), s, elab_i i)
            end

in
val elaborate = elab
fun elaborate_opt e = runError (fn () => elab e) ()
val elaborate_decl = elab_decl
fun elaborate_decl_opt d = runError (fn () => elab_decl d) ()
end

end
