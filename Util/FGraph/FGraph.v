(**
CoLoR, a Coq library on rewriting and termination.
See the COPYRIGHTS and LICENSE files.

- Frederic Blanqui, 2011-03-21

finite graphs
*)

Require Import FSetUtil FMapUtil OrderedType RelUtil LogicUtil.

Set Implicit Arguments.

Module Make (X : OrderedType).

Module Export S := FSetUtil.Make X.
Module Export M := FMapUtil.Make X.

Import X.

(***********************************************************************)
(** A finite graph on X.t is represented by its successor map: a
finite map from X.t to the type of finite sets on X.t. Since an
element can be mapped to the empty set, this representation is not
unique and the setoid equality on maps based on the setoid equality on
sets (meq) does not identify a map with no mapping for x and a map
mapping x to the empty set. We therefore have to consider another
equivalence (geq). We will consider that two graphs are equivalent if
they define the same relation. See below for more details. *)

Definition graph := XMap.t XSet.t.

Implicit Type g h : graph.

Definition meq : relation graph := XMap.Equiv XSet.Equal.

(***********************************************************************)
(** relation corresponding to a graph *)

(*COQ: necessary to define rel (hereafter) as a coercion *)
SubClass relation_on_X := relation X.t.

Definition rel g : relation_on_X :=
  fun x y => exists s, find x g = Some s /\ XSet.In y s.

Coercion rel : graph >-> relation_on_X.

Lemma rel_empty : rel (empty XSet.t) == @empty_rel X.t.

Proof.
rewrite rel_eq; intros a b. unfold empty_rel. intuition.
destruct H as [sa [a1 a2]]. rewrite <- find_mapsto_iff in a1.
rewrite empty_mapsto_iff in a1. hyp.
Qed.

Instance rel_meq_ext' : Proper (meq ==> eq ==> eq ==> impl) rel.

Proof.
intros g g' gg' x x' xx' y y' yy'. unfold impl, rel. intuition.
destruct H as [sx [hx hy]]. rewrite xx' in hx.
destruct (Equiv_find_Some gg' hx) as [sx']. destruct H.
exists sx'. intuition. rewrite <- yy', <- H0. hyp.
Qed.

Instance rel_meq_ext : Proper (meq ==> eq ==> eq ==> iff) rel.

Proof.
split; apply rel_meq_ext'; hyp||(symmetry;hyp).
Qed.

Lemma find_Some_rel {g x s} : find x g = Some s ->
  XSet.is_empty s = false -> exists y, rel g x y.

Proof.
intros hx hs. destruct (choose_mem_3 _ hs) as [y [h1 h2]].
rewrite <- mem_iff in h2. exists y. exists s. intuition.
Qed.

(***********************************************************************)
(** singleton relation *)

Definition id x y a b := eq a x /\ eq b y.

(***********************************************************************)
(** relation defined by an element and its successors *)

Definition succ x s a b := eq a x /\ XSet.In b s.

Instance succ_m' : Proper (eq ==> XSet.Equal ==> @inclusion X.t) succ.

Proof.
intros x x' xx' s s' ss' a b. unfold succ. rewrite xx', ss'. tauto.
Qed.

Instance succ_m_ext' : Proper (eq ==> XSet.Equal ==> eq ==> eq ==> impl) succ.

Proof.
intros x x' xx' s s' ss' a a' aa' b b' bb'. unfold succ.
rewrite xx', ss', aa', bb'. refl.
Qed.

Instance succ_m : Proper (eq ==> XSet.Equal ==> @same_relation X.t) succ.

Proof.
split; apply succ_m'; (hyp||symmetry;hyp).
Qed.

Instance succ_m_ext : Proper (eq ==> XSet.Equal ==> eq ==> eq ==> iff) succ.

Proof.
split; apply succ_m_ext'; (hyp||symmetry;hyp).
Qed.

Lemma succ_empty : forall x, succ x XSet.empty == @empty_rel X.t.

Proof.
intro x. rewrite rel_eq; intros a b. unfold succ, empty_rel. intuition.
In_elim.
Qed.

Lemma succ_add : forall x y s, succ x (XSet.add y s) == id x y U succ x s.

Proof.
intros x y s. apply rel_eq; intros a b.
unfold Relation_Operators.union, succ, id. rewrite add_iff. firstorder.
Qed.

Lemma rel_add : forall x g s, ~In x g -> rel (add x s g) == succ x s U g.

Proof.
intros x g s n. rewrite rel_eq; intros a b.
unfold Relation_Operators.union. split.
(* -> *)
intros [t [t1 t2]]. rewrite add_o in t1. destruct (eq_dec x a).
inversion t1. subst t. firstorder.
right. exists t. tauto.
(* <- *)
intros [ab|ab]. exists s. unfold succ in ab. intuition. rewrite add_o.
destruct (eq_dec x a). refl. absurd (eq x a). hyp. symmetry. hyp.
destruct ab as [t [t1 t2]]. exists t. intuition. rewrite add_o.
destruct (eq_dec x a). 2: hyp. absurd (In x g). hyp. rewrite e.
exists t. change (MapsTo a t g). rewrite find_mapsto_iff. hyp.
Qed.

(***********************************************************************)
(** product relation *)

Definition prod s t a b := XSet.In a s /\ XSet.In b t.

Lemma prod_m : Proper (XSet.Equal ==> XSet.Equal ==> same_relation X.t) prod.

Proof.
intros s s' ss' t t' tt'. rewrite rel_eq. intros a b. unfold prod.
rewrite ss', tt'. refl.
Qed.

Lemma prod_m_ext :
  Proper (XSet.Equal ==> XSet.Equal ==> eq ==> eq ==> iff) prod.

Proof.
intros s s' ss' t t' tt' a a' aa' b b' bb'. unfold prod.
rewrite ss', tt', aa', bb'. refl.
Qed.

(***********************************************************************)
(** equality on graphs: two graphs are equivalent if they define the
same relation *)

Definition geq g h := g == h.

Instance geq_Refl : Reflexive geq.

Proof. firstorder. Qed.

Instance geq_Sym : Symmetric geq.

Proof. firstorder. Qed.

Instance geq_Trans : Transitive geq.

Proof. firstorder. Qed.

Lemma meq_geq : meq << geq.

Proof.
intros g h gh. split; intros x y xy. rewrite <- gh. hyp. rewrite gh. hyp.
Qed.

Instance geq_meq : Proper (meq ==> meq ==> iff) geq.

Proof.
intros g g' gg' h h' hh'. apply meq_geq in gg'. apply meq_geq in hh'.
split; intro H. rewrite <- gg', <- hh'. hyp. rewrite gg', hh'. hyp.
Qed.

Lemma Equal_geq : Equal << geq.

Proof.
transitivity meq. apply Equal_Equiv. intuition. apply meq_geq.
Qed.

Instance geq_Equal : Proper (Equal ==> Equal ==> iff) geq.

Proof.
intros g g' gg' h h' hh'. apply Equal_geq in gg'. apply Equal_geq in hh'.
split; intro H. rewrite <- gg', <- hh'. hyp. rewrite gg', hh'. hyp.
Qed.

(***********************************************************************)
(** properties of rel *)

Instance rel_geq' : Proper (geq ==> @inclusion X.t) rel.

Proof.
intros g g' gg' x y [s [s1 s2]]. apply gg'. exists s. intuition.
Qed.

Instance rel_geq : Proper (geq ==> same_relation X.t) rel.

Proof.
split; apply rel_geq'; intuition.
Qed.

Instance rel_geq_ext' : Proper (geq ==> eq ==> eq ==> impl) rel.

Proof.
intros g g' gg' x x' xx' y y' yy' [s [s1 s2]]. apply gg'. exists s.
rewrite <- xx', <- yy'. intuition.
Qed.

Instance rel_geq_ext : Proper (geq ==> eq ==> eq ==> iff) rel.

Proof.
split; apply rel_geq_ext'; intuition.
Qed.

Instance rel_Equal_ext : Proper (Equal ==> eq ==> eq ==> iff) rel.

Proof.
eapply Proper3_m. apply Equal_geq. refl. refl. refl. apply rel_geq_ext.
Qed.

(***********************************************************************)
(** successors of a node *)

Definition succs x g :=
  match find x g with
    | Some s => s
    | None => XSet.empty
  end.

Lemma In_succs_rel : forall g x y, XSet.In y (succs x g) <-> rel g x y.

Proof.
intros. unfold succs, rel. destruct (find x g); firstorder.
inversion H. hyp. In_elim. discr.
Qed.

Lemma mem_succs_rel : forall g x y, XSet.mem y (succs x g) = true <-> rel g x y.

Proof.
intros. rewrite <- mem_iff. apply In_succs_rel.
Qed.

Lemma succs_empty : forall x, succs x (@empty XSet.t) = XSet.empty.

Proof. refl. Qed.

Lemma succs_add : forall x y s g,
  succs x (add y s g) = if eq_dec y x then s else succs x g.

Proof.
intros x y s g. unfold succs at 1. rewrite add_o. destruct (eq_dec y x); refl.
Qed.

Lemma succs_add_id : forall x s g, succs x (add x s g) = s.

Proof.
intros x s g. unfold succs. rewrite add_eq_o. refl. refl.
Qed.

Instance succs_geq : Proper (eq ==> geq ==> XSet.Equal) succs.

Proof.
intros x x' xx' g g' gg'. unfold succs. rewrite <- xx'. clear x' xx'.
case_eq (find x g); case_eq (find x g').
(* find x g = Some t0, find x g' = Some t1 *)
intro y. split; intro hy.
assert (xy : rel g x y). exists t0. intuition. rewrite gg' in xy.
destruct xy as [s [s1 s2]]. rewrite H0 in s1. inversion s1. subst t1. hyp.
assert (xy : rel g' x y). exists t1. intuition. rewrite <- gg' in xy.
destruct xy as [s [s1 s2]]. rewrite H in s1. inversion s1. subst t0. hyp.
(* find x g = Some t0, find x g' = None *)
case_eq (XSet.is_empty t0). rewrite is_empty_eq in H1. rewrite H1. refl.
destruct (find_Some_rel H H1) as [y hy]. rewrite gg' in hy.
destruct hy as [s [s1 s2]]. rewrite H0 in s1. discr.
(* find x g = None, find x g' = Some t0 *)
case_eq (XSet.is_empty t0). rewrite is_empty_eq in H1. rewrite H1. refl.
destruct (find_Some_rel H0 H1) as [y hy]. rewrite <- gg' in hy.
destruct hy as [s [s1 s2]]. rewrite H in s1. discr.
(* find x g = None, find x g' = None *)
refl.
Qed.

(***********************************************************************)
(** two graphs are equivalent iff they have the same successors *)

Lemma geq_succs : forall g g', geq g g' <-> forall x, succs x g [=] succs x g'.

Proof.
intros g g'. split.
intros gg' x. rewrite gg'. refl.
intro h. apply rel_eq. intros x y. repeat rewrite <- In_succs_rel.
rewrite (h x). refl.
Qed.

(***********************************************************************)
(** properties of geq wrt add *)

Lemma geq_add_remove : forall y s g g', ~In y g -> geq (add y s g) g' ->
  geq g (if XSet.is_empty s then g' else remove y g').

Proof.
intros y s g g' n e. case_eq (XSet.is_empty s).
(* s empty *)
rewrite geq_succs; intro z. rewrite <- e. rewrite succs_add.
destruct (eq_dec y z). 2: refl. rewrite <- e0. unfold succs.
rewrite not_find_in_iff in n. rewrite n. symmetry. apply is_empty_eq. hyp.
(* s not empty *)
rewrite geq_succs; intro z. unfold succs at 2. rewrite remove_o.
case_eq (eq_dec y z).
rewrite <- e0. unfold succs. rewrite not_find_in_iff in n. rewrite n. refl.
fold (succs z g'). transitivity (succs z (add y s g)).
rewrite succs_add. rewrite H0. refl. rewrite e. refl.
Qed.

Lemma geq_add : forall y s g g', ~In y g -> geq (add y s g) g' ->
  if XSet.is_empty s then geq g' g else Add y (succs y g') (remove y g') g'.

Proof.
intros y s g g' n e. case_eq (XSet.is_empty s).
(* s empty *)
rewrite geq_succs; intro z. rewrite <- e. rewrite succs_add.
destruct (eq_dec y z). 2: refl.
rewrite <- e0. unfold succs. rewrite not_find_in_iff in n. rewrite n.
apply is_empty_eq. hyp.
(* s not empty *)
unfold Add. intro z. rewrite add_o. case_eq (eq_dec y z).
(* y = z *)
unfold succs. rewrite e0. case_eq (find z g'). refl.
rewrite geq_succs in e. ded (e y). rewrite succs_add_id in H2.
rewrite e0 in H2. unfold succs in H2. rewrite H1 in H2.
rewrite <- is_empty_eq in H2. rewrite H in H2. discr.
(* y <> z *)
rewrite remove_o. rewrite H0. refl.
Qed.

(***********************************************************************)
(** predecessors of a node *)

Definition preds_aux x y sy s := if XSet.mem x sy then XSet.add y s else s.

Instance preds_aux_m :
  Proper (eq ==> eq ==> XSet.Equal ==> XSet.Equal ==> XSet.Equal) preds_aux.

Proof.
intros x x' xx' y y' yy' s s' ss' t t' tt'. unfold preds_aux. rewrite xx', ss'.
destruct (XSet.mem x' s'). rewrite yy', tt'. refl. hyp.
Qed.

Lemma preds_aux_transp : forall x, transpose_neqkey XSet.Equal (preds_aux x).

Proof.
unfold transpose_neqkey. intros x y z s t u n. unfold preds_aux.
destruct (XSet.mem x s); destruct (XSet.mem x t); try refl.
apply XSetProps.add_add.
Qed.

Definition preds x g := fold (preds_aux x) g XSet.empty.

Instance preds_Equal : Proper (eq ==> Equal ==> XSet.Equal) preds.

Proof.
intros x x' xx' g g' gg'. unfold preds.
apply fold_Equiv_ext with (eq0:= XSet.Equal).
intuition. intuition. apply preds_aux_m. refl. apply preds_aux_transp.
apply preds_aux_m. hyp. apply Equal_Equiv. intuition. hyp. refl.
Qed.

Lemma preds_empty : forall x, preds x (@empty XSet.t) [=] XSet.empty.

Proof. refl. Qed.

Lemma preds_add : forall x y s g, ~In y g -> preds x (add y s g)
  [=] if XSet.mem x s then XSet.add y (preds x g) else preds x g.

Proof.
intros x y s g nyg. unfold preds. rewrite fold_add. refl. intuition.
proper3 preds_aux_m. apply preds_aux_transp. hyp.
Qed.

Lemma preds_geq_empty : forall x g,
  geq g (@empty XSet.t) -> preds x g [=] XSet.empty.

Proof.
intros x g. pattern g; apply map_induction_bis; clear g.
(* Equal *)
intros m m' mm' h hm'. rewrite <- mm'. apply h. rewrite mm'. hyp.
(* empty *)
refl.
(* add *)
intros y s g n h e. rewrite preds_add. 2: hyp. case_eq (XSet.mem x s).
(* x in s *)
ded (geq_add n e). rewrite (mem_is_empty H) in H0. ded (H0 y).
rewrite empty_o, succs_empty, add_o in H1.
destruct (eq_dec y y). discr. absurd (eq y y). hyp. refl.
(* x not in s *)
apply h. ded (geq_add_remove n e). rewrite H0. destruct (XSet.is_empty s).
refl. rewrite remove_empty. refl.
Qed.

Instance preds_geq : Proper (eq ==> geq ==> XSet.Equal) preds.

Proof.
intros x x' xx' g; gen xx'; gen x'; gen x.
pattern g; apply map_induction_bis; clear g.
(* [=] *)
intros m m' mm' hm x x' xx' g m'g. apply Equal_geq in mm'.
transitivity (preds x m).
symmetry. apply hm. refl. hyp.
apply hm. hyp. transitivity m'; hyp.
(* empty *)
intros x x' xx' g hg. rewrite preds_empty. symmetry. apply preds_geq_empty.
symmetry. hyp.
(* add *)
intros y s g n h x x' xx' g' e. unfold preds. rewrite fold_add.
2: intuition. 2: proper3 preds_aux_m. 2: apply preds_aux_transp. 2: hyp.
fold (preds x g). fold (preds x' g'). ded (geq_add_remove n e).
gen H. case_eq (XSet.is_empty s); unfold preds_aux.
(* s empty *)
rewrite mem_3. apply h; hyp. rewrite <- XSetFacts.is_empty_iff in H. apply H.
(* s not empty *)
ded (geq_add n e). rewrite H in H1. unfold preds at 3. rewrite fold_Add.
6: apply H1. 2: intuition. 2: proper3 preds_aux_m. 2: apply preds_aux_transp.
Focus 2. rewrite remove_in_iff. intros [h1 h2]. absurd (eq y y). hyp. refl.
Focus 1. fold (preds x' (remove y g')). unfold preds_aux. rewrite <- xx'.
rewrite <- e at 1. rewrite succs_add_id. destruct (XSet.mem x s).
rewrite <- xx'. apply XSetFacts.add_m. refl. apply h. refl. hyp.
apply h. hyp. hyp.
Qed.

Lemma In_preds_rel : forall x y g, XSet.In x (preds y g) <-> rel g x y.

Proof.
intros x y g. pattern g; apply map_induction_bis; clear g.
(* Equal *)
intros m m' mm' h. rewrite <- mm'. hyp.
(* empty *)
rewrite preds_empty. split. intro h. In_elim.
intros [s [s1 s2]]. rewrite empty_o in s1. discr.
(* add *)
intros z s g n h. rewrite preds_add. 2: hyp. case_eq (XSet.mem y s).
(* y in s *)
rewrite add_iff. rewrite h. split.
(* -> *)
intros [h'|h']. exists s. rewrite add_eq_o. rewrite mem_iff. intuition. hyp.
destruct h' as [t [t1 t2]]. exists t. rewrite add_o. destruct (eq_dec z x).
rewrite not_find_in_iff, e in n. rewrite n in t1. discr. intuition.
(* <- *)
intros [t [t1 t2]]. rewrite add_o in t1. destruct (eq_dec z x). auto.
right. exists t. intuition.
(* y not in s *)
rewrite h. split.
(* -> *)
intros [t [t1 t2]]. exists t. rewrite add_o. destruct (eq_dec z x).
rewrite not_find_in_iff, e in n. rewrite n in t1. discr. intuition.
(* <- *)
intros [t [t1 t2]]. rewrite add_o in t1. destruct (eq_dec z x).
inversion t1. subst t. rewrite XSetFacts.mem_iff in t2. rewrite H in t2. discr.
exists t. intuition.
Qed.

(***********************************************************************)
(** add an edge into a graph *)

Definition add_edge x y g : graph := add x (XSet.add y (succs x g)) g.

Instance add_edge_geq : Proper (eq ==> eq ==> geq ==> geq) add_edge.

Proof.
intros x x' xx' y y' yy' g g' gg'. unfold add_edge.
rewrite geq_succs. intro z. repeat rewrite succs_add.
destruct (eq_dec x z); destruct (eq_dec x' z).
rewrite xx', yy', gg'. refl.
rewrite xx' in e. contradiction. rewrite xx' in n. contradiction.
rewrite gg'. refl.
Qed.

Lemma add_edge_rel : forall x y g, add_edge x y g == g U id x y.

Proof.
intros. rewrite rel_eq; intros a b.
unfold add_edge, Relation_Operators.union, id. intuition.
destruct H as [sa [a1 a2]]. rewrite add_o in a1. destruct (eq_dec x a).
inversion a1. subst sa. rewrite add_iff in a2. rewrite In_succs_rel in a2.
rewrite e in a2. intuition.
left. exists sa. intuition.
destruct H0 as [sa [a1 a2]]. unfold rel. rewrite add_o. destruct (eq_dec x a).
exists (XSet.add y (succs x g)). intuition. rewrite add_iff. right.
rewrite e. rewrite In_succs_rel. exists sa. auto.
exists sa. auto.
unfold rel. rewrite add_o. destruct (eq_dec x a).
exists (XSet.add y (succs x g)). intuition. rewrite add_iff. auto.
absurd (eq x a). hyp. symmetry. hyp.
Qed.

Lemma add_edge_transp_geq : forall x, transpose geq (add_edge x).

Proof.
intros x y z g. unfold geq. repeat rewrite add_edge_rel. firstorder.
Qed.

(***********************************************************************)
(** add all the edges (x,y) with y in some set s *)

Lemma fold_add_edge_rel : forall x s g0,
  rel (XSet.fold (add_edge x) s g0) == succ x s U g0.

Proof.
intros x s g0. pattern (XSet.fold (add_edge x) s g0).
apply XSetProps.fold_rec_weak; clear s.
(* [=] *)
intros s t g st i. rewrite <- st. hyp.
(* empty *)
rewrite succ_empty. rewrite union_empty_l. refl.
(* add *)
intros z g s nzs e. rewrite add_edge_rel. rewrite e.
rewrite RelUtil.union_assoc. rewrite RelUtil.union_commut with (R:=rel g0).
rewrite <- RelUtil.union_assoc. apply RelUtil.union_m. 2: refl.
rewrite rel_eq; intros a b. unfold succ, Relation_Operators.union, id.
rewrite add_iff. firstorder.
Qed.

(*COQ: can we remove this lemma? *)
Lemma fold_add_edge_rel_ext : forall x s g0 a b,
  rel (XSet.fold (add_edge x) s g0) a b <-> succ x s a b \/ rel g0 a b.

Proof.
split; intro h. apply fold_add_edge_rel in h. hyp.
apply fold_add_edge_rel. hyp.
Qed.

End Make.