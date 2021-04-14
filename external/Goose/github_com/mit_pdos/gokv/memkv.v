(* autogenerated from memkv *)
From Perennial.goose_lang Require Import prelude.
From Perennial.goose_lang Require Import ffi.grove_prelude.

From Goose Require github_com.mit_pdos.lockservice.grove_common.
From Goose Require github_com.tchajed.marshal.

(* 0_common.go *)

Definition HostName: ty := uint64T.

Definition ValueType: ty := uint64T.

Definition ErrorType: ty := uint64T.

Definition ENone : expr := #0.

Definition EDontHaveShard : expr := #1.

Definition NSHARD : expr := #65536.

Definition KV_FRESHCID : expr := #0.

Definition KV_PUT : expr := #1.

Definition KV_GET : expr := #2.

Definition KV_INS_SHARD : expr := #3.

Definition KV_MOV_SHARD : expr := #3.

Definition shardOf: val :=
  rec: "shardOf" "key" :=
    "key" `rem` NSHARD.

Module PutRequest.
  Definition S := struct.decl [
    "CID" :: uint64T;
    "Seq" :: uint64T;
    "Key" :: uint64T;
    "Value" :: slice.T byteT
  ].
End PutRequest.

(* doesn't include the operation type *)
Definition encodePutRequest: val :=
  rec: "encodePutRequest" "args" :=
    let: "num_bytes" := #8 + #8 + #8 + #8 + slice.len (struct.loadF PutRequest.S "Value" "args") in
    let: "e" := marshal.NewEnc "num_bytes" in
    marshal.Enc__PutInt "e" (struct.loadF PutRequest.S "CID" "args");;
    marshal.Enc__PutInt "e" (struct.loadF PutRequest.S "Seq" "args");;
    marshal.Enc__PutInt "e" (struct.loadF PutRequest.S "Key" "args");;
    marshal.Enc__PutInt "e" (slice.len (struct.loadF PutRequest.S "Value" "args"));;
    marshal.Enc__PutBytes "e" (struct.loadF PutRequest.S "Value" "args");;
    marshal.Enc__Finish "e".

Definition decodePutRequest: val :=
  rec: "decodePutRequest" "reqData" :=
    let: "req" := struct.alloc PutRequest.S (zero_val (struct.t PutRequest.S)) in
    let: "d" := marshal.NewDec "reqData" in
    struct.storeF PutRequest.S "CID" "req" (marshal.Dec__GetInt "d");;
    struct.storeF PutRequest.S "Seq" "req" (marshal.Dec__GetInt "d");;
    struct.storeF PutRequest.S "Key" "req" (marshal.Dec__GetInt "d");;
    struct.storeF PutRequest.S "Value" "req" (marshal.Dec__GetBytes "d" (marshal.Dec__GetInt "d"));;
    "req".

Module PutReply.
  Definition S := struct.decl [
    "Err" :: ErrorType
  ].
End PutReply.

Definition encodePutReply: val :=
  rec: "encodePutReply" "reply" :=
    let: "e" := marshal.NewEnc #8 in
    marshal.Enc__PutInt "e" (struct.loadF PutReply.S "Err" "reply");;
    marshal.Enc__Finish "e".

Definition decodePutReply: val :=
  rec: "decodePutReply" "replyData" :=
    let: "reply" := struct.alloc PutReply.S (zero_val (struct.t PutReply.S)) in
    let: "d" := marshal.NewDec "replyData" in
    struct.storeF PutReply.S "Err" "reply" (marshal.Dec__GetInt "d");;
    "reply".

Module GetRequest.
  Definition S := struct.decl [
    "CID" :: uint64T;
    "Seq" :: uint64T;
    "Key" :: uint64T
  ].
End GetRequest.

Module GetReply.
  Definition S := struct.decl [
    "Err" :: ErrorType;
    "Value" :: slice.T byteT
  ].
End GetReply.

Definition encodeGetRequest: val :=
  rec: "encodeGetRequest" "req" :=
    let: "e" := marshal.NewEnc (#3 * #8) in
    marshal.Enc__PutInt "e" (struct.loadF GetRequest.S "CID" "req");;
    marshal.Enc__PutInt "e" (struct.loadF GetRequest.S "Seq" "req");;
    marshal.Enc__PutInt "e" (struct.loadF GetRequest.S "Key" "req");;
    marshal.Enc__Finish "e".

Definition decodeGetRequest: val :=
  rec: "decodeGetRequest" "rawReq" :=
    let: "req" := struct.alloc GetRequest.S (zero_val (struct.t GetRequest.S)) in
    let: "d" := marshal.NewDec "rawReq" in
    struct.storeF GetRequest.S "CID" "req" (marshal.Dec__GetInt "d");;
    struct.storeF GetRequest.S "Seq" "req" (marshal.Dec__GetInt "d");;
    struct.storeF GetRequest.S "Key" "req" (marshal.Dec__GetInt "d");;
    "req".

Definition encodeGetReply: val :=
  rec: "encodeGetReply" "rep" :=
    let: "num_bytes" := #8 + #8 + slice.len (struct.loadF GetReply.S "Value" "rep") in
    let: "e" := marshal.NewEnc "num_bytes" in
    marshal.Enc__PutInt "e" (struct.loadF GetReply.S "Err" "rep");;
    marshal.Enc__PutInt "e" (slice.len (struct.loadF GetReply.S "Value" "rep"));;
    marshal.Enc__PutBytes "e" (struct.loadF GetReply.S "Value" "rep");;
    marshal.Enc__Finish "e".

Definition decodeGetReply: val :=
  rec: "decodeGetReply" "rawRep" :=
    let: "rep" := struct.alloc GetReply.S (zero_val (struct.t GetReply.S)) in
    let: "d" := marshal.NewDec "rawRep" in
    struct.storeF GetReply.S "Err" "rep" (marshal.Dec__GetInt "d");;
    struct.storeF GetReply.S "Value" "rep" (marshal.Dec__GetBytes "d" (marshal.Dec__GetInt "d"));;
    "rep".

Module InstallShardRequest.
  Definition S := struct.decl [
    "CID" :: uint64T;
    "Seq" :: uint64T;
    "Sid" :: uint64T;
    "Kvs" :: mapT (slice.T byteT)
  ].
End InstallShardRequest.

Definition encodeInstallShardRequest: val :=
  rec: "encodeInstallShardRequest" "req" :=
    Panic "unimpl".

Definition decodeInstallShardRequest: val :=
  rec: "decodeInstallShardRequest" "rawReq" :=
    Panic "unimpl".

Module MoveShardRequest.
  Definition S := struct.decl [
    "Sid" :: uint64T;
    "Dst" :: HostName
  ].
End MoveShardRequest.

Definition encodeMoveShardRequest: val :=
  rec: "encodeMoveShardRequest" "req" :=
    Panic "unimpl".

Definition decodeMoveShardRequest: val :=
  rec: "decodeMoveShardRequest" "rawReq" :=
    Panic "unimpl".

Definition encodeCID: val :=
  rec: "encodeCID" "cid" :=
    let: "e" := marshal.NewEnc #8 in
    marshal.Enc__PutInt "e" "cid";;
    marshal.Enc__Finish "e".

Definition decodeCID: val :=
  rec: "decodeCID" "rawCID" :=
    marshal.Dec__GetInt (marshal.NewDec "rawCID").

Definition encodeShardMap: val :=
  rec: "encodeShardMap" "shardMap" :=
    Panic "unimpl".

Definition decodeShardMap: val :=
  rec: "decodeShardMap" "raw" :=
    Panic "unimpl".

(* 1_memkv_shard_clerk.go *)

Module MemKVShardClerk.
  Definition S := struct.decl [
    "seq" :: uint64T;
    "cid" :: uint64T;
    "cl" :: struct.ptrT grove_ffi.RPCClient.S;
    "config" :: mapT stringT
  ].
End MemKVShardClerk.

Definition MakeFreshKVClerk: val :=
  rec: "MakeFreshKVClerk" "host" :=
    let: "ck" := struct.alloc MemKVShardClerk.S (zero_val (struct.t MemKVShardClerk.S)) in
    struct.storeF MemKVShardClerk.S "cl" "ck" (grove_ffi.MakeRPCClient (Fst (MapGet (struct.loadF MemKVShardClerk.S "config" "ck") "host")));;
    let: "rawRep" := NewSlice byteT #0 in
    grove_ffi.RPCClient__Call (struct.loadF MemKVShardClerk.S "cl" "ck") KV_FRESHCID (NewSlice byteT #0) "rawRep";;
    struct.storeF MemKVShardClerk.S "cid" "ck" (decodeCID "rawRep");;
    struct.storeF MemKVShardClerk.S "seq" "ck" #1;;
    "ck".

Definition MakeKVClerk: val :=
  rec: "MakeKVClerk" "cid" "host" :=
    let: "ck" := struct.alloc MemKVShardClerk.S (zero_val (struct.t MemKVShardClerk.S)) in
    struct.storeF MemKVShardClerk.S "cl" "ck" (grove_ffi.MakeRPCClient (Fst (MapGet (struct.loadF MemKVShardClerk.S "config" "ck") "host")));;
    struct.storeF MemKVShardClerk.S "cid" "ck" "cid";;
    struct.storeF MemKVShardClerk.S "seq" "ck" #1;;
    "ck".

Definition MakeKVClerkWithRPCClient: val :=
  rec: "MakeKVClerkWithRPCClient" "cid" "cl" :=
    let: "ck" := struct.alloc MemKVShardClerk.S (zero_val (struct.t MemKVShardClerk.S)) in
    struct.storeF MemKVShardClerk.S "cl" "ck" "cl";;
    struct.storeF MemKVShardClerk.S "cid" "ck" "cid";;
    struct.storeF MemKVShardClerk.S "seq" "ck" #1;;
    "ck".

Definition MemKVShardClerk__Put: val :=
  rec: "MemKVShardClerk__Put" "ck" "key" "value" :=
    let: "args" := struct.mk PutRequest.S [
      "CID" ::= struct.loadF MemKVShardClerk.S "cid" "ck";
      "Seq" ::= struct.loadF MemKVShardClerk.S "seq" "ck";
      "Key" ::= "key";
      "Value" ::= "value"
    ] in
    struct.storeF MemKVShardClerk.S "seq" "ck" (struct.loadF MemKVShardClerk.S "seq" "ck" + #1);;
    let: "rawRep" := NewSlice byteT #0 in
    Skip;;
    (for: (λ: <>, (grove_ffi.RPCClient__Call (struct.loadF MemKVShardClerk.S "cl" "ck") KV_PUT (encodePutRequest "args") "rawRep" = #true)); (λ: <>, Skip) := λ: <>,
      Continue);;
    struct.loadF PutReply.S "Err" (decodePutReply "rawRep").

Definition MemKVShardClerk__Get: val :=
  rec: "MemKVShardClerk__Get" "ck" "key" "value" :=
    let: "args" := struct.mk GetRequest.S [
      "CID" ::= struct.loadF MemKVShardClerk.S "cid" "ck";
      "Seq" ::= struct.loadF MemKVShardClerk.S "seq" "ck";
      "Key" ::= "key"
    ] in
    struct.storeF MemKVShardClerk.S "seq" "ck" (struct.loadF MemKVShardClerk.S "seq" "ck" + #1);;
    let: "rawRep" := NewSlice byteT #0 in
    Skip;;
    (for: (λ: <>, (grove_ffi.RPCClient__Call (struct.loadF MemKVShardClerk.S "cl" "ck") KV_GET (encodeGetRequest "args") "rawRep" = #true)); (λ: <>, Skip) := λ: <>,
      Continue);;
    let: "rep" := decodeGetReply "rawRep" in
    "value" <-[slice.T byteT] struct.loadF GetReply.S "Value" "rep";;
    struct.loadF GetReply.S "Err" "rep".

Definition MemKVShardClerk__InstallShard: val :=
  rec: "MemKVShardClerk__InstallShard" "ck" "sid" "kvs" :=
    let: "args" := struct.mk InstallShardRequest.S [
      "CID" ::= struct.loadF MemKVShardClerk.S "cid" "ck";
      "Seq" ::= struct.loadF MemKVShardClerk.S "seq" "ck";
      "Sid" ::= "sid";
      "Kvs" ::= "kvs"
    ] in
    struct.storeF MemKVShardClerk.S "seq" "ck" (struct.loadF MemKVShardClerk.S "seq" "ck" + #1);;
    let: "rawRep" := NewSlice byteT #0 in
    Skip;;
    (for: (λ: <>, (grove_ffi.RPCClient__Call (struct.loadF MemKVShardClerk.S "cl" "ck") KV_INS_SHARD (encodeInstallShardRequest "args") "rawRep" = #true)); (λ: <>, Skip) := λ: <>,
      Continue).

Definition MemKVShardClerk__MoveShard: val :=
  rec: "MemKVShardClerk__MoveShard" "ck" "sid" "dst" :=
    let: "args" := struct.mk MoveShardRequest.S [
      "Sid" ::= "sid";
      "Dst" ::= "dst"
    ] in
    let: "rawRep" := NewSlice byteT #0 in
    Skip;;
    (for: (λ: <>, (grove_ffi.RPCClient__Call (struct.loadF MemKVShardClerk.S "cl" "ck") KV_MOV_SHARD (encodeMoveShardRequest "args") "rawRep" = #true)); (λ: <>, Skip) := λ: <>,
      Continue).

(* 2_memkv_shard.go *)

Definition KvMap: ty := mapT (slice.T byteT).

Module MemKVShardServer.
  Definition S := struct.decl [
    "mu" :: lockRefT;
    "lastReply" :: mapT (struct.t GetReply.S);
    "lastSeq" :: mapT uint64T;
    "nextCID" :: uint64T;
    "shardMap" :: slice.T boolT;
    "kvss" :: slice.T KvMap;
    "peers" :: mapT (struct.ptrT MemKVShardClerk.S)
  ].
End MemKVShardServer.

Module PutArgs.
  Definition S := struct.decl [
    "Key" :: uint64T;
    "Value" :: ValueType
  ].
End PutArgs.

Definition MemKVShardServer__put_inner: val :=
  rec: "MemKVShardServer__put_inner" "s" "args" "reply" :=
    let: ("last", "ok") := MapGet (struct.loadF MemKVShardServer.S "lastSeq" "s") (struct.loadF PutRequest.S "CID" "args") in
    (if: "ok" && (struct.loadF PutRequest.S "Seq" "args" ≤ "last")
    then
      struct.storeF PutReply.S "Err" "reply" (struct.get GetReply.S "Err" (Fst (MapGet (struct.loadF MemKVShardServer.S "lastReply" "s") (struct.loadF PutRequest.S "CID" "args"))));;
      #()
    else
      MapInsert (struct.loadF MemKVShardServer.S "lastSeq" "s") (struct.loadF PutRequest.S "CID" "args") (struct.loadF PutRequest.S "Seq" "args");;
      let: "sid" := shardOf (struct.loadF PutRequest.S "Key" "args") in
      (if: (SliceGet boolT (struct.loadF MemKVShardServer.S "shardMap" "s") "sid" = #true)
      then
        MapInsert (SliceGet (mapT (slice.T byteT)) (struct.loadF MemKVShardServer.S "kvss" "s") "sid") (struct.loadF PutRequest.S "Key" "args") (struct.loadF PutRequest.S "Value" "args");;
        struct.storeF PutReply.S "Err" "reply" ENone
      else struct.storeF PutReply.S "Err" "reply" EDontHaveShard);;
      MapInsert (struct.loadF MemKVShardServer.S "lastReply" "s") (struct.loadF PutRequest.S "CID" "args") (struct.mk GetReply.S [
        "Err" ::= struct.loadF PutReply.S "Err" "reply"
      ])).

Definition MemKVShardServer__PutRPC: val :=
  rec: "MemKVShardServer__PutRPC" "s" "args" "reply" :=
    lock.acquire (struct.loadF MemKVShardServer.S "mu" "s");;
    MemKVShardServer__put_inner "s" "args" "reply";;
    lock.release (struct.loadF MemKVShardServer.S "mu" "s").

Definition MemKVShardServer__get_inner: val :=
  rec: "MemKVShardServer__get_inner" "s" "args" "reply" :=
    let: ("last", "ok") := MapGet (struct.loadF MemKVShardServer.S "lastSeq" "s") (struct.loadF GetRequest.S "CID" "args") in
    (if: "ok" && (struct.loadF GetRequest.S "Seq" "args" ≤ "last")
    then
      struct.store GetReply.S "reply" (Fst (MapGet (struct.loadF MemKVShardServer.S "lastReply" "s") (struct.loadF GetRequest.S "CID" "args")));;
      #()
    else
      MapInsert (struct.loadF MemKVShardServer.S "lastSeq" "s") (struct.loadF GetRequest.S "CID" "args") (struct.loadF GetRequest.S "Seq" "args");;
      let: "sid" := shardOf (struct.loadF GetRequest.S "Key" "args") in
      (if: (SliceGet boolT (struct.loadF MemKVShardServer.S "shardMap" "s") "sid" = #true)
      then
        struct.storeF GetReply.S "Value" "reply" (SliceAppendSlice byteT (NewSlice byteT #0) (Fst (MapGet (SliceGet (mapT (slice.T byteT)) (struct.loadF MemKVShardServer.S "kvss" "s") "sid") (struct.loadF GetRequest.S "Key" "args"))));;
        struct.storeF GetReply.S "Err" "reply" ENone
      else struct.storeF GetReply.S "Err" "reply" EDontHaveShard);;
      MapInsert (struct.loadF MemKVShardServer.S "lastReply" "s") (struct.loadF GetRequest.S "CID" "args") (struct.load GetReply.S "reply")).

Definition MemKVShardServer__GetRPC: val :=
  rec: "MemKVShardServer__GetRPC" "s" "args" "reply" :=
    lock.acquire (struct.loadF MemKVShardServer.S "mu" "s");;
    MemKVShardServer__get_inner "s" "args" "reply";;
    lock.release (struct.loadF MemKVShardServer.S "mu" "s").

(* NOTE: easy to do a little optimization with shard migration:
   add a "RemoveShard" rpc, which removes the shard on the target server, and
   returns half of the ghost state for that shard. Meanwhile, InstallShard()
   will only grant half the ghost state, and physical state will keep track of
   the fact that the shard is only good for read-only operations up until that
   flag is updated (i.e. until RemoveShard() is run). *)
Definition MemKVShardServer__install_shard_inner: val :=
  rec: "MemKVShardServer__install_shard_inner" "s" "args" :=
    let: ("last", "ok") := MapGet (struct.loadF MemKVShardServer.S "lastSeq" "s") (struct.loadF InstallShardRequest.S "CID" "args") in
    (if: "ok" && (struct.loadF InstallShardRequest.S "Seq" "args" ≤ "last")
    then #()
    else
      MapInsert (struct.loadF MemKVShardServer.S "lastSeq" "s") (struct.loadF InstallShardRequest.S "CID" "args") (struct.loadF InstallShardRequest.S "Seq" "args");;
      SliceSet boolT (struct.loadF MemKVShardServer.S "shardMap" "s") (struct.loadF InstallShardRequest.S "Sid" "args") #true;;
      SliceSet (mapT (slice.T byteT)) (struct.loadF MemKVShardServer.S "kvss" "s") (struct.loadF InstallShardRequest.S "Sid" "args") (struct.loadF InstallShardRequest.S "Kvs" "args")).

Definition MemKVShardServer__InstallShardRPC: val :=
  rec: "MemKVShardServer__InstallShardRPC" "s" "args" :=
    lock.acquire (struct.loadF MemKVShardServer.S "mu" "s");;
    MemKVShardServer__install_shard_inner "s" "args";;
    lock.release (struct.loadF MemKVShardServer.S "mu" "s").

Definition MemKVShardServer__MoveShardRPC: val :=
  rec: "MemKVShardServer__MoveShardRPC" "s" "args" :=
    lock.acquire (struct.loadF MemKVShardServer.S "mu" "s");;
    (if: ~ (SliceGet boolT (struct.loadF MemKVShardServer.S "shardMap" "s") (struct.loadF MoveShardRequest.S "Sid" "args"))
    then
      lock.release (struct.loadF MemKVShardServer.S "mu" "s");;
      #()
    else
      let: (<>, "ok") := MapGet (struct.loadF MemKVShardServer.S "peers" "s") (struct.loadF MoveShardRequest.S "Dst" "args") in
      (if: ~ "ok"
      then
        lock.release (struct.loadF MemKVShardServer.S "mu" "s");;
        let: "ck" := MakeFreshKVClerk (struct.loadF MoveShardRequest.S "Dst" "args") in
        lock.acquire (struct.loadF MemKVShardServer.S "mu" "s");;
        MapInsert (struct.loadF MemKVShardServer.S "peers" "s") (struct.loadF MoveShardRequest.S "Dst" "args") "ck";;
        #()
      else #());;
      let: "kvs" := SliceGet (mapT (slice.T byteT)) (struct.loadF MemKVShardServer.S "kvss" "s") (struct.loadF MoveShardRequest.S "Sid" "args") in
      SliceSet (mapT (slice.T byteT)) (struct.loadF MemKVShardServer.S "kvss" "s") (struct.loadF MoveShardRequest.S "Sid" "args") slice.nil;;
      SliceSet boolT (struct.loadF MemKVShardServer.S "shardMap" "s") (struct.loadF MoveShardRequest.S "Sid" "args") #false;;
      lock.release (struct.loadF MemKVShardServer.S "mu" "s");;
      MemKVShardClerk__InstallShard (Fst (MapGet (struct.loadF MemKVShardServer.S "peers" "s") (struct.loadF MoveShardRequest.S "Dst" "args"))) (struct.loadF MoveShardRequest.S "Sid" "args") "kvs").

Definition MakeMemKVShardServer: val :=
  rec: "MakeMemKVShardServer" <> :=
    let: "srv" := struct.alloc MemKVShardServer.S (zero_val (struct.t MemKVShardServer.S)) in
    struct.storeF MemKVShardServer.S "mu" "srv" (lock.new #());;
    struct.storeF MemKVShardServer.S "lastReply" "srv" (NewMap (struct.t GetReply.S));;
    struct.storeF MemKVShardServer.S "lastSeq" "srv" (NewMap uint64T);;
    "srv".

Definition MemKVShardServer__GetCIDRPC: val :=
  rec: "MemKVShardServer__GetCIDRPC" "s" :=
    lock.acquire (struct.loadF MemKVShardServer.S "mu" "s");;
    let: "r" := struct.loadF MemKVShardServer.S "nextCID" "s" in
    struct.storeF MemKVShardServer.S "nextCID" "s" (struct.loadF MemKVShardServer.S "nextCID" "s" + #1);;
    lock.release (struct.loadF MemKVShardServer.S "mu" "s");;
    "r".

Definition MemKVShardServer__Start: val :=
  rec: "MemKVShardServer__Start" "mkv" :=
    let: "handlers" := NewMap grove_common.RawRpcFunc in
    MapInsert "handlers" KV_FRESHCID (λ: "rawReq" "rawReply",
      "rawReply" <-[slice.T byteT] encodeCID (MemKVShardServer__GetCIDRPC "mkv")
      );;
    MapInsert "handlers" KV_PUT (λ: "rawReq" "rawReply",
      let: "rep" := struct.alloc PutReply.S (zero_val (struct.t PutReply.S)) in
      MemKVShardServer__PutRPC "mkv" (decodePutRequest "rawReq") "rep";;
      "rawReply" <-[slice.T byteT] encodePutReply "rep"
      );;
    MapInsert "handlers" KV_GET (λ: "rawReq" "rawReply",
      let: "rep" := struct.alloc GetReply.S (zero_val (struct.t GetReply.S)) in
      MemKVShardServer__GetRPC "mkv" (decodeGetRequest "rawReq") "rep";;
      "rawReply" <-[slice.T byteT] encodeGetReply "rep"
      );;
    MapInsert "handlers" KV_INS_SHARD (λ: "rawReq" "rawReply",
      MemKVShardServer__InstallShardRPC "mkv" (decodeInstallShardRequest "rawReq");;
      "rawReply" <-[slice.T byteT] NewSlice byteT #0
      );;
    MapInsert "handlers" KV_MOV_SHARD (λ: "rawReq" "rawReply",
      MemKVShardServer__MoveShardRPC "mkv" (decodeMoveShardRequest "rawReq");;
      "rawReply" <-[slice.T byteT] NewSlice byteT #0
      );;
    grove_ffi.StartRPCServer "handlers".

(* 3_memkv_coord.go *)

Definition COORD_MOVE : expr := #1.

Definition COORD_GET : expr := #2.

Module MemKVCoord.
  Definition S := struct.decl [
    "mu" :: lockRefT;
    "config" :: mapT stringT;
    "shardMap" :: slice.T HostName
  ].
End MemKVCoord.

Definition MemKVCoord__AddServerRPC: val :=
  rec: "MemKVCoord__AddServerRPC" "c" "host" :=
    lock.acquire (struct.loadF MemKVCoord.S "mu" "c");;
    Panic ("shard rebalancing unimpl");;
    lock.release (struct.loadF MemKVCoord.S "mu" "c").

Definition MemKVCoord__GetShardMapRPC: val :=
  rec: "MemKVCoord__GetShardMapRPC" "c" <> "rep" :=
    lock.acquire (struct.loadF MemKVCoord.S "mu" "c");;
    "rep" <-[slice.T byteT] encodeShardMap (struct.fieldRef MemKVCoord.S "shardMap" "c");;
    lock.release (struct.loadF MemKVCoord.S "mu" "c").

Definition MakeMemKVCoordServer: val :=
  rec: "MakeMemKVCoordServer" <> :=
    let: "s" := struct.alloc MemKVCoord.S (zero_val (struct.t MemKVCoord.S)) in
    struct.storeF MemKVCoord.S "mu" "s" (lock.new #());;
    struct.storeF MemKVCoord.S "config" "s" (NewMap stringT);;
    MapInsert (struct.loadF MemKVCoord.S "config" "s") #1 #(str"localhost:37001");;
    MapInsert (struct.loadF MemKVCoord.S "config" "s") #2 #(str"localhost:37002");;
    let: "i" := ref_to uint64T #0 in
    (for: (λ: <>, ![uint64T] "i" < NSHARD); (λ: <>, "i" <-[uint64T] ![uint64T] "i" + #1) := λ: <>,
      SliceSet uint64T (struct.loadF MemKVCoord.S "shardMap" "s") (![uint64T] "i") ((![uint64T] "i") `rem` #2);;
      Continue);;
    "s".

Definition MemKVCoord__Start: val :=
  rec: "MemKVCoord__Start" "c" :=
    let: "handlers" := NewMap grove_common.RawRpcFunc in
    MapInsert "handlers" COORD_GET (MemKVCoord__GetShardMapRPC "c");;
    grove_ffi.StartRPCServer "handlers".

(* memkv_clerk.go *)

Module MemKVCoordClerk.
  Definition S := struct.decl [
    "seq" :: uint64T;
    "cid" :: uint64T;
    "cl" :: struct.ptrT grove_ffi.RPCClient.S;
    "shardMap" :: arrayT HostName
  ].
End MemKVCoordClerk.

Definition MemKVCoordClerk__MoveShard: val :=
  rec: "MemKVCoordClerk__MoveShard" "ck" "sid" "dst" :=
    #().

Definition MemKVCoordClerk__GetShardMap: val :=
  rec: "MemKVCoordClerk__GetShardMap" "ck" :=
    let: "rawRep" := ref (zero_val (slice.T byteT)) in
    grove_ffi.RPCClient__Call (struct.loadF MemKVCoordClerk.S "cl" "ck") COORD_GET (NewSlice byteT #0) "rawRep";;
    decodeShardMap (![slice.T byteT] "rawRep").

Module ShardClerkSet.
  Definition S := struct.decl [
    "cls" :: mapT (struct.ptrT MemKVShardClerk.S)
  ].
End ShardClerkSet.

Definition ShardClerkSet__getClerk: val :=
  rec: "ShardClerkSet__getClerk" "s" "host" :=
    let: ("ck", "ok") := MapGet (struct.loadF ShardClerkSet.S "cls" "s") "host" in
    (if: ~ "ok"
    then
      let: "ck2" := MakeFreshKVClerk "host" in
      MapInsert (struct.loadF ShardClerkSet.S "cls" "s") "host" "ck2";;
      "ck2"
    else "ck").

(* NOTE: a single clerk keeps quite a bit of state, via the shardMap[], so it
   might be good to not need to duplicate shardMap[] for a pool of clerks that's
   safe for concurrent use *)
Module MemKVClerk.
  Definition S := struct.decl [
    "seq" :: uint64T;
    "cid" :: uint64T;
    "shardClerks" :: struct.ptrT ShardClerkSet.S;
    "coordCk" :: struct.t MemKVCoordClerk.S;
    "shardMap" :: slice.T HostName
  ].
End MemKVClerk.

Definition MemKVClerk__Get: val :=
  rec: "MemKVClerk__Get" "ck" "key" :=
    let: "val" := ref (zero_val (slice.T byteT)) in
    Skip;;
    (for: (λ: <>, #true); (λ: <>, Skip) := λ: <>,
      let: "sid" := shardOf "key" in
      let: "shardServer" := SliceGet uint64T (struct.loadF MemKVClerk.S "shardMap" "ck") "sid" in
      let: "shardCk" := ShardClerkSet__getClerk (struct.loadF MemKVClerk.S "shardClerks" "ck") "shardServer" in
      let: "err" := MemKVShardClerk__Get "shardCk" "key" "val" in
      (if: ("err" = EDontHaveShard)
      then struct.storeF MemKVClerk.S "shardMap" "ck" (MemKVCoordClerk__GetShardMap (struct.loadF MemKVClerk.S "coordCk" "ck"))
      else
        (if: ("err" = ENone)
        then Break
        else #()));;
      Continue);;
    ![slice.T byteT] "val".

Definition MemKVClerk__Put: val :=
  rec: "MemKVClerk__Put" "ck" "key" "value" :=
    Skip;;
    (for: (λ: <>, #true); (λ: <>, Skip) := λ: <>,
      let: "sid" := shardOf "key" in
      let: "shardServer" := SliceGet uint64T (struct.loadF MemKVClerk.S "shardMap" "ck") "sid" in
      let: "shardCk" := ShardClerkSet__getClerk (struct.loadF MemKVClerk.S "shardClerks" "ck") "shardServer" in
      let: "err" := MemKVShardClerk__Put "shardCk" "key" "value" in
      (if: ("err" = EDontHaveShard)
      then struct.storeF MemKVClerk.S "shardMap" "ck" (MemKVCoordClerk__GetShardMap (struct.loadF MemKVClerk.S "coordCk" "ck"))
      else
        (if: ("err" = ENone)
        then Break
        else #()));;
      Continue);;
    #().
