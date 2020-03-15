From Perennial.goose_lang.examples Require Import append_log.
From Perennial.goose_lang.lib Require Import encoding crash_lock.
From Perennial.program_proof Require Import proof_prelude.
From Perennial.program_proof Require Import disk_lib.
From Perennial.program_proof Require Import marshal_proof.
From Perennial.program_proof Require Import append_log_proof.
From Perennial.goose_lang.ffi Require Import append_log_ffi.
From Perennial.program_logic Require Import ghost_var.

Canonical Structure log_stateO := leibnizO log_state.

Section hocap.
Context `{!heapG Σ}.
Context `{!crashG Σ}.
Context `{!lockG Σ, stagedG Σ}.
Context `{Hin: inG Σ (authR (optionUR (exclR log_stateO)))}.

Implicit Types v : val.
Implicit Types z : Z.
Implicit Types (stk:stuckness) (E: coPset).

Context (Nlog: namespace).

Context (P: log_state -> iProp Σ).
Context (POpened: iProp Σ).
Context (PStartedOpening: iProp Σ).
Context (PStartedIniting: iProp Σ).
Context (PStartedOpening_Timeless: Timeless PStartedOpening).
Context (PStartedIniting_Timeless: Timeless PStartedIniting).
Context (SIZE: nat).
Context (SIZE_nonzero: 0 < SIZE).
(*
Context (Pinit_token: iProp Σ).
Context (Popen_token: iProp Σ).
Context (Pinit_non_open: ∀ l bs, P (Opened bs l) ∗ Pinit_token ={⊤}=∗ False).
Context (Pinit_non_closed: ∀ bs, P (Closed bs) ∗ Pinit_token ={⊤}=∗ False).
Context (Popen_non_uninit: P (UnInit) ∗ Popen_token ={⊤}=∗ False).
*)

Definition N1 := Nlog.@"lock".
Definition N2 := Nlog.@"crash".
Definition N := Nlog.@"inv".

Definition log_init : iProp Σ :=
  (P UnInit ∗ uninit_log SIZE) ∨ (∃ vs, P (Closed vs) ∗ crashed_log vs).

Definition log_state_to_crash (s: log_state) :=
  match s with
  | UnInit => uninit_log SIZE
  | Initing => uninit_log SIZE
  | Closed vs => crashed_log vs
  | Opening vs => (crashed_log vs)
  | Opened vs l => (crashed_log vs)
  end%I.

Definition log_crash_cond' s : iProp Σ :=
  log_state_to_crash s ∗ P s.

Definition log_crash_cond : iProp Σ :=
  ∃ (s: log_state), log_state_to_crash s ∗ P s.

Definition log_state_to_inv (s: log_state) k γ2 :=
  match s with
  | UnInit => na_crash_inv_full N2 k (log_crash_cond' s) (log_crash_cond) ∗ own γ2 (◯ (Excl' s))
  | Initing => PStartedIniting
  | Closed vs => na_crash_inv_full N2 k (log_crash_cond' s) (log_crash_cond) ∗ own γ2 (◯ (Excl' s))
  | Opening vs => PStartedOpening
  | Opened vs l => POpened
  end%I.

Definition log_inv_inner k γ2 : iProp Σ :=
  (∃ s, log_state_to_inv s k γ2 ∗ own γ2 (● (Excl' s)))%I.

Definition log_inv k :=
  (∃ γ2, inv N (log_inv_inner (LVL k) γ2))%I.

Lemma append_log_na_crash_inv_obligation e (Φ: val → iProp Σ) Φc E k k':
  (k' < k)%nat →
  log_init -∗
  (log_inv k' -∗ (WPC e @ NotStuck; LVL k; ⊤; E {{ Φ }} {{ Φc }})) -∗
  WPC e @ NotStuck; (LVL (S k)); ⊤; E {{ Φ }} {{ Φc ∗ log_crash_cond }}%I.
Proof.
  iIntros (?) "Hinit Hwp".
  iDestruct "Hinit" as "[(HP&Hinit)|Hinit]".
  - iMod (na_crash_inv_alloc N2 (LVL k') ⊤ (log_crash_cond) (log_crash_cond' (UnInit))  with "[HP Hinit]") as
      "(Hfull&Hpending)".
    { rewrite /log_init/log_crash_cond/log_crash_cond'.
      iSplitL "HP Hinit".
      { iNext. iFrame => //=. }
      iAlways. iIntros "H". iExists _; eauto.
    }
    iApply (wpc_na_crash_inv_init _ k k' N2 E with "[-]"); try assumption.
    iFrame.
    iMod (ghost_var_alloc (UnInit : log_stateO)) as (γ2) "(Hauth&Hfrag)".
    iMod (inv_alloc N _ (log_inv_inner _ γ2) with "[Hfull Hauth Hfrag]") as "#?".
    { iIntros "!>". rewrite /log_inv_inner. iExists _; repeat iFrame. }
    iApply ("Hwp" with "[]").
    { iExists _. eauto. }
  - iDestruct "Hinit" as (vs) "(HP&Hinit)".
    iMod (na_crash_inv_alloc N2 (LVL k') ⊤ (log_crash_cond) (log_crash_cond' (Closed vs))  with "[HP Hinit]") as
      "(Hfull&Hpending)".
    { rewrite /log_init/log_crash_cond/log_crash_cond'.
      iSplitL "HP Hinit".
      { iNext. iFrame => //=. }
      iAlways. iIntros "H". iExists _; eauto.
    }
    iApply (wpc_na_crash_inv_init _ k k' N2 E with "[-]"); try assumption.
    iFrame.
    iMod (ghost_var_alloc (Closed vs : log_stateO)) as (γ2) "(Hauth&Hfrag)".
    iMod (inv_alloc N _ (log_inv_inner _ γ2) with "[Hfull Hauth Hfrag]") as "#?".
    { iIntros "!>". rewrite /log_inv_inner. iExists _; repeat iFrame. }
    iApply ("Hwp" with "[]").
    { iExists _. eauto. }
Qed.

Definition is_log (k: nat) (l: loc) : iProp Σ :=
  ∃ lk,
  log_inv k ∗
  inv Nlog (∃ q, l ↦[Log.S :: "m"]{q} lk) ∗
  (∃ γlk, is_crash_lock N1 N2 (LVL k) γlk lk
                                (∃ bs, ptsto_log l bs ∗ P (Opened bs l))
                                log_crash_cond).

Instance is_log_persistent: Persistent (is_log k l).
Proof. apply _. Qed.

(* XXX: For these crash hocap specs, P (Closed bs) might be slightly
   confusing...  It is not yet "crashed", merely halted? *)

Theorem wpc_Log__Reset k k' E2 l Q Qc:
  (S (S k) < k')%nat →
  (Q -∗ Qc) →
  {{{ is_log k' l ∗
     ((∀ bs, P (Opened bs l) ={⊤ ∖↑ N2}=∗ P (Opened [] l) ∗ Q) ∧
             Qc)
  }}}
    Log__Reset #l @ NotStuck; (LVL (S (S (S k)))); ⊤; E2
  {{{ RET #() ; Q }}}
  {{{ Qc }}}.
Proof.
  clear PStartedOpening_Timeless PStartedIniting_Timeless SIZE_nonzero.
  iIntros (? Hwand Φ Φc) "(His_log&Hvs) HΦ".
  iDestruct "His_log" as (?) "H".
  iDestruct "H" as "(#Hlog_inv&Hm&His_lock)".
  iMod (inv_readonly_acc _ with "Hm") as (q) "Hm"; first by set_solver+.
  iDestruct "His_lock" as (γlk) "His_lock".
  rewrite /Log__Reset.
  wpc_pures; auto.
  { iDestruct "Hvs" as "(_&$)". }

  wpc_bind (struct.loadF _ _ _).
  wpc_frame "HΦ Hvs".
  { iIntros "((H&_)&(_&Hvs))". by iApply "H". }
  wp_loadField.
  iIntros "(HΦ&Hvs)".

  wpc_bind (lock.acquire _).
  wpc_frame "HΦ Hvs".
  { iIntros "((H&_)&(_&Hvs))". by iApply "H". }
  wp_apply (crash_lock.acquire_spec with "His_lock"); first by set_solver+.
  iIntros "H". iDestruct "H" as (Γ) "Hcrash_locked".
  iIntros "(HΦ&Hvs)".

  wpc_pures; auto.
  { iDestruct "Hvs" as "(_&$)". }
  wpc_bind (Log__reset _).
  replace E2 with (∅ ∪ E2) by set_solver.
  iApply (use_crash_locked with "[$]"); eauto.
  iSplit.
  { iDestruct "Hvs" as "(_&H)". iDestruct "HΦ" as "(HΦ&_)".
    by iApply "HΦ". }

  iIntros "H". iDestruct "H" as (bs) "(Hpts&HP)".
  iApply wpc_fupd.
  iApply wpc_fupd_crash_shift_empty'.
  wpc_apply (wpc_Log__reset with "[$] [-]").
  iSplit.
  { iIntros "H".
    iDestruct "H" as "[H|H]".
    * iDestruct "Hvs" as "(_&Hvs)".
      iModIntro.
      iSplitL "HΦ Hvs".
      ** iDestruct "HΦ" as "(H&_)". by iApply "H".
      ** iExists _. do 2 iFrame.
    * iDestruct "Hvs" as "(Hvs&_)".
      iDestruct ("Hvs" $! bs) as "Hvs".
      iMod ("Hvs" with "[$]") as "(Hclo&HQc)".
      iModIntro.
      iSplitL "HΦ HQc".
      ** iDestruct "HΦ" as "(H&_)". iApply "H". by iApply Hwand.
      ** iExists _. do 2 iFrame.
  }
  iNext. iIntros "Hpts".
  (* Linearization point *)
  iDestruct "Hvs" as "(Hvs&_)".
  iMod ("Hvs" with "[$]") as "(HP&HQ)".
  iSplitR "Hpts HP"; last first.
  { iExists _; iFrame. eauto. }
  iModIntro. iIntros.
  iSplit; last first.
  { iApply "HΦ"; by iApply Hwand. }
  wpc_pures.
  { by iApply Hwand. }

  wpc_frame "HQ HΦ".
  { iIntros "(?&H)"; iApply "H". by iApply Hwand. }

  wp_bind (struct.loadF _ _ _).
  wp_loadField.
  wp_apply (crash_lock.release_spec with "[$]"); eauto.
  iIntros "(HQ&HΦ)".
  by iApply "HΦ".
Qed.

Lemma ptsto_log_crashed lptr vs:
  ptsto_log lptr vs -∗ crashed_log vs.
Proof.
  rewrite /ptsto_log. iIntros "H". iDestruct "H" as (??) "(?&His_log')".
  rewrite /crashed_log. iExists _, _. iFrame.
Qed.

Theorem wpc_Open k k' E2 Qc Q:
  (S k < k')%nat →
  (∀ l, Q l -∗ Qc) →
  {{{ log_inv k'
      ∗ ((P (UnInit) ={⊤ ∖ ↑N ∖ ↑N2}=∗ False)
        ∧ (PStartedIniting ∨ PStartedOpening ∨ POpened ={⊤ ∖ ↑N}=∗ False)
        ∧ (∀ vs, P (Closed vs) ={⊤ ∖ ↑N ∖ ↑N2}=∗
                 PStartedOpening ∗ P (Opening vs)
                 ∗ (Qc ∧ ∀ l, P (Opening vs) -∗ PStartedOpening ={⊤ ∖ ↑N2 ∖ ↑N}=∗
                              Q l ∗ P (Opened vs l) ∗ POpened))
        ∧ Qc) }}}
    Open #() @ NotStuck; LVL (S (S (S k))); ⊤; E2
  {{{ lptr, RET #lptr; is_log k' lptr ∗ Q lptr }}}
  {{{ Qc }}}.
Proof using PStartedOpening_Timeless.
  iIntros (? Hwand Φ Φc) "(#Hlog_inv&Hvs) HΦ".
  iApply wpc_fupd.
  rewrite /log_inv.
  iDestruct "Hlog_inv" as (γ2) "#Hinv".
  iApply wpc_step_fupdN_inner3; first done.
  iInv "Hinv" as "Hinner" "Hclo".
  iMod (fupd_intro_mask' _ ∅) as "Hclo'"; first by set_solver+.
  do 2 iModIntro. iNext. iMod "Hclo'" as "_".
  rewrite /log_inv_inner.
  iDestruct "Hinner" as (s) "(Hstate_to_inv&Hauth_state)".
  destruct s;
    try (iDestruct "Hvs" as "(_&(Hbad&_))";
         iMod ("Hbad" with "[Hstate_to_inv]") as %[];
         eauto; done).
  (* UnInit case *)
  { iDestruct "Hstate_to_inv" as "(Hval&Hfrag_state)".
    iApply (na_crash_inv_open_modify _ _ O (⊤ ∖ ↑N) ⊤ with "Hval").
    { solve_ndisj. }
    iIntros "[(Hlog_crash_cond&Hclose)|(Hc&Hclose)]".
    - iDestruct "Hlog_crash_cond" as "(Hlog_state&HP)".
      iDestruct "Hvs" as "(Hvs&_)"; iMod ("Hvs" with "HP"); try eauto; done.
    - iMod "Hclose". iMod ("Hclo" with "[Hclose Hfrag_state Hauth_state]"); first eauto.
      { iNext. iExists _. iFrame. }
      iApply step_fupdN_inner_later; auto.
      iApply wpc_C. iFrame.
      iDestruct "Hvs" as "(_&_&_&?)".
      by iApply "HΦ".
  }
  iDestruct "Hstate_to_inv" as "(Hval&Hfrag_state)".
  iApply (na_crash_inv_open_modify _ _ O (⊤ ∖ ↑N) ⊤ with "Hval").
  { solve_ndisj. }
  iIntros "[(Hlog_crash_cond&Hclose)|(Hc&Hclose)]".
  - iDestruct "Hlog_crash_cond" as "(Hlog_state&HP)".
    (* Viewshift to the "Opening" state, which will let us take out the na_crash_inv_full from inv *)
    iDestruct "Hvs" as "(_&_&Hvs)". iMod ("Hvs" with "HP") as "(Hopening&HP&Hvs)".
    iMod ("Hclose" $! (log_state_to_crash (Opening s) ∗ P (Opening s))%I with "[HP Hlog_state]") as "Hfull".
    { iSplitL "HP Hlog_state".
      - iNext. iFrame.
      - iAlways. iIntros. iExists _; eauto. }
    iMod (ghost_var_update _ (Opening s : log_stateO) with "[$] [$]") as "(Hauth_state&Hfrag_state)".
    iMod ("Hclo" with "[Hopening Hauth_state]").
    { iNext. iExists _; iFrame; eauto. }
    (* XXX: make it so you can iModIntro |={E,E}_k=> *)
    iApply step_fupdN_inner_later; auto.
    iApply (wpc_na_crash_inv_open_modify (λ v,
                                       match v with
                                       | LitV (LitLoc l) => (∃ bs, ptsto_log l bs ∗ P (Opened bs l))
                                       | _ => False
                                       end)%I with "Hfull"); try auto.
    iSplit.
    { iApply "HΦ". iDestruct "Hvs" as "($&_)". }
    iIntros "(Hlog&HP)".
    iApply wpc_fupd.
    wpc_apply (wpc_Open with "[$] [-]").
    iSplit.
    * iIntros. iSplitL "Hvs HΦ".
      ** iApply "HΦ". iDestruct "Hvs" as "($&_)".
      ** iExists (Opening s). iFrame.
    * iNext. iIntros (lptr) "(Hlog&Hlock)".
      iDestruct "Hlock" as (ml) "(Hpts&Hlock)".
      iDestruct "Hvs" as "(_&Hvs)".
      iInv "Hinv" as "H" "Hclo".
      iDestruct "H" as (s') "(Hlog_state_to_inv&>Hauth_state)".
      unify_ghost. iDestruct "Hlog_state_to_inv" as ">HStartedOpening".
      iMod ("Hvs" $! lptr with "HP HStartedOpening") as "(HQc&HP&HPOpened)".
      iMod (ghost_var_update _ (Opened s lptr: log_stateO) with "[$] [$]") as "(Hauth_state&Hfrag_state)".
      iMod ("Hclo" with "[HPOpened Hauth_state Hfrag_state]") as "_".
      { iNext. iExists _; iFrame. }
      iSplitL "HP Hlog".
      { iExists _. iFrame. eauto. }
      iModIntro.
      iSplitR; first eauto.
      { iAlways. iIntros "H". iDestruct "H" as (bs) "(?&?)". iExists _. iFrame.
        simpl. by iApply ptsto_log_crashed. }
      iIntros "Hfull". iSplit.
      ** iMod (inv_alloc Nlog _ (∃ q, lptr ↦[Log.S :: "m"]{q} #ml) with "[Hpts]") as "Hread".
         { iNext; iExists _; iFrame. }
         iMod (alloc_crash_lock' with "Hlock Hfull") as (?) "Hcrash_lock".
         iModIntro. iApply "HΦ". iFrame. iExists _. rewrite /log_inv. iSplitL "".
         { iExists _. rewrite /log_inv_inner. eauto. }
         iFrame. iExists _. iFrame.
      ** iApply "HΦ". by iApply Hwand.
  - iMod "Hclose". iMod ("Hclo" with "[Hclose Hfrag_state Hauth_state]"); first eauto.
    { iNext. iExists _. iFrame. }
    iApply step_fupdN_inner_later; auto.
    iApply wpc_C. iFrame.
    iDestruct "Hvs" as "(_&_&_&?)".
    by iApply "HΦ".
Qed.

Theorem wpc_Init (sz: u64) k k' E2 Qc Q:
  int.nat sz = SIZE →
  (S k < k')%nat →
  (∀ l, Q l -∗ Qc) →
  {{{ log_inv k'
      ∗ ((∀ vs, P (Closed vs) ={⊤ ∖ ↑N ∖ ↑N2}=∗ False)
        ∧ (PStartedIniting ∨ PStartedOpening ∨ POpened ={⊤ ∖ ↑N}=∗ False)
        ∧ (P (UnInit) ={⊤ ∖ ↑N ∖ ↑N2}=∗
              PStartedIniting ∗ P (Initing)
              ∗ (Qc ∧ ∀ l, P Initing -∗ PStartedIniting ={⊤ ∖ ↑N2 ∖ ↑N}=∗
                           Q l ∗ P (Opened [] l) ∗ POpened))
        ∧ Qc) }}}
    Init #sz @ NotStuck; LVL (S (S (S k))); ⊤; E2
  {{{ l, RET (#l, #true);  is_log k' l ∗ Q l}}}
  {{{ Qc }}}.
Proof using PStartedIniting_Timeless SIZE_nonzero.
  iIntros (Hsize ? Hwand Φ Φc) "(#Hlog_inv&Hvs) HΦ".
  iApply wpc_fupd.
  rewrite /log_inv.
  iDestruct "Hlog_inv" as (γ2) "#Hinv".
  iApply wpc_step_fupdN_inner3; first done.
  iInv "Hinv" as "Hinner" "Hclo".
  iMod (fupd_intro_mask' _ ∅) as "Hclo'"; first by set_solver+.
  do 2 iModIntro. iNext. iMod "Hclo'" as "_".
  rewrite /log_inv_inner.
  iDestruct "Hinner" as (s) "(Hstate_to_inv&Hauth_state)".
  destruct s;
    try (iDestruct "Hvs" as "(_&(Hbad&_))";
         iMod ("Hbad" with "[Hstate_to_inv]") as %[];
         eauto; done).
  2:{
    iDestruct "Hstate_to_inv" as "(Hval&Hfrag_state)".
    iApply (na_crash_inv_open_modify _ _ O (⊤ ∖ ↑N) ⊤ with "Hval").
    { solve_ndisj. }
    iIntros "[(Hlog_crash_cond&Hclose)|(Hc&Hclose)]".
    - iDestruct "Hlog_crash_cond" as "(Hlog_state&HP)".
      iDestruct "Hvs" as "(Hvs&_)"; iMod ("Hvs" with "HP"); try eauto; done.
    - iMod "Hclose". iMod ("Hclo" with "[Hclose Hfrag_state Hauth_state]"); first eauto.
      { iNext. iExists _. iFrame. }
      iApply step_fupdN_inner_later; auto.
      iApply wpc_C. iFrame.
      iDestruct "Hvs" as "(_&_&_&?)".
      by iApply "HΦ".
  }
  iDestruct "Hstate_to_inv" as "(Hval&Hfrag_state)".
  iApply (na_crash_inv_open_modify _ _ O (⊤ ∖ ↑N) ⊤ with "Hval").
  { solve_ndisj. }
  iIntros "[(Hlog_crash_cond&Hclose)|(Hc&Hclose)]".
  - iDestruct "Hlog_crash_cond" as "(Hlog_state&HP)".
    (* Viewshift to the "Initing" state, which will let us take out the na_crash_inv_full from inv *)
    iDestruct "Hvs" as "(_&_&Hvs)". iMod ("Hvs" with "HP") as "(Hopening&HP&Hvs)".
    iMod ("Hclose" $! (log_state_to_crash (Initing) ∗ P (Initing))%I with "[HP Hlog_state]") as "Hfull".
    { iSplitL "HP Hlog_state".
      - iNext. iFrame.
      - iAlways. iIntros. iExists _; eauto. }
    iMod (ghost_var_update _ (Initing : log_stateO) with "[$] [$]") as "(Hauth_state&Hfrag_state)".
    iMod ("Hclo" with "[Hopening Hauth_state]").
    { iNext. iExists _; iFrame; eauto. }
    (* XXX: make it so you can iModIntro |={E,E}_k=> *)
    iApply step_fupdN_inner_later; auto.
    iApply (wpc_na_crash_inv_open_modify (λ v,
                                       match v with
                                       | PairV (LitV (LitLoc l))
                                               (LitV (LitBool true))
                                         => (∃ bs, ptsto_log l bs ∗ P (Opened bs l))
                                       | _ => False
                                       end)%I with "Hfull"); try auto.
    iSplit.
    { iApply "HΦ". iDestruct "Hvs" as "($&_)". }
    iIntros "(Hlog&HP)".
    iApply wpc_fupd.
    iDestruct "Hlog" as (vs) "(Hd&%)".
    wpc_apply (wpc_init with "[Hd] [-]").
    { iFrame. iPureIntro. congruence. }
    iSplit.
    * iIntros "Hcrash". iSplitL "Hvs HΦ".
      ** iApply "HΦ". iDestruct "Hvs" as "($&_)".
      ** iExists Initing. iFrame.
         iDestruct "Hcrash" as "[H|H]".
         { iExists _; iFrame; eauto. }
         { iDestruct "H" as (??? Heq) "H".
           iExists _; iFrame. iPureIntro. subst. simpl in *. eauto. }
    * iNext. iIntros (lptr ok) "(Heq_ok&Hlog)".
      iDestruct "Heq_ok" as %Heq_ok.
      iDestruct "Hvs" as "(_&Hvs)".
      iInv "Hinv" as "H" "Hclo".
      iDestruct "H" as (s') "(Hlog_state_to_inv&>Hauth_state)".
      unify_ghost. iDestruct "Hlog_state_to_inv" as ">HStartedOpening".
      assert (ok = true) as ->.
      { apply Heq_ok. lia. }
      iMod ("Hvs" $! lptr with "HP HStartedOpening") as "(HQc&HP&HPOpened)".
      iMod (ghost_var_update _ (Opened [] lptr: log_stateO) with "[$] [$]") as "(Hauth_state&Hfrag_state)".
      iMod ("Hclo" with "[HPOpened Hauth_state Hfrag_state]") as "_".
      { iNext. iExists _; iFrame. }
      iDestruct "Hlog" as "(Hlog&Hlock)".
      iDestruct "Hlock" as (ml) "(Hpts&Hlock)".
      iSplitL "HP Hlog".
      { iExists _. iFrame. eauto. }
      iModIntro.
      iSplitR; first eauto.
      { iAlways. iIntros "H". iDestruct "H" as (bs) "(?&?)". iExists _. iFrame.
        simpl. by iApply ptsto_log_crashed. }
      iIntros "Hfull". iSplit.
      ** iMod (inv_alloc Nlog _ (∃ q, lptr ↦[Log.S :: "m"]{q} #ml) with "[Hpts]") as "Hread".
         { iNext; iExists _; iFrame. }
         iMod (alloc_crash_lock' with "Hlock Hfull") as (?) "Hcrash_lock".
         iModIntro. iApply "HΦ". iFrame. iExists _. rewrite /log_inv. iSplitL "".
         { iExists _. rewrite /log_inv_inner. eauto. }
         iFrame. iExists _. iFrame.
      ** iApply "HΦ". by iApply Hwand.
  - iMod "Hclose". iMod ("Hclo" with "[Hclose Hfrag_state Hauth_state]"); first eauto.
    { iNext. iExists _. iFrame. }
    iApply step_fupdN_inner_later; auto.
    iApply wpc_C. iFrame.
    iDestruct "Hvs" as "(_&_&_&?)".
    by iApply "HΦ".
Qed.

End hocap.
