- [x] Remove bsort from Eq 
- [x] 'msg' in 'str_error' should be of (string list)
- [x] split 'case' syntax into 'case', 'sumcase' and 'unpack'
- [x] 'case' and 'unpack' should allow omitting return-clause and try to forget unescapable variables (like what 'let' does)
- [x] Distill the 'bind' pattern
- [x] Disallow impredicative universal types
- [x] Type inference
- [x] Idx inference
Kind-of. 9. Allow [datatype] to have idx arguments that don't change.
- [x] Multi-argument idx functions.
- [x] Add an optional idx to [Quan], to link the remaining unification variables in types and the witnesses found by the Master Theorem solver.
- [x] Infer by Master Theorem then check.
- [x] Single variable Master Theorem case.
- [x] Error line number on multiple files.
- [x] Make linking between inferred existential variable values and types better.
- [x] Copy function signature annotation to case annotation
Abondoned. 17. Unit and product types are required to define datatypes. 17. Remove unit and product types from the language, and have standard library.
- [x] Example: Tree flatten.
- [x] Example: Insertion sort.
- [x] Have reference and arrays.
- [x] RB-tree insertion.
- [x] RB-tree lookup.
- [x] Braun tree insertion.
- [ ] A bug of position reporting when I change bigO spec of msort in msort.timl from [$m * $n * log2 $n] to [$n * log2 $n].
- [x] 'return _ using' works but 'return using' doesn't in msort.timl and tree.timl.
- [x] Change syntax order of function name and [t] declares.
- [x] Be able to infer for [tree_map] and [tree_foldl].
Partially. 28. Have module system.
    Road map to add module system:
    * [x] Have a barebone module system with only modules, signatures, sealing, functors and 'open'. No hierarchy (embeded modules), module alias, signature alias, 'where'/'sharing', 'include'.
    * [ ] Combine name-resolve and typecheck.
    * [ ] Combine cctx and tctx into tctx.
    * [ ] Combine idx and type into constructors, sort and kind into kind, Combine sctx and kctx into kctx.
    * [ ] Add record types.
    * [ ] Add singleton kinds, dependent record kinds, dependent arrow kinds.
    * [ ] Elaborate modules and signatures into core language.
- [x] Bug of type inference in tree_append_rlm. The inferred type has [{n} tree tree] and [{n} list list].
- [x] Put [Unit] back to mtype from [base_type] because [Unit] is not a base type like [Int] but a structural building block.
- [ ] Have a good error message when insertion_sort.timl/[insert] doesn't have the needed return-annotation on [case].
- [x] Be able to infer for [insertion_sort].
- [ ] [unify]'s [(UVar, UVar)] case could be dangerous: shift_invis may not be transactional, and there is no circularity check.
- [x] Have a standard library.
- [x] Automatically generate premises in [(VarP, Never)] case of [match_ptrn], from complement cover of previous rules.
- [x] [case] should also copy [fun]'s [return] clause even without [using].
Abondoned. No problem. 37. [as] pattern may have a problem in [balance_left].
- [x] Bug: redundancy checker runs forever on [balance_left].
Done.. 39. rbt.timl typecheckes when using ForgetError-less [subst] and ForgetError-full [forget]. Investigate why.
- [x] [find_habitant] can further simplify covers and speed up.
- [x] Have [type =] type aliasing.
- [x] Maximally insertion of index arguments.
- [x] Maximally insertion of index arguments in patterns.
- [x] nouvar-expr/passp/Imply/_ is not sound, possibly losing information.
- [ ] [subst_invis_no_throw] should be implemented in a safe way where uvars that can see the target variable are unified with a new shifted uvars that can't see it, and [bring_forward_anchor] needs to be more sophisticated to only put new anchor when there is no shift (and the notifier in [Exists] needs to do some shift) because now not every uvar has an anchor.
Dono. 46. Braun tree extraction.
- [x] rename "peel_" to "collect_".
- [x] Register admitted things.
- [ ] Make SMT batch response parsing smarter (don't check response length beforehand)
- [x] Simplify MaxI using SMT solver.
- [x] Have binary search with arrays.
- [x] Have binary heap with arrays.
- [x] Have in-place merge sort with arrays.
- [x] Have k-median search with arrays.
- [x] Investigate amortized complexity analysis.
- [ ] Prove in Coq.
- [ ] Infer [BigO] arity.
- [x] Have built-in indexed [uint].
- [ ] Pretty-print to SML.
- [ ] Combine cctx and tctx.
- [x] Add <> notation.
- [ ] Add a return clause in [Case] to mean the time including the matchee.
- [x] Amortized complexity of queue implementation by two stacks.
- [ ] Infer type according to pattern.
- [ ] Wrongly inferred [T_insert_delete_seq_0] to be (fn n => $n) without the [2.0 + 48.0 * $n] annotation. The source of the problem: unsoundness in bigO-solver.sml/solve_exists(). 
- [ ] Have some Nat/Time inference.
- [ ] Unify [UnOpI], [DivI] and [ExpI].
- [x] Change [unify_s] to [is_sub_sort].
- [x] Should apply solvers and check no-uvar after every module, not every file (unless we enforce one-module-per-file policy). 
- [ ] Move VC openings from [check_decl] to [check_decls].
- [ ] [subst] should do lazy shifting, not eager.
- [x] The last two examples in bigO-evolve.timl about using [idx] instead of [absidx] doesn't work now.
- [x] Simplify unused 'forall' in [prop]. The unused foralls are Big-O premises.
- [ ] [BigOEvolveSealed] in bigO-evolve.timl doesn't work yet.
- [x] if-then-else and list syntax.
- [ ] Restore the version of [link_sig] in revision 00ba072, because a module may have uvars before sealing, and uvars can't be retrieved from a module.
- [ ] Big-O solver should heuristically distinguish "defining" side of [TimeFun] uvars from the "using" side, by the rule-of-thumb that only [_ <= f x] is a defining constraint of [f].
- [ ] Do a module dependent analysis of each module and only bring the needed modules into [gctx] VC context.
- [x] Have double-linked lists.
- [x] rbt6.timl:  absidx sort [Time] inference error in [IntKey].
- [x] Currently [absidx ... with ... end] is "scoped abstract index". We should have "unscoped" or "module-scoped" abstract index [absidx id = ...] so within the module [id]'s definition is visible but outside the module it's not.
- [ ] Make [kind]'s sorts dependent.
- [ ] Generate typing derivations.
- [x] Remove annotations on [case] (at least in a mode).
- [x] [datatype] can introduce index variable names at the first line for every constructor.
- [ ] [find_hab] is too slow on array-msort.timl on array-msort-inplace.timl

# To-do Examples:

- [x] Binary search with arrays.
- [x] binary heap with arrays.
- [x] In-place merge sort with arrays.
- [x] k-median search with arrays.
- [x] Quicksort.
- [x] Dijkstra algorithm.
- [x] Two-stack queue (amortized).
- [x] Double-linked lists.
- [ ] Union-find (amortized).
- [x] Some example showcasing the flexibility of "size".