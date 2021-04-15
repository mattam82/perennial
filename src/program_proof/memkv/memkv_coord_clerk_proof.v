From Perennial.program_proof Require Import proof_prelude.
From Goose.github_com.mit_pdos.gokv Require Import memkv.
From Perennial.goose_lang Require Import ffi.grove_ffi.
From Perennial.program_proof.lockservice Require Import rpc.
From Perennial.program_proof.memkv Require Import common_proof memkv_shard_clerk_proof.

Section memkv_coord_clerk_proof.

Context `{!heapG Σ, rpcG Σ GetReplyC}.

Axiom own_MemKVCoordClerk : loc → iProp Σ.

Lemma wp_MemKVCoordClerk__GetShardMap (ck:loc) :
  {{{
       own_MemKVCoordClerk ck
  }}}
    MemKVCoordClerk__GetShardMap #ck
  {{{
       shardMap_sl (shardMapping:list u64), RET (slice_val shardMap_sl);
       own_MemKVCoordClerk ck ∗
       typed_slice.is_slice shardMap_sl uint64T 1%Qp shardMapping ∗
       ⌜length shardMapping = uNSHARD⌝
  }}}
.
Proof.
Admitted.

Axiom own_ShardClerkSet : loc → gname → iProp Σ.

(* TODO: need precondition that [[is_shard_server host]] *)
Lemma wp_ShardClerkSet__getClerk (γkv:gname) (s:loc) (host:u64) :
  {{{
       own_ShardClerkSet s γkv
  }}}
    ShardClerkSet__getClerk #s #host
  {{{
       (ck_ptr:loc) γsh, RET #ck_ptr; own_MemKVShardClerk ck_ptr γsh ∗
                                      ⌜γsh.(kv_gn) = γkv⌝ ∗
                                    (own_MemKVShardClerk ck_ptr γsh -∗ own_ShardClerkSet s γkv)
  }}}.
Proof.
Admitted.

End memkv_coord_clerk_proof.