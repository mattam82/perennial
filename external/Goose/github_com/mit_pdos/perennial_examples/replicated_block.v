(* autogenerated from github.com/mit-pdos/perennial-examples/replicated_block *)
From Perennial.goose_lang Require Import prelude.
From Perennial.goose_lang Require Import ffi.disk_prelude.

Module RepBlock.
  Definition S := struct.decl [
    "d" :: disk.Disk;
    "addr" :: uint64T;
    "m" :: lockRefT
  ].
End RepBlock.

(* Open initializes a replicated block,
   either after a crash or from two disk blocks.

   Takes ownership of addr and addr+1 on disk. *)
Definition Open: val :=
  rec: "Open" "d" "addr" :=
    let: "b" := disk.Read "addr" in
    disk.Write ("addr" + #1) "b";;
    struct.new RepBlock.S [
      "d" ::= "d";
      "addr" ::= "addr";
      "m" ::= lock.new #()
    ].

(* readAddr returns the address to read from

   gives ownership of a disk block, so requires the lock to be held *)
Definition RepBlock__readAddr: val :=
  rec: "RepBlock__readAddr" "rb" "primary" :=
    (if: "primary"
    then struct.loadF RepBlock.S "addr" "rb"
    else struct.loadF RepBlock.S "addr" "rb" + #1).

Definition RepBlock__Read: val :=
  rec: "RepBlock__Read" "rb" "primary" :=
    lock.acquire (struct.loadF RepBlock.S "m" "rb");;
    let: "b" := disk.Read (RepBlock__readAddr "rb" "primary") in
    lock.release (struct.loadF RepBlock.S "m" "rb");;
    "b".

Definition RepBlock__Write: val :=
  rec: "RepBlock__Write" "rb" "b" :=
    lock.acquire (struct.loadF RepBlock.S "m" "rb");;
    disk.Write (struct.loadF RepBlock.S "addr" "rb") "b";;
    disk.Write (struct.loadF RepBlock.S "addr" "rb" + #1) "b";;
    lock.release (struct.loadF RepBlock.S "m" "rb").