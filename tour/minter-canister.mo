import Principal "mo:base/Principal";
import Blob "mo:base/Blob";
import Text "mo:base/Text";
import { now } "mo:base/Time";
import Ledger "icrc1-custom";
import ICRC1 "mo:icrc1-mo/ICRC1";
// import { print } "mo:base/Debug";
import Int "mo:base/Int";
import Nat64 "mo:base/Nat64";

/// Este canister debe ser desplegado despues de Triourism y antes del Tour ledger. 
// Luego de desplegado el Ledger ejecutar setLedger con el ledeger canister ID

shared ({ caller = Deployer}) actor class Minter({triourismCanisterId: Principal}) = this {


  //////////////// Si crece mover a un archivo de tipos ///////
    type Account = {owner: Principal; subaccount: ?Blob};

    public type FeesDispersionTable = {
        toBurnPermille: Nat;
        receivers: [{account: Account; permille: Nat}] // Permille es a mil lo que porcentage a 100
    };

  //////////////// Si crece mover a un modulo de Utils ////////
    
    func feesDispersionValidate(d: FeesDispersionTable): Bool {
        var result =  d.toBurnPermille;
        for (r in d.receivers.vals()) {
          result +=   r.permille
        };
        result < 1000;
    };

    func fee(): async  Nat {
      switch _fee {
        case null { await LedgerActor.icrc1_fee() };
        case ( ?f ) { 
          _fee := ?f;
          f
        }
      }
    };

  ///////////////////// Variables de estado ///////////////////

    let NULL_ADDRESS = "aaaaa-aa";
   
    // let fees_collector_subaccount: ?Blob = ? "FeeCollector00000000000000000000"; // El Blob del subaccount tiene que medir 32 Bytes
    // let pool_rewards: ?Blob = ? "PoolRewards00000000000000000000";

    // var pool_rewards_balance = 0;
    stable var _fee: ?Nat = null;

    func pool_rewards_account(): Account {
      {owner = Principal.fromActor(this); subaccount = ? "PoolRewards00000000000000000000"}
    };

    func fees_collector_account(): Account {
      {owner = Principal.fromActor(this); subaccount = ? "FeeCollector00000000000000000000"}
    };


    stable var LedgerActor = actor(NULL_ADDRESS): Ledger.CustomToken;
    stable let TriourismCanisterId = triourismCanisterId;
    stable var OldLedgerActor = actor(NULL_ADDRESS): Ledger.CustomToken; // Junto con restorePreviousLedger posiblemente innecesario
    stable var feesDispersionTable: FeesDispersionTable = {toBurnPermille = 0; receivers = []};
    

  /////////////////////// Settings //////////////////////////////////////////////////////////////////

    public shared ({ caller }) func setLedger(lerdgerCanisterId: Principal): async {#Ok; #Err: Text}{
        assert(caller == Deployer);
        OldLedgerActor := LedgerActor;
        LedgerActor := actor(Principal.toText(lerdgerCanisterId)): Ledger.CustomToken;
        _fee := ?(await LedgerActor.icrc1_fee());
        #Ok
    };

    public shared ({ caller }) func restorePreviousLedger(): async {#Ok; #Err: Text}{
        assert(caller == Deployer);
        if (Principal.fromActor(OldLedgerActor) != Principal.fromText("aaaaa-aa")) {
            LedgerActor := OldLedgerActor;
            OldLedgerActor := actor(NULL_ADDRESS): Ledger.CustomToken;
            _fee := ?(await OldLedgerActor.icrc1_fee());
            return #Ok
        };
        #Err("No hay registros de ledgers configurados previamente al actual")
    };

    public shared ({ caller }) func setFeesDispersionTable(d: FeesDispersionTable): async {#Ok; #Err: Text}{
        assert (caller == Deployer);
        if ( not feesDispersionValidate(d)) { return #Err("La suma de todos los items debe ser menor o igual a 1000") };
        feesDispersionTable := d;
        #Ok
    };

    func ledgerReady(): Bool { 
        Principal.fromActor(LedgerActor) != Principal.fromText(NULL_ADDRESS)    
    };

  //////////////////////////////////////  Getters Fees dispersion  section ///////////////////////////////////////////// 
    
    public query func getFeeCollector(): async Account { 
      fees_collector_account()
    };

    public shared func getFeeCollectorBalance(): async Nat {
      await LedgerActor.icrc1_balance_of(fees_collector_account())
    };

    public shared ({ caller }) func getFeesDispersionTable(): async FeesDispersionTable{
      assert(caller == Deployer);
      feesDispersionTable
    };

    public query func getLedgerCanisterId(): async Principal {
      Principal.fromActor(LedgerActor);
    };

  /////////////////////////////////////// Mint section ////////////////////////////////////////////////////////////////

    // public shared ({ caller }) func mintRewards(args: ICRC1.Mint): async ICRC1.TransferResult{
    //   print("Minter recibiendo llamada");
    //   assert(caller == TriourismCanisterId and ledgerReady());
    //   print("Llamada aceptada");
    //   await LedgerActor.mint(args);
    // };

    public shared ({ caller }) func issueRewards({accounts: [Account]; amount : Nat64}): async {#Ok; #Err}{  
      assert(caller == TriourismCanisterId and ledgerReady());
      let args = {
        amount = Nat64.toNat(amount);
        memo: ?Blob = null;
        created_at_time = ? Nat64.fromNat(Int.abs(now()));
      };
      let pool_rewards_balance = await LedgerActor.icrc1_balance_of(pool_rewards_account());
      if(pool_rewards_balance >= accounts.size() * (args.amount + (await fee()))){
        let from_subaccount: ?ICRC1.Subaccount = pool_rewards_account().subaccount;
        for (to in accounts.vals()){
          switch (await LedgerActor.icrc1_transfer({
            args with
            fee = null;
            from_subaccount;
            to;
          })) {
            case (#Err(_)) { ignore LedgerActor.mint({args with to})};
            case _ {}
          };
        }
      } else {
        for (to in accounts.vals()){
          ignore await LedgerActor.mint({args with to})
        }
      };

      #Ok

    };








}