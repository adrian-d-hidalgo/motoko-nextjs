import Nat8 "mo:base/Nat8";

module {

    public type InitialDistribution = {
        allocations : [Allocation];
    };

    public type Allocation = {
        categoryName : Text;
        holders : [InitialHolder];
        vestingScheme : VestingScheme;
    };

    public type VestingScheme = {
        #timeBasedVesting : TimeBasedVesting;
        #mintBasedVesting : MintBasedVesting;
    };

    public type VestingState = {
        categoryName: Text;
        isBeforeCliff : Bool;
        isFullyVested : Bool;      // Si ya se liberaron todos los tokens (currentTime >= endTime)
        currentPeriodOverTotal: (Nat, Nat); 
        vestedAmount : Nat;        // Cantidad total liberada hasta ahora
        remainingAmount : Nat;     // Cantidad aún bloqueada
        nextReleaseTime : ?Int;    // Timestamp del próximo release (null si ya terminó)
    };

    public type InitialHolder = {
        owner : Principal;
        allocatedAmount : Nat;
        hasVesting : Bool;
    };

    public type TimeBasedVesting = {
        cliff : ?Int; // Comienzo del periodo de vesting. Si es null se toma la fecha del deploy. Timestamp seg
        // duration : Nat; // Duración del periodo de vesting desde el cliff // comentado por redundante
        // releaseRate : Nat; // Cantidad de tokens a liberar por periodo luego del periodo de vesting. Opcion de nombre maxAmountPerRelease
        // El releaseRate se calcularia como ```amount / (intervalQty + 1)```
        intervalDuration : Nat; // Intervalo de tiempo en dias entre cada liberación
        intervalQty : Nat8; // Cantidad de intervalos. ```duration = intervalQty * releaseInterval```
    };

    public type VestingRule = {
        timeBasedVesting : ?TimeBasedVesting;
        mintBasedVesting : ?MintBasedVesting;
    };

    ///// Revisar regla ////////////////////

    public type MintBasedVesting = {
        triggers : [{ totalSupply : Nat; releaseAmount : Nat }];
        withdrawalRatio : Nat; //relacion entre el totalSupply actual y el maximo que se puede retirar en un solo trigger
    };

    public func mintBasedVestingValidate(mintBasedVesting : MintBasedVesting) : Bool {
        var lastTrigger = { totalSupply = 0; releaseAmount = 0 };
        let ratio = if (mintBasedVesting.withdrawalRatio < 500) {
            500;
        } else {
            mintBasedVesting.withdrawalRatio;
        };
        for (t in mintBasedVesting.triggers.vals()) {
            if (
                t.totalSupply <= lastTrigger.totalSupply or
                t.releaseAmount <= lastTrigger.releaseAmount or
                t.totalSupply < t.releaseAmount * ratio
            ) {
                return false;
            };
            lastTrigger := t;
        };
        true;
    };

};
