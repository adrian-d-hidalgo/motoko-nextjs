#!/bin/bash

run_test() {
    DESCRIPTION="$1"
    EXPECTED="$2"
    COMMAND="$3"

    echo "--------------  $DESCRIPTION  --------------"
    echo "Valor esperado: $EXPECTED"

    # Ejecutar el comando y capturar la salida
    RESULT=$(eval "$COMMAND")

    echo "Valor obtenido: $RESULT"

    # Verificar si el resultado contiene el valor esperado
    if echo "$RESULT" | grep -q "$EXPECTED"; then
        echo -e "\e[32m✔ Test exitoso\e[0m"  # Verde
    else
        echo -e "\e[31m✘ Test fallido\e[0m"  # Rojo
    fi
    echo ""
}

# Configuración de identidades
dfx identity use 0000InvNonVesting
export InvNonVesting=$(dfx identity get-principal) 

dfx identity use 0000InvVesting
export InvVesting=$(dfx identity get-principal)

dfx identity use 0000Founder01
export Founder01=$(dfx identity get-principal)

dfx identity use 0000Founder02
export Founder02=$(dfx identity get-principal)

dfx identity use 0000Founder03
export Founder03=$(dfx identity get-principal)

dfx identity use 0000Minter
export Minter=$(dfx identity get-principal)

dfx identity use 0000FeeCollector
export FeeCollector=$(dfx identity get-principal)

dfx identity use 0000Controller
export Controller=$(dfx identity get-principal)

# Test balance luego de distribución

echo -e "\n\n===== PRUEBAS PREVIAS AL INICIO DE VESTING distribucion con vesting bloqueada =====\n"

run_test "Test total_supply luego de distribución" \
    "(1_000_000_000_000 : nat)" \
    "dfx canister call tour icrc1_total_supply"

# Test usuario con vesting intentando transferir tokens
dfx identity use 0000InvVesting
run_test "Test usuario con vesting quiere transferir 500_000_000 tokens" \
    "(
    variant {
        Err = variant {
        VestingRestriction = record {
            blocked_amount = 450_000_000_000 : nat;
            available_amount = 0 : nat;
        }
        }
    },
    )" \
    "dfx canister call tour icrc1_transfer '(
      record {
        to = record { owner = principal \"$Founder01\"; subaccount = null; };
        fee = null;
        memo = null;
        from_subaccount = null;
        created_at_time = null;
        amount = 500_000_000 : nat;
      },
    )'"

# Test usuario sin vesting realizando transferencia
dfx identity use 0000InvNonVesting
run_test "Test usuario SIN VESTING puede transferir 500_000_000 tokens a founder1" \
    "(variant { Ok = 5 : nat })" \
    "dfx canister call tour icrc1_transfer '(
      record {
        to = record { owner = principal \"$Founder01\"; subaccount = null; };
        fee = null;
        memo = null;
        from_subaccount = null;
        created_at_time = null;
        amount = 500_000_000 : nat;
      },
    )'"

run_test "Verificación de balance de usuario sin vesting luego de la transferencia" \
    "(479_499_990_000 : nat)" \
    "dfx canister call tour icrc1_balance_of '(
      record { owner = principal \"$InvNonVesting\" },
    )'"

run_test "Verificación de balance de founder1  luego de la transferencia" \
    "(20_500_000_000 : nat)" \
    "dfx canister call tour icrc1_balance_of '(
      record { owner = principal \"$Founder01\" },
    )'"

run_test "Verificacion de balance del fee_collector luego de una transaccion" \
    "(10_000 : nat)" \
    "dfx canister call tour icrc1_balance_of '(
      record { owner = principal \"$Minter\"; subaccount = opt blob \"FeeCollector00000000000000000000\"},
    )'"

# Test mint y verificación de balance
dfx identity use 0000Minter
run_test "El minter hace un mint de 2_000_000_000 tokens en favor de founder1" \
    "(variant { Ok = 6 : nat })" \
    "dfx canister call tour mint '(
      record {
        to = record { owner = principal \"$Founder01\"; subaccount = null; };
        memo = null;
        created_at_time = null;
        amount = 2_000_000_000 : nat;
      },
    )'"

run_test "Verificación de balance de founder1" \
    "(22_500_000_000 : nat)" \
    "dfx canister call tour icrc1_balance_of '(
      record { owner = principal \"$Founder01\" },
    )'"

run_test "Check total_supply luego del mint" \
    "(1_002_000_000_000 : nat)" \
    "dfx canister call tour icrc1_total_supply"


# Founder 1 intenta transferir más de lo permitido
dfx identity use 0000Founder01
run_test "Founder 1 quiere transferir 3_000_000_000 a founder 2 (bloqueado por vesting)" \
    "(
        variant {
            Err = variant {
            VestingRestriction = record {
                blocked_amount = 20_000_000_000 : nat;
                available_amount = 2_500_000_000 : nat;
            }
            }
        },
    )" \
    "dfx canister call tour icrc1_transfer '(
      record {
        to = record { owner = principal \"$Founder02\"; subaccount = null; };
        fee = null;
        memo = null;
        from_subaccount = null;
        created_at_time = null;
        amount = 3_000_000_000 : nat;
      },
    )'"

run_test "Founder 1 quiere transferir 2_500_000_000 a founder 2 (bloqueado por vesting)" \
    "(
        variant {
            Err = variant {
            VestingRestriction = record {
                blocked_amount = 20_000_000_000 : nat;
                available_amount = 2_500_000_000 : nat;
            }
            }
        },
    )" \
    "dfx canister call tour icrc1_transfer '(
      record {
        to = record { owner = principal \"$Founder02\"; subaccount = null; };
        fee = null;
        memo = null;
        from_subaccount = null;
        created_at_time = null;
        amount = 2_500_000_000 : nat;
      },
    )'"

run_test "Founder 1 quiere transferir 2_499_990_000 a founder 2 (exitosa)" \
    "(variant { Ok = 7 : nat })" \
    "dfx canister call tour icrc1_transfer '(
      record {
        to = record { owner = principal \"$Founder02\"; subaccount = null; };
        fee = null;
        memo = null;
        from_subaccount = null;
        created_at_time = null;
        amount = 2_499_990_000 : nat;
      },
    )'"

 
echo -e "\n\n============= PRUEBAS DE VESTING PROGRESIVO =============\n"

echo -e "\n============= Verificación del tiempo restante para el siguiente release =============\n"
now=$(date +%s)

#_____________
mapfile -t next_release_entries < <(dfx canister call tour vestingsStatus | grep -E 'categoryName =|nextReleaseTime =' | awk -F '= ' '{print $2}' | sed 's/;//g' | tr -d '"')

min=5000000000000000000
nextCategory=""
now=$(date +%s)
currentCategory=""

# Iterar sobre las entradas extraídas
for ((i=0; i<${#next_release_entries[@]}; i++)); do
    entry="${next_release_entries[i]}"
    
    # Si la entrada es un categoryName, guardarlo temporalmente
    if [[ "$entry" =~ ^[A-Za-z]+$ ]]; then
        currentCategory="$entry"
    
    # Si la entrada es un timestamp, procesarlo
    elif [[ "$entry" != "null" ]]; then
        num=$(echo "$entry" | grep -oP '\d+(_\d+)*' | tr -d '_')

        if [[ -n "$num" && "$num" -lt "$min" ]]; then
            min="$num"
            nextCategory="$currentCategory"
        fi
    fi
done

# Convertir timestamp a segundos
min_seconds=$((min / 1000000000))
secondsWaiting=$((min_seconds - now))

# Imprimir resultados
echo "La proxima liberación de fondos corresponde a la categoria: $nextCategory"
echo "Segundos restantes: $secondsWaiting"



# Función para esperar mostrando cuenta regresiva
wait_with_countdown() {
    local seconds=$1
    echo -e "\n[⏳] Esperando $seconds segundos..."
    while [ $seconds -gt -1 ]; do
        echo -ne " Tiempo restante: $seconds segundos\r"
        sleep 1
        ((seconds--))
    done
    echo -e "\n[✅] Continuando con las pruebas\n"
}

wait_with_countdown $((secondsWaiting))

echo -e "\n\n============= PRUEBAS DE TRANSACCIONES EN CASOS LÍMITE PARA FOUNDERS =============\n"

# Verificar si la próxima categoría es Founders
if [[ "$nextCategory" == "Founders" ]]; then
    echo "La próxima liberación de fondos es para la categoría Founders. Procediendo con las pruebas..."

    # Seleccionar una identidad Founder
    dfx identity use 0000Founder03

    run_test "Founder03 intenta transferir el monto exacto disponible" \
        "(
          variant {
            Err = variant {
              VestingRestriction = record {
                blocked_amount = 27_500_000_000 : nat;
                available_amount = 2_500_000_000 : nat;
              }
            }
          },
        )" \
        "dfx canister call tour icrc1_transfer '(
          record {
            to = record { owner = principal \"$Founder02\"; subaccount = null; };
            fee = null;
            memo = null;
            from_subaccount = null;
            created_at_time = null;
            amount = 2_500_000_000 : nat;
          },
        )'"

    # Intentar transferir justo el valor disponible menos la comisión
    run_test "Founder03 intenta transferir el valor disponible exacto menos la comisión" \
        "(variant { Ok = 8 : nat })" \
        "dfx canister call tour icrc1_transfer '(
          record {
            to = record { owner = principal \"$Founder02\"; subaccount = null; };
            fee = null;
            memo = null;
            from_subaccount = null;
            created_at_time = null;
            amount = 2_490_990_000 : nat;
          },
        )'"    

    
    run_test "Verificación de balance de founder1  luego de la transferencia" \
        "(20_000_000_000 : nat)" \
        "dfx canister call tour icrc1_balance_of '(
        record { owner = principal \"$Founder01\" },
        )'"

    # Verificar el balance del receptor (Founder02) después de la transferencia
    run_test "Verificación de balance de Founder02 después de la transferencia" \
        "(24_990_980_000 : nat" \
        "dfx canister call tour icrc1_balance_of '(
          record { owner = principal \"$Founder02\" },
        )'"

    # Verificar el balance del fee_collector después de la transferencia
    run_test "Verificación de balance del fee_collector después de la transferencia" \
        "(30_000 : nat)" \
        "dfx canister call tour icrc1_balance_of '(
          record { owner = principal \"$Minter\"; subaccount = opt blob \"FeeCollector00000000000000000000\"},
        )'"

else
    echo "La próxima liberación de fondos no es para la categoría Founders. Realizando pruebas para Investors..."

    # Seleccionar una identidad Investor
    dfx identity use 0000InvVesting
    export Investor=$(dfx identity get-principal)

    run_test "Investor intenta transferir un valor por encima del disponible" \
        "(variant { Err = variant { InsufficientFunds = record { balance = $available_balance_investor : nat } } })" \
        "dfx canister call tour icrc1_transfer '(
          record {
            to = record { owner = principal \"$Founder01\"; subaccount = null; };
            fee = null;
            memo = null;
            from_subaccount = null;
            created_at_time = null;
            amount = 50000000001 : nat;
          },
        )'"

    # Intentar transferir justo el valor disponible menos la comisión
    run_test "Investor intenta transferir el valor disponible exacto menos la comisión" \
        "(variant { Ok = 9 : nat })" \
        "dfx canister call tour icrc1_transfer '(
          record {
            to = record { owner = principal \"$Founder01\"; subaccount = null; };
            fee = null;
            memo = null;
            from_subaccount = null;
            created_at_time = null;
            amount = 545454545454554 : nat;
          },
        )'"

¡
    run_test "Verificación de balance disponible de Investor después de la transferencia" \
        "(0 : nat)" \
        "echo $available_balance_investor"

    # Verificar el balance del receptor (Founder01) después de la transferencia
    run_test "Verificación de balance de Founder01 después de la transferencia" \
        "($((available_balance_investor - fee)) : nat" \
        "dfx canister call tour icrc1_balance_of '(
          record { owner = principal \"$Founder01\" },
        )'"

    # Verificar el balance del fee_collector después de la transferencia
    run_test "Verificación de balance del fee_collector después de la transferencia" \
        "($((10_000 + fee)) : nat)" \
        "dfx canister call tour icrc1_balance_of '(
          record { owner = principal \"$Minter\"; subaccount = opt blob \"FeeCollector00000000000000000000\"},
        )'"
fi

mapfile -t next_release_entries < <(dfx canister call tour vestingsStatus | grep -E 'categoryName =|nextReleaseTime =' | awk -F '= ' '{print $2}' | sed 's/;//g' | tr -d '"')

min=5000000000000000000
nextCategory=""
now=$(date +%s)
currentCategory=""

# Iterar sobre las entradas extraídas
for ((i=0; i<${#next_release_entries[@]}; i++)); do
    entry="${next_release_entries[i]}"
    
    # Si la entrada es un categoryName, guardarlo temporalmente
    if [[ "$entry" =~ ^[A-Za-z]+$ ]]; then
        currentCategory="$entry"
    
    # Si la entrada es un timestamp, procesarlo
    elif [[ "$entry" != "null" ]]; then
        num=$(echo "$entry" | grep -oP '\d+(_\d+)*' | tr -d '_')

        if [[ -n "$num" && "$num" -lt "$min" ]]; then
            min="$num"
            nextCategory="$currentCategory"
        fi
    fi
done

# Convertir timestamp a segundos
min_seconds=$((min / 1000000000))
secondsWaiting=$((min_seconds - now))

# Imprimir resultados
echo "La proxima liberación de fondos corresponde a la categoria: $nextCategory"
echo "Segundos restantes: $secondsWaiting"

wait_with_countdown $((secondsWaiting + 1))


