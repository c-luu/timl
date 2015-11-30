structure TiML = struct
structure E = NamefulExpr
open Expr
open Util
open Parser
open Elaborate
open NameResolve
open TypeCheck

infixr 0 $

fun print_result show_region filename (((decls, ctxd, ds, ctx), vcs) : tc_result) =
  let 
      val ctxn as (sctxn, kctxn, cctxn, tctxn) = ctx_names ctx
      val header =
          sprintf "Typechecked $" [filename] ::
          [""]
      val type_lines =
          (List.concat o map (fn (name, t) => [sprintf "$ : $" [name, str_t (sctxn, kctxn) t], ""]) o rev o #4) ctxd
      val time_lines =
          "Times:" :: "" ::
          (List.concat o map (fn d => [sprintf "|> $" [str_i sctxn d], ""])) ds
      val vc_lines =
          sprintf "Verification Conditions: [count=$]" [str_int (length vcs)] ::
          "" ::
	  concatMap (fn vc => VC.str_vc show_region filename vc @ [""]) vcs
      val s = join_lines 
                  (
                    header
                    @ type_lines 
                    @ time_lines 
                  (* @ vc_lines *)
                  )
  in
      s
  end

exception Error of string
                       
open SMT2Printer
open SMTSolver

fun typecheck_file (filename, ctx) =
  let
      val ctxn = ctx_names ctx
      val decls = parse_file filename
      val decls = map elaborate_decl decls
      (* val () = (print o join_lines o map (suffix "\n") o fst o E.str_decls ctxn) decls *)
      val decls = resolve_decls ctxn decls
      (* val () = (print o join_lines o map (suffix "\n") o fst o str_decls ctxn) decls *)
      val result as ((decls, ctxd, ds, ctx), vcs) = typecheck_decls ctx decls
      (* val () = write_file (filename ^ ".smt2", to_smt2 vcs) *)
      val () = println $ print_result false filename result
      val () = println $ sprintf "Generated $ proof obligations." [str_int $ length vcs]
      val (_, unsats) = mapSnd (smt_solver filename) result
      (* val unsats = map (fn vc => (vc, NONE)) vcs *)
      fun print_unsat filename (vc, counter) =
        VC.str_vc true filename vc @
        [""] @
        (case counter of
             SOME assigns =>
             ["Counter-example:"] @
             map (fn (name, value) => sprintf "$ = $" [name, value]) assigns
           | NONE => ["Can't prove and can't find counter example"]) @
        [""]        
      val () =
          if length unsats <> 0 then
              (println (sprintf "Can't prove the following $ proof obligations:\n" [str_int $ length unsats]);
               (app println o concatMap (print_unsat filename)) unsats)
          else
              println "All conditions proved."
  in
      ctx
  end
  handle 
  Elaborate.Error (r, msg) => raise Error $ str_error "Error" filename r ["Elaborate error: " ^ msg]
  | NameResolve.Error (r, msg) => raise Error $ str_error "Error" filename r ["Resolve error: " ^ msg]
  | TypeCheck.Error (r, msg) => raise Error $ str_error "Error" filename r ((* "Type error: " :: *) msg)
  | Parser.Error => raise Error "Unknown parse error"
  | SMTError msg => raise Error $ "SMT error: " ^ msg
  | IO.Io e => raise Error $ sprintf "IO error in function $ on file $" [#function e, #name e]
  | OS.SysErr (msg, err) => raise Error $ sprintf "System error$: $" [(default "" o Option.map (prefix " " o OS.errorName)) err, msg]
                                                         
fun main filenames =
  let
      val ctx = foldl typecheck_file empty_ctx filenames
  in
      ctx
  end
                      
end

structure Main = struct
open Util
open OS.Process
         
fun main (prog_name, args : string list) : int = 
  let
      val _ =
	  case args of
	      [] => (println "Usage: THIS filename1 filename2 ..."; exit(failure))
	    | filenames =>
              TiML.main filenames
  in	
      0
  end
  handle 
  TiML.Error msg => (println msg; 1)
  | Impossible msg => (println ("Impossible: " ^ msg); 1)

end
