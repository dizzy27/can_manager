import IC "./ic";
import Principal "mo:base/Principal";
import Blob "mo:base/Blob";
import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";

actor class () = self {
  private let CYCLE_LIMIT = 1_000_000_000_000; //根据需要进行分配

  public query({caller}) func cycleBalance(): async Nat{
    Cycles.balance()
  };

  public shared({caller}) func wallet_receive(): async Nat {
    Cycles.accept(Cycles.available())
  };

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

  // M/N多签提案实现 todo
  private stable var M: Nat = 2;
  private stable var N: Nat = 3;

  type Operation = {
    #start_canister: Text;
    #stop_canister: Text;
    #update_settings;
  };

  // 实现M/N的多签提案
  public shared({caller}) func propose(proposal: Operation): async Nat {
    // todo
    0
  };

  // 实现M/N的多签执行
  public shared({caller}) func approve(proposal_id: Nat): async () {
    // todo
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
