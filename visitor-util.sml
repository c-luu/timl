structure VisitorUtil = struct
open Util
       
fun extend_noop this env x1 = env
val visit_noop = return3
fun visit_imposs msg _ _ _ = raise Impossible msg
fun visit_pair visit_fst visit_snd env (a, b) =
  (visit_fst env a, visit_snd env b)
fun visit_list visit env = map (visit env)
end
                          
