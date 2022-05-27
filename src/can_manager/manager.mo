import IC "./ic";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Buffer "mo:base/Buffer";
import Blob "mo:base/Blob";
import RBT "mo:base/RBTree";
import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";

// 多人钱包 Actor
actor class Manager(members_init: [Principal], auth_threhold: Nat) = self {
  private let CYCLE_LIMIT = 200_000_000_000;

  func size_of<T>(items: [T]): Nat {
    var item_size = 0;
    for (_ in items.vals()) {
      item_size += 1;
    };
    item_size
  };

  // 该多人钱包所需要初始化的参数M，N以及最开始的小组成员
  private stable var N = size_of(members_init);
  private stable var M = auth_threhold;
  private stable var members = members_init;

  private stable var new_can_index: Nat = 0;
  private let cans = RBT.RBTree<Nat, Principal>(Nat.compare); // 存储创建的canister
  private stable var cans_text: [Text] = [];

  system func preupgrade() {
    if (new_can_index > 0) {
      var cans_buf = Buffer.Buffer<Text>(new_can_index);
      var i = 0;
      while (i < new_can_index) {
        let can = cans.get(i);
        switch (can) {
          case (?can) {
            cans_buf.add(Principal.toText(can));
          };
          case (null) { };
        };
        i += 1;
      };
      if (cans_buf.size() > 0) {
        cans_text := cans_buf.toArray();
      };
    };
  };

  system func postupgrade() {
    let cans_num = size_of(cans_text);
    if (cans_num > 0) {
      var i = 0;
      while (i < cans_num) {
        cans.put(new_can_index, Principal.fromText(cans_text[i]));
        new_can_index += 1;
        i += 1;
      };
    };
  };

  public query({caller}) func cycleBalance(): async Nat{
    Cycles.balance()
  };

  public shared({caller}) func wallet_receive(): async Nat {
    Cycles.accept(Cycles.available())
  };

  //创建被该多人钱包管理的canister
  public shared({caller}) func create_canister() : async IC.canister_id {    
    let settings = {
      freezing_threshold = null;
      controllers = ?[Principal.fromActor(self)];
      memory_allocation = null;
      compute_allocation = null;
    };
    let ic: IC.Self = actor("aaaaa-aa"); //ledger actor的ID

    Cycles.add(CYCLE_LIMIT);
    let result = await ic.create_canister({ settings = ?settings; });
    cans.put(new_can_index, result.canister_id);
    new_can_index += 1;
    result.canister_id
  };

  public shared({caller}) func install_code(
    wasm: Blob,
    canister: Text,
    mode: { #reinstall; #upgrade; #install }
  ) : async Text { 
    let settings = { 
      arg = [];  
      wasm_module = Blob.toArray(wasm);
      mode = mode;
      canister_id = Principal.fromText(canister);
    };
    let ic: IC.Self = actor("aaaaa-aa"); //ledger actor的ID
    await ic.install_code(settings);
    "code installed for " # canister
  };

  public shared({caller}) func start_canister(canister : Text) : async () {    
    let settings = { 
      canister_id = Principal.fromText(canister);
    };
    let ic: IC.Self = actor("aaaaa-aa"); //ledger actor的ID
    await ic.start_canister(settings)
  };

  public shared({caller}) func stop_canister(canister : Text) : async () {    
    let settings = { 
      canister_id = Principal.fromText(canister);
    };
    let ic: IC.Self = actor("aaaaa-aa"); //ledger actor的ID
    await ic.stop_canister(settings)
  };

  public shared({caller}) func delete_canister(canister : Text) : async () {    
    let settings = { 
      canister_id = Principal.fromText(canister);
    };
    let ic: IC.Self = actor("aaaaa-aa"); //ledger actor的ID
    await ic.delete_canister(settings)
  };

  // 调试测试专用 Hello
  type HelloCan = actor {
    greet: shared(Text) -> async Text;
  };

  public shared({caller}) func test_hello(canister: Text, name: Text): async Text {
    let hello: HelloCan = actor(canister);
    await hello.greet(name)
  };

  public query({caller}) func get_canisters(): async [Text] {
    var cans_buf = Buffer.Buffer<Text>(new_can_index);
    var i = 0;
    while (i < new_can_index) {
      let can = cans.get(i);
      switch (can) {
        case (?can) {
          let can_text = Principal.toText(can);
          cans_buf.add(can_text);
        };
        case (null) { assert(false) };
      };
      
      i += 1;
    };
    cans_buf.toArray()
  };

  public query({caller}) func get_members(): async [Principal] {
    members
  };

  type Operation = {
    #enable_auth: Principal;
    #disable_auth: Principal;
  };

  private var new_proposal_index: Nat = 0;
  private let proposals = RBT.RBTree<Nat, (Operation, Buffer.Buffer<Principal>)>(Nat.compare);

  func includes(principals: [Principal], principal: Principal): Bool {
    for (p in principals.vals()) {
      if (Principal.toText(principal) == Principal.toText(p)) { 
        return true
      };
    };
    false
  };

  // 实现M/N的多签提案
  public shared({caller}) func propose(proposal: Operation): async () {
    // Debug.print(Principal.toText(caller));
    assert(includes(members, caller));
    let voters = Buffer.Buffer<Principal>(1);
    voters.add(caller);
    proposals.put(new_proposal_index, (proposal, voters));
    new_proposal_index += 1;
  };

  // 实现M/N的多签执行
  public shared({caller}) func vote(proposal_id: Nat): async Text {
    // Debug.print(Principal.toText(caller));
    assert(includes(members, caller));
    let proposal = proposals.get(proposal_id);
    switch (proposal) {
      case (?proposal) {
        let voters = proposal.1;
        if (includes(voters.toArray(), caller)) return "Already voted";
        voters.add(caller);
        proposals.put(proposal_id, (proposal.0, voters));
        if (voters.size() >= M) return "Proposal excuted"
        else return "Proposal voted";
      };
      case (null) { "Error: No proposal found" };
    };
  };

  // 实现M/N的多签执行
  public query({caller}) func view_proposals(): async [(Nat, (Operation, Nat))] {
    var proposals_buf = Buffer.Buffer<(Nat, (Operation, Nat))>(new_proposal_index);
    var i = 0;
    while (i < new_proposal_index) {
      let proposal = proposals.get(i);
      switch (proposal) {
        case (?proposal) {
          proposals_buf.add((i, (proposal.0, proposal.1.size())));
        };
        case (null) { assert(false) };
      };
      i += 1;
    };
    proposals_buf.toArray()
  };
};


// {
//   dependencies = [ "base" ],
//   compiler = None Text
// }


// let upstream = https://github.com/dfinity/vessel-package-set/releases/download/mo-0.6.18-20220107/package-set.dhall
// let additions = [
//     ]
// in  upstream # additions