import IC "./ic";
import Principal "mo:base/Principal";
import Buffer "mo:base/Buffer";
import Blob "mo:base/Blob";
import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import Manager "./manager";

// create a multi-sig wallet by this canister
actor {
  private let CYCLE_LIMIT = 2_000_000_000_000; //根据需要进行分配

  public query({caller}) func cycleBalance(): async Nat{
    Cycles.balance()
  };

  public shared({caller}) func wallet_receive(): async Nat {
    Cycles.accept(Cycles.available())
  };

  func size_of(texts: [Text]): Nat {
    var text_size = 0;
    for (_ in texts.vals()) {
      text_size += 1;
    };
    text_size
  };

  func init_members(members: [Text]): [Principal] {
    var principals = Buffer.Buffer<Principal>(size_of(members));
    for (member in members.vals()) {
      principals.add(Principal.fromText(member));
    };
    principals.toArray()
  };

  public shared({caller}) func create_manager(members_init: [Text], auth_threhold: Nat): async Principal {
    let ic: IC.Self = actor("aaaaa-aa"); //ledger actor的ID
    let members = init_members(members_init);
    assert(auth_threhold <= size_of(members_init));

    Cycles.add(CYCLE_LIMIT);
    let manager = await Manager.Manager(members, auth_threhold);
    let principal = Principal.fromActor(manager);

    await ic.update_settings({
      canister_id = principal;
      settings = {
        freezing_threshold = ?2592000;
        controllers = ?members;
        memory_allocation = ?0;
        compute_allocation = ?0;
      }
    });
    
    principal
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
