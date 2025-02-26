
# dfx deploy icrc1_ledger_canister --argument '( variant {
#     Init = record {
#       decimals = opt (8 : nat8);
#       token_symbol = "TOUR";
#       transfer_fee = 10_000 : nat;
#       metadata = vec {
#         record { 
#           "icrc1:logo";
#           variant {Text = "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxMDAgMTAwIiB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCI+CiAgICA8Y2lyY2xlIGN4PSI1MCIgY3k9IjUwIiByPSI0MCIgZmlsbD0iYmx1ZSI+CiAgICAgICAgPGFuaW1hdGUgYXR0cmlidXRlTmFtZT0iciIgZnJvbT0iNDAiIHRvPSIyMCIgZHVyPSIxcyIgcmVwZWF0Q291bnQ9ImluZGVmaW5pdGUiIC8+CiAgICA8L2NpcmNsZT4KPC9zdmc+Cgo="
#           }
#         };
#         record { "icrc1:decimals"; variant { Nat = 8 : nat } };
#         record { "icrc1:name"; variant { Text = "$TOUR" } };
#         record { "icrc1:symbol"; variant { Text = "TOUR" } };
#         record { "icrc1:fee"; variant { Nat = 10_000 : nat } };
#         record { "icrc1:max_memo_length"; variant { Nat = 80 : nat } };
#       };
#       minting_account = record {
#         owner = principal "y77j5-4vnxl-ywos7-qjtcr-6iopc-i2ql2-iwoem-ehvwk-wruju-fr7ib-mae";
#         subaccount = null;
#       };
#       initial_balances = vec {
#         record {
#           record {
#             owner = principal "zpdk5-e6ec5-izoeb-uzhwy-rl2ot-4ag42-im6yv-itg3x-inywa-j3bae-tqe";
#             subaccount = null;
#           };
#           1_000_000_000_000_000 : nat;
#         };
#         record {
#           record {
#             owner = principal "xigzi-mf2wo-xch5n-4dlsf-5tq6n-pke7b-7w2tx-2fv4h-l3yvi-3ycr2-pae";
#             subaccount = null;
#           };
#           500_000_000_000_000: nat;
#         }
#       };
#       fee_collector_account = opt record {
#         owner = principal "epvyw-ddnza-4wy4p-joxft-ciutt-s7pji-cfxm3-khwlb-x2tb7-uo7tc-xae";
#         subaccount = null;
#       };
#       archive_options = record {
#         num_blocks_to_archive = 1_000 : nat64;
#         max_transactions_per_response = null;
#         trigger_threshold = 2_000 : nat64;
#         more_controller_ids = opt vec {
#           principal "d2alm-ajpbz-hohks-j3k3y-ulxfm-fegz6-jwopx-d2eu7-3ycil-hnxqa-hae";
#         };
#         max_message_size_bytes = null;
#         cycles_for_archive_creation = opt (10_000_000_000_000 : nat64);
#         node_max_memory_size_bytes = null;
#         controller_id = principal "epvyw-ddnza-4wy4p-joxft-ciutt-s7pji-cfxm3-khwlb-x2tb7-uo7tc-xae";
#       };
#       max_memo_length = null;
#       token_name = "$TOUR";
#       feature_flags = opt record { icrc2 = true };
#     }
#   }
# )'

# dfx deploy icrc1_index_canister --argument '(opt variant {
#   Init = record {
#     ledger_id = principal "br5f7-7uaaa-aaaaa-qaaca-cai";
#     retrieve_blocks_from_ledger_interval_seconds = opt 30
#   }
# })'


########################################################################
# Ejemplo de metadata de ckBTC
#(
#   vec {
#     record {
#       "icrc1:logo";
#       variant {
#         Text = "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTQ2IiBoZWlnaHQ9IjE0NiIgdmlld0JveD0iMCAwIDE0NiAxNDYiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjxyZWN0IHdpZHRoPSIxNDYiIGhlaWdodD0iMTQ2IiByeD0iNzMiIGZpbGw9IiMzQjAwQjkiLz4KPHBhdGggZmlsbC1ydWxlPSJldmVub2RkIiBjbGlwLXJ1bGU9ImV2ZW5vZGQiIGQ9Ik0xNi4zODM3IDc3LjIwNTJDMTguNDM0IDEwNS4yMDYgNDAuNzk0IDEyNy41NjYgNjguNzk0OSAxMjkuNjE2VjEzNS45MzlDMzcuMzA4NyAxMzMuODY3IDEyLjEzMyAxMDguNjkxIDEwLjA2MDUgNzcuMjA1MkgxNi4zODM3WiIgZmlsbD0idXJsKCNwYWludDBfbGluZWFyXzExMF81NzIpIi8+CjxwYXRoIGZpbGwtcnVsZT0iZXZlbm9kZCIgY2xpcC1ydWxlPSJldmVub2RkIiBkPSJNNjguNzY0NiAxNi4zNTM0QzQwLjc2MzggMTguNDAzNiAxOC40MDM3IDQwLjc2MzcgMTYuMzUzNSA2OC43NjQ2TDEwLjAzMDMgNjguNzY0NkMxMi4xMDI3IDM3LjI3ODQgMzcuMjc4NSAxMi4xMDI2IDY4Ljc2NDYgMTAuMDMwMkw2OC43NjQ2IDE2LjM1MzRaIiBmaWxsPSIjMjlBQkUyIi8+CjxwYXRoIGZpbGwtcnVsZT0iZXZlbm9kZCIgY2xpcC1ydWxlPSJldmVub2RkIiBkPSJNMTI5LjYxNiA2OC43MzQzQzEyNy41NjYgNDAuNzMzNSAxMDUuMjA2IDE4LjM3MzQgNzcuMjA1MSAxNi4zMjMyTDc3LjIwNTEgMTBDMTA4LjY5MSAxMi4wNzI0IDEzMy44NjcgMzcuMjQ4MiAxMzUuOTM5IDY4LjczNDNMMTI5LjYxNiA2OC43MzQzWiIgZmlsbD0idXJsKCNwYWludDFfbGluZWFyXzExMF81NzIpIi8+CjxwYXRoIGZpbGwtcnVsZT0iZXZlbm9kZCIgY2xpcC1ydWxlPSJldmVub2RkIiBkPSJNNzcuMjM1NCAxMjkuNTg2QzEwNS4yMzYgMTI3LjUzNiAxMjcuNTk2IDEwNS4xNzYgMTI5LjY0NyA3Ny4xNzQ5TDEzNS45NyA3Ny4xNzQ5QzEzMy44OTcgMTA4LjY2MSAxMDguNzIyIDEzMy44MzcgNzcuMjM1NCAxMzUuOTA5TDc3LjIzNTQgMTI5LjU4NloiIGZpbGw9IiMyOUFCRTIiLz4KPHBhdGggZD0iTTk5LjgyMTcgNjQuNzI0NUMxMDEuMDE0IDU2Ljc1MzggOTQuOTQ0NyA1Mi40Njg5IDg2LjY0NTUgNDkuNjEwNEw4OS4zMzc2IDM4LjgxM0w4Mi43NjQ1IDM3LjE3NUw4MC4xNDM1IDQ3LjY4NzlDNzguNDE1NSA0Ny4yNTczIDc2LjY0MDYgNDYuODUxMSA3NC44NzcxIDQ2LjQ0ODdMNzcuNTE2OCAzNS44NjY1TDcwLjk0NzQgMzQuMjI4NUw2OC4yNTM0IDQ1LjAyMjJDNjYuODIzIDQ0LjY5NjUgNjUuNDE4OSA0NC4zNzQ2IDY0LjA1NiA0NC4wMzU3TDY0LjA2MzUgNDQuMDAyTDU0Ljk5ODUgNDEuNzM4OEw1My4yNDk5IDQ4Ljc1ODZDNTMuMjQ5OSA0OC43NTg2IDU4LjEyNjkgNDkuODc2MiA1OC4wMjM5IDQ5Ljk0NTRDNjAuNjg2MSA1MC42MSA2MS4xNjcyIDUyLjM3MTUgNjEuMDg2NyA1My43NjhDNTguNjI3IDYzLjYzNDUgNTYuMTcyMSA3My40Nzg4IDUzLjcxMDQgODMuMzQ2N0M1My4zODQ3IDg0LjE1NTQgNTIuNTU5MSA4NS4zNjg0IDUwLjY5ODIgODQuOTA3OUM1MC43NjM3IDg1LjAwMzQgNDUuOTIwNCA4My43MTU1IDQ1LjkyMDQgODMuNzE1NUw0Mi42NTcyIDkxLjIzODlMNTEuMjExMSA5My4zNzFDNTIuODAyNSA5My43Njk3IDU0LjM2MTkgOTQuMTg3MiA1NS44OTcxIDk0LjU4MDNMNTMuMTc2OSAxMDUuNTAxTDU5Ljc0MjYgMTA3LjEzOUw2Mi40MzY2IDk2LjMzNDNDNjQuMjMwMSA5Ni44MjEgNjUuOTcxMiA5Ny4yNzAzIDY3LjY3NDkgOTcuNjkzNEw2NC45OTAyIDEwOC40NDhMNzEuNTYzNCAxMTAuMDg2TDc0LjI4MzYgOTkuMTg1M0M4NS40OTIyIDEwMS4zMDYgOTMuOTIwNyAxMDAuNDUxIDk3LjQ2ODQgOTAuMzE0MUMxMDAuMzI3IDgyLjE1MjQgOTcuMzI2MSA3Ny40NDQ1IDkxLjQyODggNzQuMzc0NUM5NS43MjM2IDczLjM4NDIgOTguOTU4NiA3MC41NTk0IDk5LjgyMTcgNjQuNzI0NVpNODQuODAzMiA4NS43ODIxQzgyLjc3MiA5My45NDM4IDY5LjAyODQgODkuNTMxNiA2NC41NzI3IDg4LjQyNTNMNjguMTgyMiA3My45NTdDNzIuNjM4IDc1LjA2ODkgODYuOTI2MyA3Ny4yNzA0IDg0LjgwMzIgODUuNzgyMVpNODYuODM2NCA2NC42MDY2Qzg0Ljk4MyA3Mi4wMzA3IDczLjU0NDEgNjguMjU4OCA2OS44MzM1IDY3LjMzNEw3My4xMDYgNTQuMjExN0M3Ni44MTY2IDU1LjEzNjQgODguNzY2NiA1Ni44NjIzIDg2LjgzNjQgNjQuNjA2NloiIGZpbGw9IndoaXRlIi8+CjxkZWZzPgo8bGluZWFyR3JhZGllbnQgaWQ9InBhaW50MF9saW5lYXJfMTEwXzU3MiIgeDE9IjUzLjQ3MzYiIHkxPSIxMjIuNzkiIHgyPSIxNC4wMzYyIiB5Mj0iODkuNTc4NiIgZ3JhZGllbnRVbml0cz0idXNlclNwYWNlT25Vc2UiPgo8c3RvcCBvZmZzZXQ9IjAuMjEiIHN0b3AtY29sb3I9IiNFRDFFNzkiLz4KPHN0b3Agb2Zmc2V0PSIxIiBzdG9wLWNvbG9yPSIjNTIyNzg1Ii8+CjwvbGluZWFyR3JhZGllbnQ+CjxsaW5lYXJHcmFkaWVudCBpZD0icGFpbnQxX2xpbmVhcl8xMTBfNTcyIiB4MT0iMTIwLjY1IiB5MT0iNTUuNjAyMSIgeDI9IjgxLjIxMyIgeTI9IjIyLjM5MTQiIGdyYWRpZW50VW5pdHM9InVzZXJTcGFjZU9uVXNlIj4KPHN0b3Agb2Zmc2V0PSIwLjIxIiBzdG9wLWNvbG9yPSIjRjE1QTI0Ii8+CjxzdG9wIG9mZnNldD0iMC42ODQxIiBzdG9wLWNvbG9yPSIjRkJCMDNCIi8+CjwvbGluZWFyR3JhZGllbnQ+CjwvZGVmcz4KPC9zdmc+Cg=="
#       };
#     };
#     record { "icrc1:decimals"; variant { Nat = 8 : nat } };
#     record { "icrc1:name"; variant { Text = "ckBTC" } };
#     record { "icrc1:symbol"; variant { Text = "ckBTC" } };
#     record { "icrc1:fee"; variant { Nat = 10 : nat } };
#     record { "icrc1:max_memo_length"; variant { Nat = 80 : nat } };
#   },
# )
######################################################################
dfx identity new 0000InvNonVesting
dfx identity use 0000InvNonVesting
export InvNonVesting=$(dfx identity get-principal) 

dfx identity new 0000InvVesting
dfx identity use 0000InvVesting
export InvVesting=$(dfx identity get-principal)

dfx identity new 0000Founder01
dfx identity use 0000Founder01
export Founder01=$(dfx identity get-principal)

dfx identity new 0000Founder02
dfx identity use 0000Founder02
export Founder02=$(dfx identity get-principal)

dfx identity new 0000Founder03
dfx identity use 0000Founder03
export Founder03=$(dfx identity get-principal)


dfx identity new 0000Controller
dfx identity use 0000Controller
export Controller=$(dfx identity get-principal)

dfx identity use triourism
export deployer=$(dfx identity get-principal)
export minterCanister=$(dfx canister id icrc1_minter_canister)

timestamp=$(date +%s)
cliffFounders=$((timestamp + 83))   
cliffInvestors=$((timestamp + 120)) 

dfx deploy tour --argument '(
  variant {
    Init = record {
      decimals = 8 : nat8;
      token_symbol = "TOUR";
      transfer_fee = 10_000 : nat;
      metadata = vec {
        record {
          "icrc1:logo";
          variant {
            Text = "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxMDAgMTAwIiB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCI+CiAgICA8Y2lyY2xlIGN4PSI1MCIgY3k9IjUwIiByPSI0MCIgZmlsbD0iYmx1ZSI+CiAgICAgICAgPGFuaW1hdGUgYXR0cmlidXRlTmFtZT0iciIgZnJvbT0iNDAiIHRvPSIyMCIgZHVyPSIxcyIgcmVwZWF0Q291bnQ9ImluZGVmaW5pdGUiIC8+CiAgICA8L2NpcmNsZT4KPC9zdmc+Cgo="
          };
        };
        record { "icrc1:decimals"; variant { Nat = 8 : nat } };
        record { "icrc1:name"; variant { Text = "TOUR" } };
        record { "icrc1:symbol"; variant { Text = "$TOUR" } };
        record { "icrc1:fee"; variant { Nat = 10_000 : nat } };
        record { "icrc1:max_memo_length"; variant { Nat = 32 : nat } };
      };
      minting_account = record {
        owner = principal "'$minterCanister'";
        subaccount = null;
      };
      initial_balances = vec {};
      fee_collector_account = opt record {
        owner = principal "'$minterCanister'";
        subaccount = opt blob "FeeCollector00000000000000000000";
      };
      archive_options = record {
        num_blocks_to_archive = 1_000 : nat64;
        max_transactions_per_response = null;
        trigger_threshold = 2_000 : nat64;
        more_controller_ids = null;
        max_message_size_bytes = null;
        cycles_for_archive_creation = opt (10_000_000_000_000 : nat64);
        node_max_memory_size_bytes = null;
        controller_id = principal "'$Controller'";
      };
      max_supply = null;
      max_memo_length = opt (32 : nat);
      token_name = "$TOUR";
      feature_flags = opt record { icrc2 = true };
    }
  },
  record {
    metadata = vec {};
    min_burn_amount = null;
    max_supply = null;
    distribution = opt record {
      allocations = vec {
        record {
          categoryName = "Founders";
          holders = vec {
            record {
              owner = principal "'$Founder01'";
              hasVesting = true;
              allocatedAmount = 20_000_000_000 : nat;
            };
            record {
              owner = principal "'$Founder02'";
              hasVesting = true;
              allocatedAmount = 20_000_000_000 : nat;
            };
            record {
              owner = principal "'$Founder03'";
              hasVesting = true;
              allocatedAmount = 30_000_000_000 : nat;
            };
          };
          vestingScheme = variant {
            timeBasedVesting = record {
              cliff = opt ('"$cliffFounders"');
              intervalDuration = 23;
              intervalQty = 12 : nat8;
            }
          }
        };
        record {
          categoryName = "Investors";
          holders = vec {
            record {
              owner = principal "'$InvVesting'";
              hasVesting = true;
              allocatedAmount = 450_000_000_000 : nat;
            };
            record {
              owner = principal "'$InvNonVesting'";
              hasVesting = false;
              allocatedAmount = 480_000_000_000 : nat;
            };

          };
          vestingScheme = variant { 
            timeBasedVesting = record {
              cliff = opt ('"$cliffInvestors"');
              intervalDuration = 27;
              intervalQty = 6 : nat8;
            }
          }
        };
      };
    };
  },
)'

dfx canister call tour initialize
