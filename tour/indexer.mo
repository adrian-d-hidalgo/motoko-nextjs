import Principal "mo:base/Principal";
import Map "mo:map/Map";
// import { phash } "mo:map/Map";
// import TrieMap "mo:base/TrieMap";

import ICRC1 "mo:icrc1-mo/ICRC1";
import ICRC2 "mo:icrc2-mo/ICRC2";
import { print } "mo:base/Debug";
import Array "mo:base/Array";

/*
    get_blocks : shared query GetBlocksRequest -> async GetBlocksResponse;
    get_fee_collectors_ranges : shared query () -> async FeeCollectorRanges;
    list_subaccounts : shared query ListSubaccountsArgs -> async [SubAccount];
    status : shared query () -> async Status;
*/


shared ({caller = LedgerCanisterId}) actor class Indexer() = this {

    let ledger = actor( Principal.toText(LedgerCanisterId) ): actor {
        icrc1_decimals: shared query () -> async Nat8;
        icrc1_fee: shared query () -> async Nat;
        // icrc1_metadata: shared query () -> async [ICRC1.MetaDatum];
        // icrc1_total_supply: shared query () -> async ICRC1.Balance;
        icrc1_minting_account: shared query () -> async ?ICRC1.Account;
        icrc1_balance_of: shared query ICRC1.Account -> async ICRC1.Balance;
        icrc1_supported_standards: shared query () -> async [ICRC1.SupportedStandard];
        icrc1_transfer: shared ICRC1.TransferArgs -> async ICRC1.TransferResult;
        mint: shared ICRC1.Mint -> async ICRC1.TransferResult;
        burn: shared ICRC1.BurnArgs -> async ICRC1.TransferResult;
        icrc2_allowance: query ICRC2.AllowanceArgs -> async ICRC2.Allowance;
        icrc2_approve: shared ICRC2.ApproveArgs -> async ICRC2.ApproveResponse;
        icrc2_transfer_from: shared ICRC2.TransferFromArgs -> async ICRC2.TransferFromResponse;
        getTransactionRange: query (Nat, ?Nat) -> async [ICRC1.Transaction];
    };

    type TokenTransferredListener = ICRC1.TokenTransferredListener;
    type Account = {owner: Principal; subaccount: ?Blob};

    stable let accountsTransactions = Map.new<Account, [ICRC1.Transaction]>();
    stable var transactions: [ICRC1.Transaction] = [];

    private func pull_missing_transactions(): async () {
        let _transactionsPulled: [ICRC1.Transaction] = await ledger.getTransactionRange(transactions.size(), null);
        transactions := Array.tabulate<ICRC1.Transaction>(
            transactions.size() + _transactionsPulled.size(), 
            func i = if (i < transactions.size()) { transactions[i] } else { _transactionsPulled[i - transactions.size()] }
        );
        for (trx in _transactionsPulled.vals()) {
            index_transaction(trx)
        };
    };

    private func index_transaction(trx: ICRC1.Transaction) {
        let accounts = switch (trx.kind) {
            case "TRANSFER" {
                switch (trx.transfer) {
                    case null { [] };
                    case (?data) { [data.from, data.to] }
                };
            };
            case "MINT" {

                switch (trx.mint) {
                    case null { [] };
                    case (?data) { [data.to] }
                }
            };
            case "BURN" {
                switch (trx.burn) {
                    case null { [] };
                    case (?data) { [data.from] }
                }
            };
            case _ { [] }
        };
        for (account in accounts.vals() ){
            let trxsPrevious = Map.get<Account, [ICRC1.Transaction]>(accountsTransactions, ICRC1.ahash, account);
            switch (trxsPrevious) {
                case null { 
                    ignore Map.put<Account, [ICRC1.Transaction]>(accountsTransactions, ICRC1.ahash, account, [trx]) 
                };
                case (?trxsPrevious) {
                    let updatedTrxs = Array.tabulate<ICRC1.Transaction>(
                        trxsPrevious.size() + 1, 
                        func i =   if (i == 0) { trx } else { trxsPrevious[i - 1] }
                    );
                    ignore Map.put(accountsTransactions, ICRC1.ahash, account, updatedTrxs) 
                };
            };
        };
    };

    public shared ({ caller }) func on_transaction(trx: ICRC1.Transaction, index: Nat) : () {
        assert( caller == LedgerCanisterId);
        assert( index >= transactions.size());
        if (index == transactions.size()) {
            index_transaction(trx)
        } else {
            await pull_missing_transactions();
        }; 
    };

    public query func get_account_transactions(account: Account): async [ICRC1.Transaction] {
        switch (Map.get<Account, [ICRC1.Transaction]>(accountsTransactions, ICRC1.ahash, account)){
            case null { [] };
            case (?trxs) { trxs };
        };
    };

    public func icrc1_balance_of(a: ICRC1.Account): async ICRC1.Balance{
        await ledger.icrc1_balance_of(a)
    };

    // public query func get_account_transactions({max_results : Nat; start : ?Nat; account : Account}): async GetTransactionsResult{

    // };

    public query func ledger_id(): async Principal{
        LedgerCanisterId
    };



    

}


