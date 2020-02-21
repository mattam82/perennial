From Perennial.program_proof Require Import proof_prelude.
From Perennial.Helpers Require Import GenHeap.
From Goose.github_com.mit_pdos.goose_nfsd Require Import lockmap.
From Perennial.goose_lang.lib Require Import wp_store.

Hint Rewrite app_length @drop_length @take_length @fmap_length
     @replicate_length : len.
Hint Rewrite @vec_to_list_length : len.
Hint Rewrite @insert_length : len.
Hint Rewrite u64_le_length : len.

Ltac word := try lazymatch goal with
                 | |- envs_entails _ _ => iPureIntro
                 end; Integers.word.

Ltac len := autorewrite with len; try word.

Section heap.
Context `{!heapG Σ}.
Context `{!lockG Σ}.
Context `{!gen_heapPreG u64 bool Σ}.

Implicit Types s : Slice.t.
Implicit Types (stk:stuckness) (E: coPset).

Definition lockN : namespace := nroot .@ "lockShard".
Definition lockshardN : namespace := nroot .@ "lockShardMem".

Definition locked (hm : gen_heapG u64 bool Σ) (addr : u64) : iProp Σ :=
  ( mapsto (hG := hm) addr 1 true )%I.

Definition lockShard_addr gh (shardlock : loc) (addr : u64) (gheld : bool) (ptrVal : val) (covered : gmap u64 unit) (P : u64 -> iProp Σ) :=
  ( ∃ (lockStatePtr : loc) owner (cond : loc) (nwaiters : u64),
      ⌜ ptrVal = #lockStatePtr ⌝ ∗
      lockStatePtr ↦[structTy lockState.S] (owner, (#gheld, (#cond, (#nwaiters, #())))) ∗
      lock.is_cond cond #shardlock ∗
      ⌜ covered !! addr ≠ None ⌝ ∗
      ( ⌜ gheld = true ⌝ ∨
        ( ⌜ gheld = false ⌝ ∗ mapsto (hG := gh) addr 1 false ∗ P addr ) )
  )%I.

Definition is_lockShard_inner (mptr : loc) (shardlock : loc) (ghostHeap : gen_heapG u64 bool Σ) (covered : gmap u64 unit) (P : u64 -> iProp Σ) : iProp Σ :=
  ( ∃ m def ghostMap,
      is_map mptr (m, def) ∗
      gen_heap_ctx (hG := ghostHeap) ghostMap ∗
      ( [∗ map] addr ↦ gheld; lockStatePtrV ∈ ghostMap; m,
          lockShard_addr ghostHeap shardlock addr gheld lockStatePtrV covered P ) ∗
      ( [∗ map] addr ↦ _ ∈ covered,
          ⌜m !! addr = None⌝ → P addr )
  )%I.

Definition is_lockShard (ls : loc) (ghostHeap : gen_heapG u64 bool Σ) (covered : gmap u64 unit) (P : u64 -> iProp Σ) :=
  ( ∃ (shardlock mptr : loc) γl,
      inv lockshardN (ls ↦[structTy lockShard.S] (#shardlock, (#mptr, #()))) ∗
      is_lock lockN γl #shardlock (is_lockShard_inner mptr shardlock ghostHeap covered P)
  )%I.

Global Instance is_lockShard_persistent ls gh (P : u64 -> iProp Σ) c : Persistent (is_lockShard ls gh c P).
Proof. apply _. Qed.

Opaque zero_val.

Theorem wp_mkLockShard covered (P : u64 -> iProp Σ) :
  {{{ [∗ map] a ↦ _ ∈ covered, P a }}}
    mkLockShard #()
  {{{ ls gh, RET #ls; is_lockShard ls gh covered P }}}.
Proof using gen_heapPreG0 heapG0 lockG0 Σ.
  iIntros (Φ) "Hinit HΦ".
  rewrite /mkLockShard.
  wp_call.

  wp_apply wp_NewMap.
  iIntros (mref) "Hmap".
  wp_pures.

  wp_bind (newlock _).
  iApply lock.new_free_lock; auto.

  iNext.
  iIntros (shardlock) "Hfreelock".

  wp_pures.
  iDestruct (lock.is_free_lock_ty with "Hfreelock") as "%".
  wp_apply (typed_mem.wp_AllocAt (structTy lockShard.S)); first by eauto.
  iIntros (ls) "Hls".

  iMod (gen_heap_init (∅: gmap u64 bool)) as (hG) "Hheapctx".
  rewrite -wp_fupd.

  wp_pures.

  iAssert (is_lockShard_inner mref shardlock hG covered P) with "[Hinit Hmap Hheapctx]" as "Hinner".
  {
    iExists _, _, _.
    iFrame.

    iSplitR; eauto.

    iApply big_sepM_mono; last iFrame.
    iIntros; iFrame.
  }

  iMod (alloc_lock with "Hfreelock Hinner") as (γ) "Hlock".
  iMod (inv_alloc lockshardN _ (ls ↦[struct.t lockShard.S] (#shardlock, (#mref, #()))) with "Hls") as "Hls".
  iModIntro.

  iApply "HΦ".
  iExists _, _, _.
  iFrame.
Qed.

Transparent loadField.
Theorem wp_load_lockShard_mu (ls shardlock mptr : loc) :
  {{{ inv lockshardN (ls ↦[struct.t lockShard.S] (#shardlock, (#mptr, #()))) }}}
    struct.loadF lockShard.S "mu" #ls
  {{{ RET #shardlock; True }}}.
Proof.
  iIntros (Φ) "#Hinv HΦ".
  rewrite /loadField /=.
  wp_pures.

  iInv lockshardN as "Hls".
  iDestruct "Hls" as "[([Hl _] & [Hm _]) Ht]".
  rewrite /=.
  wp_load.
  iModIntro.
  iSplitL "Hl Hm Ht".
  {
    iModIntro.
    iFrame.
    rewrite /=.
    iFrame.
  }
  iApply "HΦ".
  auto.
Qed.

Instance loadField_atomic d f z bt (l:loc) : field_offset d f = Some (z, baseT bt) -> Atomic s (struct.loadF d f #l).
Proof.
  rewrite /loadField.
  intros s ->.
  simpl.
  destruct bt; simpl.
Abort.

Theorem wp_load_lockShard_state (ls shardlock mptr : loc) :
  {{{ inv lockshardN (ls ↦[struct.t lockShard.S] (#shardlock, (#mptr, #()))) }}}
    struct.loadF lockShard.S "state" #ls
  {{{ RET #mptr; True }}}.
Proof.
  iIntros (Φ) "#Hinv HΦ".
  rewrite /loadField /=.
  wp_pures.

  iInv lockshardN as "Hls".
  iDestruct "Hls" as "[([Hl _] & [Hm _]) Ht]".
  rewrite Z.mul_1_r Z.add_0_r /=.
  iDestruct "Hm" as "[Hm _]".
  wp_apply (wp_load with "Hm"); iIntros "Hm".
  iSplitL "Hl Hm Ht".
  {
    iModIntro.
    iFrame.
    rewrite /=.
    done.
  }
  iApply "HΦ".
  auto.
Qed.

Transparent storeField.
Opaque String.eqb.
Theorem wp_store_lockState (lsp : loc) fn v fv :
  val_ty fv (field_ty lockState.S fn) ->
  {{{ lsp ↦[struct.t lockState.S] v }}}
    struct.storeF lockState.S fn #lsp fv
  {{{ RET #(); lsp ↦[struct.t lockState.S] (setField_f lockState.S fn fv v) }}}.
Proof.
  iIntros (Hfvt Φ) "Hl HΦ".
  wp_apply (wp_storeField_struct with "Hl"); first by auto.
  iFrame.
Qed.

Theorem wp_load_lockState (lsp : loc) v fn :
  {{{ lsp ↦[struct.t lockState.S] v }}}
    struct.loadF lockState.S fn #lsp
  {{{ RET getField_f lockState.S fn v; lsp ↦[struct.t lockState.S] v }}}.
Proof.
  iIntros (Φ) "Hl HΦ".
  wp_apply (wp_loadField_struct with "Hl").
  iFrame.
Qed.
Transparent String.eqb.
Opaque loadField.

Theorem wp_lockShard__acquire ls gh covered (addr : u64) (id : u64) (P : u64 -> iProp Σ) :
  {{{ is_lockShard ls gh covered P ∗
      ⌜covered !! addr ≠ None⌝ }}}
    lockShard__acquire #ls #addr #id
  {{{ RET #(); P addr ∗ locked gh addr }}}.
Proof.
  iIntros (Φ) "[Hls %] HΦ".
  iDestruct "Hls" as (shardlock mptr γl) "(#Hls&#Hlock)".

  wp_call.
  wp_apply (wp_load_lockShard_mu with "Hls").
  wp_apply (acquire_spec with "Hlock").
  iIntros "[Hlocked Hinner]".

  wp_pures.
  wp_apply (wp_forBreak
    (is_lockShard_inner mptr shardlock gh covered P ∗ spin_lock.locked γl)
    (is_lockShard_inner mptr shardlock gh covered P ∗ spin_lock.locked γl ∗ P addr ∗ locked gh addr)
    with "[] [$Hlocked $Hinner]").

  {
    iIntros (Φloop) "!> [Hinner Hlocked] HΦloop".
    iDestruct "Hinner" as (m def gm) "(Hmptr & Hghctx & Haddrs & Hcovered)".
    wp_pures.
    wp_apply wp_ref_of_zero.
    iIntros (state) "Hstate".
    wp_apply (wp_load_lockShard_state with "Hls").
    wp_apply (wp_MapGet with "[$Hmptr]"); auto.
    iIntros (v ok) "[% Hmptr]".

    wp_pures.
    iDestruct "Hstate" as "[[Hstate _] _]". rewrite /=.
    rewrite loc_add_0.

    destruct ok; wp_if.
    - wp_pures.
      wp_apply (wp_store with "Hstate"); iIntros "Hstate".

      wp_apply wp_ref_of_zero.
      iIntros (acquired) "Hacquired".

      wp_load.
      apply map_get_true in H0.
      iDestruct (big_sepM2_lookup_2_some with "Haddrs") as (gheld) "%"; eauto.
      iDestruct (big_sepM2_insert_acc with "Haddrs") as "[Haddr Haddrs]"; eauto.
      iDestruct "Haddr" as (lockStatePtr owner cond nwaiters) "(% & HlockStatePtr & Hcond & % & Hwaiters)".
      subst.
      wp_apply (wp_load_lockState with "HlockStatePtr").
      iIntros "HlockStatePtr".
      rewrite /getField_f /=.
      destruct gheld; wp_pures.
      + wp_load.
        wp_apply (wp_load_lockState with "HlockStatePtr").
        iIntros "HlockStatePtr".
        wp_load.
        wp_apply (wp_store_lockState with "HlockStatePtr"); [val_ty|].
        iIntros "HlockStatePtr".
        wp_pures.

        iSpecialize ("Haddrs" $! true #lockStatePtr).
        rewrite insert_id; eauto.
        rewrite insert_id; eauto.

        iDestruct (lock.is_cond_dup with "Hcond") as "[Hcond1 Hcond2]".

        wp_load.
        wp_apply (wp_load_lockState with "HlockStatePtr").
        iIntros "HlockStatePtr".
        wp_apply (lock.wp_condWait with "[$Hlock $Hcond1 $Hlocked Hmptr Hghctx Hcovered Haddrs Hcond2 HlockStatePtr]").
        {
          iExists _, _, _.
          iFrame.
          iApply "Haddrs".
          iExists _, _, _, _.
          iFrame.
          iSplitL; try done.
          iSplitL; try done.
          iLeft; done.
        }

        iIntros "(Hcond & Hlocked & Hinner)".
        wp_apply (wp_load_lockShard_state with "Hls").

        iDestruct "Hinner" as (m2 def2 gm2) "(Hmptr & Hghctx & Haddrs & Hcovered)".
        wp_apply (wp_MapGet with "[$Hmptr]"). iIntros (v ok) "[% Hmptr]".
        destruct ok.
        * wp_pures.

          apply map_get_true in H2.
          iDestruct (big_sepM2_lookup_2_some with "Haddrs") as (gheld) "%"; eauto.
          iDestruct (big_sepM2_lookup_acc with "Haddrs") as "[Haddr Haddrs]"; eauto.
          iDestruct "Haddr" as (lockStatePtr2 owner2 cond2 nwaiters2) "(% & HlockStatePtr & Hcond2 & % & Hwaiters2)".

          subst.
          wp_apply (wp_load_lockState with "HlockStatePtr"). iIntros "HlockStatePtr".
          wp_apply (wp_store_lockState with "HlockStatePtr"); [val_ty|]. iIntros "HlockStatePtr".

          iDestruct "Hacquired" as "[[Hacquired _] _]"; rewrite loc_add_0.
          wp_load.

          wp_pures.
          iApply "HΦloop".
          iLeft. iFrame. iSplitL; try done.
          iExists _, _, _. iFrame.
          iApply "Haddrs".
          iExists _, _, _, _. iFrame. done.

        * iDestruct "Hacquired" as "[[Hacquired _] _]"; rewrite loc_add_0.
          wp_load.
          wp_pures.
          iApply "HΦloop".
          iLeft. iFrame. iSplitL; try done.
          iExists _, _, _. iFrame.

      + wp_load.
        wp_apply (wp_store_lockState with "HlockStatePtr"); [val_ty|]. iIntros "HlockStatePtr".
        wp_load.
        wp_apply (wp_store_lockState with "HlockStatePtr"); [val_ty|]. iIntros "HlockStatePtr".

        iDestruct "Hwaiters" as "[% | [_ [Haddr Hp]]]"; try congruence.
        iMod (gen_heap_update _ _ _ true with "Hghctx Haddr") as "[Hghctx Haddr]".

        iDestruct "Hacquired" as "[[Hacquired _] _]"; rewrite loc_add_0.
        wp_pures.
        wp_store.
        wp_load.

        wp_pures.
        iApply "HΦloop".
        iRight. iFrame. iSplitL; try done.
        iExists _, _, _. iFrame.

        erewrite <- (insert_id m) at 1; eauto.
        iApply "Haddrs".
        iExists _, _, _, _. iFrame.
        iSplitL; try done.
        iSplitL; try done.
        iLeft; done.

    - wp_pures.
      wp_apply (wp_load_lockShard_mu with "Hls").
      wp_apply lock.wp_newCond; [done|].
      iIntros (c) "Hcond".
      wp_apply (typed_mem.wp_AllocAt (struct.t lockState.S)); [val_ty|].
      iIntros (lst) "Hlst".
      wp_store.
      wp_load.
      wp_apply (wp_load_lockShard_state with "Hls").
      wp_apply (wp_MapInsert with "[$Hmptr]").
      iIntros "Hmptr".

      wp_apply wp_ref_of_zero.
      iIntros (acquired) "Hacquired".

      wp_pures.
      wp_load.
      wp_apply (wp_load_lockState with "Hlst").
      iIntros "Hlst".
      rewrite /getField_f /=. wp_pures.
      wp_bind (struct.storeF _ _ _ _).

      wp_load.
      wp_apply (wp_store_lockState with "Hlst"); [val_ty|]. iIntros "Hlst".
      wp_load.
      wp_apply (wp_store_lockState with "Hlst"); [val_ty|]. iIntros "Hlst".

      apply map_get_false in H0.
      iDestruct (big_sepM2_lookup_2_none with "Haddrs") as %Hgaddr; eauto.

      iMod (gen_heap_alloc _ addr true with "Hghctx") as "(Hghctx & Haddrlocked)"; [auto|].  

      iDestruct "Hacquired" as "[[Hacquired _] _]"; rewrite loc_add_0.
      wp_store.
      wp_load.

      wp_pures.
      iApply "HΦloop".
      iRight. iFrame. iSplitL; try done.

      destruct (covered !! addr) eqn:Hcoveredaddr; try congruence.
      iDestruct (big_sepM_delete with "Hcovered") as "[Hp Hcovered]"; eauto.
      iSplitR "Hp".
      2: { iApply "Hp"; done. }

      iExists _, _, _. iFrame.

      iSplitR "Hcovered".
      {
        iApply (big_sepM2_insert); [auto | auto | ].
        iFrame.
        iExists _, _, _, _.
        iFrame.
        iSplitL; try done.
        iSplitL; [ iPureIntro; congruence | ].
        iLeft; done.
      }

      replace (covered) with (<[addr := tt]> (delete addr covered)) at 3.
      2: {
        rewrite insert_delete.
        rewrite insert_id; destruct u; eauto.
      }

      iApply (big_sepM_insert).
      { rewrite lookup_delete; auto. }

      iSplitR. { rewrite lookup_insert; iIntros (Hx). congruence. }

      iApply big_sepM_mono; iFrame.
      iIntros (x ? Hx) "H".
      destruct (decide (addr = x)); subst.
      { rewrite lookup_delete in Hx. congruence. }

      iIntros "%".
      rewrite lookup_insert_ne in a0; eauto.
      iApply "H". done.
  }

  iIntros "(Hinner & Hlocked & Hp & Haddrlocked)".
  wp_apply (wp_load_lockShard_mu with "Hls").
  wp_apply (release_spec with "[Hlocked Hinner]").
  {
    iSplitR. { iApply "Hlock". }
    iFrame.
  }

  iApply "HΦ".
  iFrame.
Qed.

Theorem wp_lockShard__release ls (addr : u64) (P : u64 -> iProp Σ) covered gh :
  {{{ is_lockShard ls gh covered P ∗ P addr ∗ locked gh addr }}}
    lockShard__release #ls #addr
  {{{ RET #(); True }}}.
Proof.
  iIntros (Φ) "(Hls & Hp & Haddrlocked) HΦ".
  iDestruct "Hls" as (shardlock mptr γl) "(#Hls&#Hlock)".
  wp_call.
  wp_apply (wp_load_lockShard_mu with "Hls").
  wp_apply (acquire_spec with "Hlock").
  iIntros "[Hlocked Hinner]".
  iDestruct "Hinner" as (m def gm) "(Hmptr & Hghctx & Haddrs & Hcovered)".

  wp_apply (wp_load_lockShard_state with "Hls").
  wp_apply (wp_MapGet with "Hmptr").
  iIntros (v ok) "[% Hmptr]".

  wp_pures.

  rewrite /locked.
  iDestruct (gen_heap_valid with "Hghctx Haddrlocked") as %Hsome.
  iDestruct (big_sepM2_lookup_1_some with "Haddrs") as %Hsome2; eauto.
  destruct Hsome2.

  iDestruct (big_sepM2_delete with "Haddrs") as "[Haddr Haddrs]"; eauto.

  iDestruct "Haddr" as (lockStatePtr owner cond waiters) "[-> (Hlockstateptr & Hcond & [% Hxx])]".

  rewrite /map_get H0 /= in H.
  inversion H; clear H; subst.

  wp_apply (wp_store_lockState with "Hlockstateptr"); [val_ty|].
  iIntros "Hlockstateptr".

  wp_apply (wp_load_lockState with "Hlockstateptr").
  iIntros "Hlockstateptr".

  wp_pures.
  destruct (bool_decide (int.val 0 < int.val waiters)).

  {
    wp_pures.
    wp_apply (wp_load_lockState with "Hlockstateptr").
    iIntros "Hlockstateptr".

    wp_apply (lock.wp_condSignal with "[$Hcond]").

    iMod (gen_heap_update _ _ _ false with "Hghctx Haddrlocked") as "[Hghctx Haddrlocked]".

    iIntros "Hcond".
    wp_apply (wp_load_lockShard_mu with "Hls").
    wp_apply (release_spec with "[Hlock Hlocked Hp Haddrlocked Hghctx Hcovered Hmptr Haddrs Hlockstateptr Hcond]").
    {
      iFrame.
      iSplitR.
      { iApply "Hlock". }
      iExists m, _, _.
      iFrame.

      iDestruct (big_sepM2_insert_2 _ _ _ addr false #lockStatePtr
        with "[Hlockstateptr Hp Hcond Haddrlocked] Haddrs") as "Haddrs".
      {
        rewrite /setField_f /=.
        iExists _, _, _, _.
        iFrame.
        iSplitR; auto.
        iSplitR; auto.
        iRight.
        iFrame. done.
      }

      rewrite insert_delete.
      rewrite insert_delete.
      rewrite (insert_id m); eauto.
    }

    iApply "HΦ".
    auto.
  }

  {
    wp_pures.
    wp_apply (wp_load_lockShard_state with "Hls").
    wp_apply (wp_MapDelete with "[$Hmptr]").
    iIntros "Hmptr".

    iMod (gen_heap_delete with "[$Haddrlocked $Hghctx]") as "Hghctx".

    wp_apply (wp_load_lockShard_mu with "Hls").
    wp_apply (release_spec with "[Hlock Hlocked Hp Hghctx Hcovered Hmptr Haddrs Hlockstateptr Hcond]").
    {
      iFrame.
      iSplitR.
      { iApply "Hlock". }
      iExists _, _, (delete addr gm).
      iFrame.

      destruct (covered !! addr) eqn:Hca; try congruence.
      iDestruct (big_sepM_delete with "Hcovered") as "[Hcaddr Hcovered]"; eauto.
      replace (covered) with (<[addr := tt]> (delete addr covered)) at 3.
      2: {
        rewrite insert_delete.
        rewrite insert_id; destruct u; eauto.
      }

      iApply (big_sepM_insert).
      { rewrite lookup_delete; auto. }

      iSplitL "Hp". { iFrame. done. }

      iApply big_sepM_mono; iFrame.
      iIntros (x ? Hx) "H".
      destruct (decide (addr = x)); subst.
      { rewrite lookup_delete in Hx. congruence. }

      iIntros "%".
      rewrite lookup_delete_ne in a0; eauto.
      iApply "H". done.
    }

    iApply "HΦ".
    auto.
  }
Qed.

End heap.
