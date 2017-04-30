(* normalization *)

structure Normalize = struct
open UVar
open Expr
open Subst
open TypecheckUtil
       
fun update_bs bs =
  case bs of
      UVarBS x =>
      (case !x of
           Refined bs => 
           let 
             val bs = update_bs bs
             val () = x := Refined bs
           in
             bs
           end
         | Fresh _ => bs
      )
    | BSArrow (a, b) => BSArrow (update_bs a, update_bs b)
    | Base _ => bs

fun load_uvar update origin x = 
  case !x of
      Refined a => 
      let 
        val a = update a
        val () = x := Refined a
      in
        a
      end
    | Fresh _ => origin
                   
fun update_i i =
  case i of
      UVarI (x, r) => load_uvar update_i i x
    | UnOpI (opr, i, r) => UnOpI (opr, update_i i, r)
    | DivI (i1, n2) => DivI (update_i i1, n2)
    | ExpI (i1, n2) => ExpI (update_i i1, n2)
    | BinOpI (opr, i1, i2) => BinOpI (opr, update_i i1, update_i i2)
    | Ite (i1, i2, i3, r) => Ite (update_i i1, update_i i2, update_i i3, r)
    | VarI _ => i
    | ConstIN _ => i
    | ConstIT _ => i
    | TTI _ => i
    | TrueI _ => i
    | FalseI _ => i
    | AdmitI _ => i
    | IAbs (b, Bind (name, i), r) => IAbs (update_bs b, Bind (name, update_i i), r)

fun update_p p =
  case p of
      Quan (q, bs, Bind (name, p), r) => Quan (q, update_bs bs, Bind (name, update_p p), r)
    | BinConn (opr, p1, p2) => BinConn (opr, update_p p1, update_p p2)
    | BinPred (opr, i1, i2) => BinPred (opr, update_i i1, update_i i2)
    | Not (p, r) => Not (update_p p, r)
    | True _ => p
    | False _ => p

fun update_s s =
  case s of
      UVarS (x, r) => load_uvar update_s s x
    | Basic _ => s
    | Subset ((b, r1), Bind (name, p), r) => Subset ((update_bs b, r1), Bind (name, update_p p), r)
    | SortBigO ((b, r1), i, r) => SortBigO ((update_bs b, r1), update_i i, r)
    | SAbs (s1, Bind (name, s), r) => SAbs (update_s s1, Bind (name, update_s s), r)
    | SApp (s, i) => SApp (update_s s, update_i i)

fun update_k k = mapSnd (map update_s) k
                      
fun update_mt t =
  case t of
      UVar (x, r) => load_uvar update_mt t x
    | Unit r => Unit r
    | Arrow (t1, d, t2) => Arrow (update_mt t1, update_i d, update_mt t2)
    | TyArray (t, i) => TyArray (update_mt t, update_i i)
    | TyNat (i, r) => TyNat (update_i i, r)
    | Prod (t1, t2) => Prod (update_mt t1, update_mt t2)
    | UniI (s, Bind (name, t1), r) => UniI (update_s s, Bind (name, update_mt t1), r)
    | MtVar x => MtVar x
    | MtAbs (k, Bind (name, t), r) => MtAbs (update_k k, Bind (name, update_mt t), r)
    | MtApp (t1, t2) => MtApp (update_mt t1, update_mt t2)
    | MtAbsI (s, Bind (name, t), r) => MtAbsI (update_s s, Bind (name, update_mt t), r)
    | MtAppI (t, i) => MtAppI (update_mt t, update_i i)
    | AppV (y, ts, is, r) => AppV (y, map update_mt ts, map update_i is, r)
    | BaseType a => BaseType a

fun whnf_i i =
  case i of
      UVarI (x, r) => load_uvar whnf_i i x
    | BinOpI (opr, i1, i2) =>
      let
        val i1 = whnf_i i1
        val i2 = whnf_i i2
      in
        case (opr, i1) of
            (IApp, IAbs (_, Bind (_, i1), _)) => whnf_i (subst_i_i i2 i1)
          | _ => BinOpI (opr, i1, i2)
      end
    | Ite (i1, i2, i3, r) =>
      let
        val i1 = whnf_i i1
        val i2 = whnf_i i2
        val i3 = whnf_i i3
      in
        case i1 of
            TrueI _ => i2
          | FalseI _ => i3
          | _ => Ite (i1, i2, i3, r)
      end
    | _ => i

fun normalize_i i =
  case i of
      UVarI (x, r) => load_uvar normalize_i i x
    | UnOpI (opr, i, r) => UnOpI (opr, normalize_i i, r)
    | DivI (i1, n2) => DivI (normalize_i i1, n2)
    | ExpI (i1, n2) => ExpI (normalize_i i1, n2)
    | BinOpI (opr, i1, i2) =>
      let
        val i1 = normalize_i i1
        val i2 = normalize_i i2
      in
        case (opr, i1) of
            (IApp, IAbs (_, Bind (_, i1), _)) => normalize_i (subst_i_i i2 i1)
          | _ => BinOpI (opr, i1, i2)
      end
    | Ite (i1, i2, i3, r) =>
      let
        val i1 = normalize_i i1
        val i2 = normalize_i i2
        val i3 = normalize_i i3
      in
        case i1 of
            TrueI _ => i2
          | FalseI _ => i3
          | _ => Ite (i1, i2, i3, r)
      end
    | VarI _ => i
    | ConstIN _ => i
    | ConstIT _ => i
    | TTI _ => i
    | TrueI _ => i
    | FalseI _ => i
    | AdmitI _ => i
    | IAbs (b, Bind (name, i), r) => IAbs (update_bs b, Bind (name, normalize_i i), r)

fun normalize_p p =
  case p of
      Quan (q, bs, Bind (name, p), r) => Quan (q, update_bs bs, Bind (name, normalize_p p), r)
    | BinConn (opr, p1, p2) => BinConn (opr, normalize_p p1, normalize_p p2)
    | BinPred (opr, i1, i2) => BinPred (opr, normalize_i i1, normalize_i i2)
    | Not (p, r) => Not (normalize_p p, r)
    | True _ => p
    | False _ => p
                   
fun whnf_s s =
  case s of
      UVarS (x, r) => load_uvar whnf_s s x
    | SApp (s, i) =>
      let
        val s = whnf_s s
        val i = whnf_i i
      in
        case s of
            SAbs (_, Bind (_, s), _) => whnf_s (subst_i_s i s)
          | _ => SApp (s, i)
      end
    | _ => s
             
fun normalize_s s =
  case s of
      UVarS (x, r) => load_uvar normalize_s s x
    | Basic _ => s
    | Subset ((b, r1), Bind (name, p), r) => Subset ((update_bs b, r1), Bind (name, normalize_p p), r)
    | SortBigO ((b, r1), i, r) => SortBigO ((update_bs b, r1), normalize_i i, r)
    | SAbs (s_arg, Bind (name, s), r) => SAbs (normalize_s s_arg, Bind (name, normalize_s s), r)
    | SApp (s, i) =>
      let
        val s = normalize_s s
        val i = normalize_i i
      in
        case s of
            SAbs (_, Bind (_, s), _) => normalize_s (subst_i_s i s)
          | _ => SApp (s, i)
      end
        
fun normalize_k k = mapSnd (map normalize_s) k
                                      
fun is_type_variable r y =
  (* ToDo: can do better *)
  case y of
      AppV (x, [], [], _) => x
    (* | MtVar x => x *)
    | _ => raise Error (r, ["Head of type operator application must be a datatype name"])
                 
fun eval_AppV y (ts, is, r) =
  if null ts andalso null is then
    y
  else
    AppV (is_type_variable r y, ts, is, r)
         
fun whnf_mt gctx kctx (t : mtype) : mtype =
  let
    val whnf_mt = whnf_mt gctx
  in
    case t of
        UVar (x, r) => load_uvar (whnf_mt kctx) t x
      | AppV (y, ts, is, r) =>
        let
          val y = try_retrieve_MtVar (whnf_mt kctx) gctx kctx y
        in
          eval_AppV y (ts, is, r)
        end
      | MtVar x => try_retrieve_MtVar (whnf_mt kctx) gctx kctx x
      | MtAppI (t, i) =>
        let
          val t = whnf_mt kctx t
          val i = whnf_i i
        in
          case t of
              MtAbsI (_, Bind (_, t), _) => whnf_mt kctx (subst_i_mt i t)
            | _ => MtAppI (t, i)
        end
      | MtApp (t1, t2) =>
        let
          val t1 = whnf_mt kctx t1
          val t2 = whnf_mt kctx t2
        in
          case t1 of
              MtAbs (_, Bind (_, t1), _) => whnf_mt kctx (subst_t_mt t2 t1)
            | _ => MtApp (t1, t2)
        end
      | _ => t
  end

fun normalize_mt gctx kctx t =
  let
    val normalize_mt = normalize_mt gctx
  in
    case t of
        UVar (x, r) => load_uvar (normalize_mt kctx) t x
      | Unit r => Unit r
      | Arrow (t1, d, t2) => Arrow (normalize_mt kctx t1, update_i d, normalize_mt kctx t2)
      | TyArray (t, i) => TyArray (normalize_mt kctx t, update_i i)
      | TyNat (i, r) => TyNat (update_i i, r)
      | Prod (t1, t2) => Prod (normalize_mt kctx t1, normalize_mt kctx t2)
      | UniI (s, Bind (name, t1), r) => UniI (update_s s, Bind (name, normalize_mt (shiftx_i_kctx 1 kctx) t1), r)
      | AppV (y, ts, is, r) =>
        let
          val y = try_retrieve_MtVar (normalize_mt kctx) gctx kctx y
          val ts = map (normalize_mt kctx) ts
          val is = map update_i is
        in
          eval_AppV y (ts, is, r)
        end
      | MtVar x => try_retrieve_MtVar (normalize_mt kctx) gctx kctx x
      | MtAbsI (s, Bind (name, t), r) => MtAbsI (normalize_s s, Bind (name, normalize_mt kctx t), r)
      | MtAppI (t, i) =>
        let
          val t = normalize_mt kctx t
          val i = normalize_i i
        in
          case t of
              MtAbsI (_, Bind (_, t), _) => normalize_mt kctx (subst_i_mt i t)
            | _ => MtAppI (t, i)
        end
      | MtAbs (k, Bind (name, t), r) => MtAbs (normalize_k k, Bind (name, normalize_mt kctx t), r)
      | MtApp (t1, t2) =>
        let
          val t1 = normalize_mt kctx t1
          val t2 = normalize_mt kctx t2
        in
          case t1 of
              MtAbs (_, Bind (_, t1), _) => normalize_mt kctx (subst_t_mt t2 t1)
            | _ => MtApp (t1, t2)
        end
      | BaseType a => BaseType a
  end

fun normalize_t gctx kctx t =
  case t of
      Mono t => Mono (normalize_mt gctx kctx t)
    | Uni (Bind (name, t), r) => Uni (Bind (name, normalize_t gctx (add_kinding (fst name, Type) kctx) t), r)

end
