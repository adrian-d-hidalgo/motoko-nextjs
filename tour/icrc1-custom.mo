import ExperimentalCycles "mo:base/ExperimentalCycles";
import Principal "mo:base/Principal";
import Nat64 "mo:base/Nat64";
import { now } "mo:base/Time";
import { print } "mo:base/Debug";
import Map "mo:map/Map";
import { phash } "mo:map/Map";

import ICRC1 "mo:icrc1-mo/ICRC1";
import ICRC2 "mo:icrc2-mo/ICRC2";
import Types "types";
import Tokenomic "tokenomic";
import Vec "mo:vector";
import Indexer "indexer";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Int "mo:base/Int";
import Nat8 "mo:base/Nat8";
import Buffer "mo:base/Buffer";
import Nat "mo:base/Nat";
import IC "../interfaces/ic-management-interface";

shared ({ caller = _owner }) actor class CustomToken(
  // init_args1 : ICRC1.InitArgs,
  // init_args2 : ICRC2.InitArgs,
  ledgerArgs : Types.LedgerArgument,
  customArgs : {
    distribution : ?Tokenomic.InitialDistribution;
    max_supply : ?Nat;
    metadata : [(Text, Types.MetadataValue)];
    min_burn_amount : ?Nat;
  },
) = this {

  ///////////////////////////////// WARNING ///////////////////////////////////////

  // let NanosPerDay = 24 * 60 * 60 * 1_000_000_000; // Valor definitivo
  let NanosPerDay = 2 * 1_000_000_000; // Valor para pruebas 1 dia = 4 segundo

  stable var distributionTimestamp : Int = 0;

  //////////////////////////////////////////////////////////////////////////////////

  stable var icrc1_args : ?ICRC1.InitArgs = null;
  stable var icrc2_args : ?ICRC2.InitArgs = null;
  switch ledgerArgs {
    case (#Init(initArgs)) {
      icrc1_args := ?{
        decimals = initArgs.decimals;
        advanced_settings = null;
        fee = ?#Fixed(initArgs.transfer_fee);
        minting_account = ?initArgs.minting_account;
        fee_collector = initArgs.fee_collector_account;
        logo = null;
        max_accounts = null;
        max_memo = initArgs.max_memo_length;
        max_supply = customArgs.max_supply;
        metadata = null;
        min_burn_amount = customArgs.min_burn_amount;
        name = ?initArgs.token_name;
        permitted_drift = null;
        settle_to_accounts = null;
        symbol = ?initArgs.token_symbol;
        transaction_window = null;
      };
      icrc2_args := ?{
        advanced_settings = null;
        fee = ?#Fixed(initArgs.transfer_fee);
        max_allowance = null;
        max_approvals = null;
        max_approvals_per_account = null;
        settle_to_approvals = null;
      };

    };

    case (#Upgrade(_)) {
      assert false;
    };
  };

  stable let icrc1_migration_state = ICRC1.init(ICRC1.initialState(), #v0_1_0(#id), icrc1_args, _owner);

  ///////////////////////////////////// Flags //////////////////////////////////////

  stable var distributionComplete = false;
  stable var vestingSchemes : [{ categoryName : Text; scheme : Tokenomic.VestingScheme; ended : Bool }] = [];
  stable var isLedgerReady = false;

  //////

  let #v0_1_0(#data(icrc1_state_current)) = icrc1_migration_state;

  private var _icrc1 : ?ICRC1.ICRC1 = null;

  private func get_icrc1_state() : ICRC1.CurrentState {
    return icrc1_state_current;
  };

  private func get_icrc1_environment() : ICRC1.Environment {
    {
      get_time = null;
      get_fee = null;
      add_ledger_transaction = null;
      can_transfer = null;
    };
  };

  func icrc1() : ICRC1.ICRC1 {
    switch (_icrc1) {
      case (null) {
        let initclass : ICRC1.ICRC1 = ICRC1.ICRC1(?icrc1_migration_state, Principal.fromActor(this), get_icrc1_environment());
        _icrc1 := ?initclass;
        initclass;
      };
      case (?val) val;
    };
  };

  stable let icrc2_migration_state = ICRC2.init(ICRC2.initialState(), #v0_1_0(#id), icrc2_args, _owner);

  let #v0_1_0(#data(icrc2_state_current)) = icrc2_migration_state;

  private var _icrc2 : ?ICRC2.ICRC2 = null;

  private func get_icrc2_state() : ICRC2.CurrentState {
    return icrc2_state_current;
  };

  private func get_icrc2_environment() : ICRC2.Environment {
    {
      icrc1 = icrc1();
      get_fee = null;
      can_approve = null;
      can_transfer_from = null;
    };
  };

  func icrc2() : ICRC2.ICRC2 {
    switch (_icrc2) {
      case (null) {
        let initclass : ICRC2.ICRC2 = ICRC2.ICRC2(?icrc2_migration_state, Principal.fromActor(this), get_icrc2_environment());
        _icrc2 := ?initclass;
        initclass;
      };
      case (?val) val;
    };
  };

  stable var _indexer : ?Indexer.Indexer = null;

  func pushTrxToIndexer(trxResult : ICRC1.TransferResult) : async ICRC1.TransferResult {
    switch (trxResult) {
      case (#Err(_)) {};
      case (#Ok(index)) {
        let local_transactions = icrc1().get_local_transactions();
        let _trx = Vec.get(local_transactions, index);
        switch (_indexer) {
          case (?indexer) {
            indexer.on_transaction(_trx, index);
          };
          case (null) {};
        };
      };
    };
    trxResult;
  };

  /////////////////// Deploy indexer //////////////////

  func deploy_indexer() : async Principal {
    switch _indexer {
      case null {
        ExperimentalCycles.add<system>(2_000_000_000_000);
        let indexer = await Indexer.Indexer();
        _indexer := ?indexer;
        let indexerCanisterId = Principal.fromActor(indexer);
        // Agregamos al _owner como controlador del indexer
        await IC.addController(Principal.fromActor(indexer), _owner);
        indexerCanisterId;
      };
      case (?pid) { Principal.fromActor(pid) };
    };
  };

  //////////////// Initial Distribution ////////////////

  func distribution(allocations : [Tokenomic.Allocation]) : async { #Ok; #Err : Text } {
    if (distributionComplete) { return #Err("Distribution is already complete") };
    for (distItem in allocations.vals()) {
      vestingSchemes := Array.tabulate<{ categoryName : Text; scheme : Tokenomic.VestingScheme; ended : Bool }>(
        vestingSchemes.size() + 1,
        func i = if (i == vestingSchemes.size()) {
          { categoryName = distItem.categoryName; scheme = distItem.vestingScheme; ended = false };
        } else {
          vestingSchemes[i];
        },
      );
      for ({ allocatedAmount; hasVesting; owner } in distItem.holders.vals()) {
        let mintArgs = {
          to : Types.Account = { owner; subaccount = null };
          amount = allocatedAmount;
          memo = null;
          created_at_time = ?Nat64.fromNat(Int.abs(now()));
        };
        let minting_account = get_icrc1_state().minting_account;
        ignore await* icrc1().mint(minting_account.owner, mintArgs);

        // Mapeo holder/amount para permitir o denegar transacciones durante periodo de vesting
        if (Map.has<Principal, { value : Nat; schemeIndex : Nat }>(holdersVesting, phash, owner)) {
          return #Err("Hay un mismo principal en mas de una categoría de distribución");
        };

        if (hasVesting) {
          ignore Map.put<Principal, { value : Nat; schemeIndex : Nat }>(
            holdersVesting,
            phash,
            owner,
            { value = allocatedAmount; schemeIndex = vestingSchemes.size() - 1 },
          );
        };
      };
    };
    distributionComplete := true;
    distributionTimestamp := now();
    #Ok;
  };

  ////// Deploy de canister indexer y distribucion inicial  ///////

  public shared ({ caller }) func initialize() : async { #Ok; #Err : Text } {
    assert (caller == _owner);
    let indexerCanisterId = await deploy_indexer();
    print("Indexer canister deployed at " # debug_show (indexerCanisterId));
    switch ledgerArgs {
      case (#Init(_)) {
        switch (customArgs.distribution) {
          case (?dist) {
            return await distribution(dist.allocations);
          };
          case (_) { return #Ok };
        };
      };
      case (_) { return #Ok };
    };

  };

  /////////////////////// vesting validations /////////////////////

  stable let holdersVesting = Map.new<Principal, { value : Nat; schemeIndex : Nat }>();

  func calculateBlockedAmount(p : Principal) : Nat {
    switch (Map.get<Principal, { value : Nat; schemeIndex : Nat }>(holdersVesting, phash, p)) {
      case null { return 0 };
      case (?{ value; schemeIndex }) {
        if (vestingSchemes[schemeIndex].ended) {
          return 0;
        } else {
          switch (vestingSchemes[schemeIndex].scheme) {
            case (#timeBasedVesting(scheme)) {
              let { period } = getCurrentPeriodVesting(scheme);

              if (period == 0) {
                return value;
              } else {
                return value - ((value * period) / Nat8.toNat(scheme.intervalQty));
              };
            };
            case (_) { return 0 } // Otros esquemas a implementar
          };
          value;
        };
      };
    };
  };

  func checkVestingRestrictions(caller : Principal, trx : ICRC1.TransferArgs) : {
    #Ok;
    #Err : Types.TransferError;
  } {
    // TODO Se puede agregar un valor aleatorio y acotado a cada usuario con vesting para evitar
    // que todos los usuarios de una misma categoria queden con sus tokens liberados al mismo tiempo
    let balance = icrc1().balance_of({ owner = caller; subaccount = null });
    let blocked_amount = calculateBlockedAmount(caller);
    if (blocked_amount == 0) { return #Ok };
    if (balance >= blocked_amount + trx.amount + icrc1().fee()) {
      #Ok;
    } else {
      #Err(#VestingRestriction({ blocked_amount; available_amount = balance - blocked_amount }));
    };
  };

  // Custom functions

  public query func indexerCanister() : async ?Principal {
    switch (_indexer) {
      case null { null };
      case (?indexer) {
        ?Principal.fromActor(indexer);
      };
    };
  };

  public shared query ({ caller }) func balance(subaccount : ?Blob) : async Nat {
    icrc1().balance_of({ owner = caller; subaccount });
  };

  // public shared ({ caller }) func available(): async Nat {
  //   icrc1().balance_of({ owner = caller; subaccount = null }) - get;
  // };

  func getCurrentPeriodVesting(scheme : Tokenomic.TimeBasedVesting) : { period : Nat; cliff : Int } {
    let currentTime = Int.abs(now());
    let cliff = switch (scheme.cliff) {
      case null { distributionTimestamp };
      case (?c) { c * 1_000_000_000 };
    };
    var period = Int.abs(
      if (currentTime < cliff) { 0 } else {
        let p = ((currentTime - cliff) / (scheme.intervalDuration * NanosPerDay) + 1);
        if (p <= Nat8.toNat(scheme.intervalQty)) { p } else { Nat8.toNat(scheme.intervalQty) };
      }
    );
    return { period; cliff };
  };

  public query func vestingsStatus() : async [Tokenomic.VestingState] {
    let states = Buffer.fromArray<Tokenomic.VestingState>([]);
    for (vst in vestingSchemes.vals()) {
      switch (vst.scheme) {
        case (#timeBasedVesting(scheme)) {
          let { period; cliff } = getCurrentPeriodVesting(scheme);

          let vState : Tokenomic.VestingState = {
            categoryName = vst.categoryName;
            currentPeriodOverTotal = (period, Nat8.toNat(scheme.intervalQty));
            isBeforeCliff = period == 0;
            isFullyVested = period == Nat8.toNat(scheme.intervalQty);
            nextReleaseTime = if (period == Nat8.toNat(scheme.intervalQty)) { null } else {
              ?(cliff + period * scheme.intervalDuration * NanosPerDay);
            };
            remainingAmount = 0;  // TODO
            vestedAmount = 0;     // TODO
          };
          states.add(vState);

        };
        case _ {};
      };
    };
    Buffer.toArray(states);
  };

  /// Functions for the ICRC1 token standard

  public shared query func is_ledger_ready() : async Bool {
    isLedgerReady;
  };

  public shared query func icrc1_name() : async Text {
    icrc1().name();
  };

  public shared query func icrc1_symbol() : async Text {
    icrc1().symbol();
  };

  public shared query func icrc1_decimals() : async Nat8 {
    icrc1().decimals();
  };

  public shared query func icrc1_fee() : async ICRC1.Balance {
    icrc1().fee();
  };

  public shared query func icrc1_metadata() : async [ICRC1.MetaDatum] {
    icrc1().metadata();
  };

  public shared query func icrc1_total_supply() : async ICRC1.Balance {
    icrc1().total_supply();
  };

  public shared query func icrc1_minting_account() : async ?ICRC1.Account {
    ?icrc1().minting_account();
  };

  public shared query func icrc1_balance_of(args : ICRC1.Account) : async ICRC1.Balance {
    icrc1().balance_of(args);
  };

  public shared query func icrc1_supported_standards() : async [ICRC1.SupportedStandard] {
    icrc1().supported_standards();
  };

  public shared ({ caller }) func icrc1_transfer(args : ICRC1.TransferArgs) : async Types.TransferResult {
    switch (checkVestingRestrictions(caller, args)) {
      case (#Err(e)) { return #Err(e) };
      case _ {};
    };
    let trxResult = await* icrc1().transfer(caller, args);
    ignore pushTrxToIndexer(trxResult);
    trxResult;
  };

  public shared ({ caller }) func mint(args : ICRC1.Mint) : async ICRC1.TransferResult {
    let trxResult = await* icrc1().mint(caller, args);
    await pushTrxToIndexer(trxResult);
  };

  public shared ({ caller }) func burn(args : ICRC1.BurnArgs) : async ICRC1.TransferResult {
    let trxResult = await* icrc1().burn(caller, args);
    await pushTrxToIndexer(trxResult);
  };

  public query func icrc2_allowance(args : ICRC2.AllowanceArgs) : async ICRC2.Allowance {
    return icrc2().allowance(args.spender, args.account, false);
  };

  public shared ({ caller }) func icrc2_approve(args : ICRC2.ApproveArgs) : async Types.ApproveResponse {
    switch (checkVestingRestrictions(caller, { args with to = args.spender } : ICRC1.TransferArgs)) {
      case (#Err(#VestingRestriction(e))) { return #Err(#VestingRestriction(e)) };
      case _ {};
    };
    await* icrc2().approve(caller, args);
  };

  public shared ({ caller }) func icrc2_transfer_from(args : ICRC2.TransferFromArgs) : async ICRC2.TransferFromResponse {
    switch (checkVestingRestrictions(args.from.owner, { args with from_subaccount = args.from.subaccount } : ICRC1.TransferArgs)) {
      case (#Err(e)) { return #Err(e) };
      case _ {};
    };
    let trxResult = await* icrc2().transfer_from(caller, args);
    switch trxResult {
      case (#Err(_)) { trxResult };
      case (#Ok(index)) { await pushTrxToIndexer(#Ok(index)) };
    };
  };

  public query func getTransactionRange(start : Nat, _end : ?Nat) : async [ICRC1.Transaction] {
    let local_transactions = icrc1().get_local_transactions();
    let end = switch _end {
      case null {
        Vec.size(local_transactions);
      };
      case (?val) {
        if (val > Vec.size(local_transactions)) { Vec.size(local_transactions) } else { val };
      };
    };
    Array.tabulate<ICRC1.Transaction>(end - start, func i = Vec.get(local_transactions, start + i));
  };

  // Deposit cycles into this canister.
  public shared func deposit_cycles() : async () {

    let amount = ExperimentalCycles.available();
    let accepted = ExperimentalCycles.accept<system>(amount);
    assert (accepted == amount);
  };
};
