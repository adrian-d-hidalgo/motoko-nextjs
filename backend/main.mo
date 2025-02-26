import Prim "mo:⛔";
import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import List "mo:base/List";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat64 "mo:base/Nat64";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import { now } "mo:base/Time";
import { print } "mo:base/Debug";

import Map "mo:map/Map";
import Set "mo:map/Set";
import { phash; nhash; n32hash; thash } "mo:map/Map";
import Indexer_icp "./indexer_icp_token";
import AccountIdentifier "mo:account-identifier";
import IC "ic:aaaaa-aa";

import Minter "../tour/minter-canister";

import Types "types";
import msg "constants";

shared ({ caller = DEPLOYER }) actor class Triourism () = this {

    type User = Types.User;
    type HostUser =Types.HostUser;
    type UserData = Types.UserData;
    type SignUpResult = Types.SignUpResult;
    type Calendary = Types.Calendary;
    type Reservation = Types.Reservation;
    type HousingId = Nat;
    type ReviewId = Nat;
    type Review = Types.Review;
    type Housing = Types.Housing;
    type HousingTypeInit = Types.HousingTypeInit;
    type HousingType = Types.HousingType;
    type HousingResponse = Types.HousingResponse;
    type HousingPreview = Types.HousingPreview;
    type HousingCreateData = Types.HousingCreateData;
    type TransactionParams = Types.TransactionParams;
    type DataTransaction = Types.DataTransaction;
    type TransactionResponse = Types.TransactionResponse;

    type UpdateResult = Types.UpdateResult;
    type ResultHousingPaginate = {#Ok: {array: [HousingPreview]; hasNext: Bool}; #Err: Text};
    type RewardRatio = {
        #ICP_DIVIDES_TOUR: Nat; // Reward = Ammount * Relación. Ejemplo para ICPvTourRewardRatio = #ICP_DIVIDES_TOUR(2): txAmount = 100 ICP -> recompenza = 200 Tour
        #TOUR_DIVIDES_ICP: Nat; // Reward = Ammount / Relación. Ejemplo para ICPvTourRewardRatio = #TOUR_DIVIDES_ICP(2): txAmount = 100 ICP -> recompenza = 50 Tour
    };

  
    // stable let DEPLOYER = caller;
    let NULL_ADDRESS = "aaaaa-aa";

    stable var TourMinterCanister: Minter.Minter = actor(NULL_ADDRESS);
    stable var TourLedgerCanisterID = NULL_ADDRESS;

    // /////////////// WARNING modificar estas variables en produccion a los valores reales  ////
    let nanoSecPerDay = 30 * 1_000_000_000;             // Test Transcurso acelerado de los dias
    // let nanoSecPerDay = 86400 * 1_000_000_000;       // Valor real de nanosegundos en un dia
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    ////////////////////////////////// Global Configuration Parameters //////////////////////////////////////

    stable var CancellationFeeCompensateBuyer: Nat64 = 5; // Percentage added to the buyer's refund
    stable var ReservationFee: Nat64 = 10;                // Percentage of the total reservation price
    stable var TimeToPay = 15 * 1_000_000_000;            // Tiempo en nanosegundos para confirmar la reserva mediante pago
    // stable var TimeToPay = 30 * 60 * 1_000_000_000;    // Tiempo sugerido 30 minutos
    stable var MinDaysBeforeCheckinForCancellation = 4;   // Minimo de dias antes del checkin para cancelar una reserva pagando CancellationFeeCompensateBuyer

    stable var ICPvTourRewardRatio: RewardRatio = #TOUR_DIVIDES_ICP(2); // Cambiar por un Nat
    stable var RewardRatio: Nat64 = 1000; // eg. RewardRatio = 1000; -> 1000 USD = 1 Tour
    
    //////////////////////////////// Core Data Structures ///////////////////////
     
    stable let admins = Set.new<Principal>();
    ignore Set.put<Principal>(admins, phash, DEPLOYER);

    stable let users = Map.new<Principal, User>();
    stable let hostUsers = Map.new<Principal, HostUser>();

    stable let housings = Map.new<HousingId, Housing>();
    stable let review = Map.new<ReviewId, Review>();

    stable let reservationsPendingConfirmation = Map.new<Nat, Reservation>();
    stable let reservationsHistory = Map.new<Nat, Reservation>();
    
    stable var lastHousingId = 0;
    stable var lastReviewId = 0;
    stable var lastReservationId = 0;

    stable let referralCodes = Map.new<Nat32, Types.ReferralBook>();

    // Prueba Amenidades dinamicas
    stable var amenities: [Text] = Types.amenitiesArray;

    public shared ({ caller }) func addAmenities(a: Text): async (){
        assert(isAdmin(caller));
        // TODO Normalizar cadenas de texto y evitar duplicados
        let setAmenities = Set.fromIter<Text>(amenities.vals(), thash);
        ignore Set.put<Text>(setAmenities, thash, a);
        amenities := Set.toArray<Text>(setAmenities);
        // TODO Modificar encodedAmenities en cada housing
    };

    ///////////////////////////////////// Login Update functions ////////////////////////////////////////

    public shared ({ caller }) func signUpAsUser(data: Types.SignUpData) : async SignUpResult {
        if(Principal.isAnonymous(caller)) { return #Err(msg.Anonymous) };
        if (Map.has<Principal, User>(users,phash, caller )){
            return #Err("The caller is linked to an existing User Host")
        };
        let user = Map.get(users, phash, caller);
        switch user {
            case (?User) { #Err("User already exists") };
            case null {

                let referralProcess = putRefered(data.referralBy, caller, #User(#Level1));
                if (referralProcess){
                    let newUser: User = {
                        data with
                        verified = true;
                        reviewsIssued = List.nil<Nat>();    //Reservation IDs in reservationsPendingConfirmation
                        reservations = List.nil<Nat>();     //Reservation IDs in reservationsHistory
                        score = 0;
                    };
                    ignore Map.put(users, phash, caller, newUser);
                    #Ok( newUser );
                } else {
                    #Err("Invalid referral code")
                }
            };
        };
    };

    public shared ({ caller }) func signUpAsHost(data: Types.SignUpData) : async SignUpResult {
        if(Principal.isAnonymous(caller)) { return #Err(msg.Anonymous) };
        if (Map.has<Principal, User>(users,phash, caller )){
            return #Err("The caller is linked to an existing User")
        };
        let hostUser = Map.get(hostUsers, phash, caller);
        switch hostUser {
            case (?User) { #Err("Host User already exists") };
            case null {
                let referralProcess = putRefered(data.referralBy, caller, #User(#Level1));
                if (referralProcess){
                    let newHostUser: HostUser = {
                        data with
                        verified = true;
                        score = 0;
                        housingIds = List.nil<Nat>();
                        housingTypes =  Map.new<Text, HousingType>();
                    };
                    ignore Map.put(hostUsers, phash, caller, newHostUser);
                    #Ok(newHostUser);
                } else {
                    #Err("Invalid referral code")
                }
            };
        };
    };

    public shared query ({ caller }) func loginAsUser(): async {#Ok: UserData; #Err} {
        let user = Map.get<Principal, User>(users, phash, caller); 
        switch user {
            case null { #Err() };
            case ( ?u ) { #Ok(u)}
        };
    };

    public shared query ({ caller }) func loginAsHost(): async {#Ok: UserData; #Err} {
        let hostUser = Map.get<Principal, HostUser>(hostUsers, phash, caller); 
        switch hostUser {
            case null { #Err() };
            case ( ?u ) { #Ok(u)}
        };
    };

    public shared ({ caller }) func getMyReferralCode(): async Nat32 {
        let code = (Principal.hash(caller));
        let referralBook = Map.get<Nat32, Types.ReferralBook>(referralCodes, n32hash, code);
        switch referralBook {
            case null {
                let book: Types.ReferralBook = {
                    owner = caller; 
                    refereds: [Types.Refered] = [];
                };
                ignore Map.put<Nat32, Types.ReferralBook>(referralCodes, n32hash, code, book);
            };
            case _ {}
        };  
        code
    };

    public shared ({ caller }) func getMyReferralBook(): async ?Types.ReferralBook{
        Map.get<Nat32, Types.ReferralBook>(referralCodes, n32hash, Principal.hash(caller));
    };

    func putRefered(code: ?Nat32, user: Principal, kind: Types.ReferalKind): Bool {
        switch (code) {
            case null { true };
            case ( ?code ) {
                let referralBook = Map.get<Nat32, Types.ReferralBook>(referralCodes, n32hash, code);
                switch referralBook {
                    case null { false };
                    case (?referralBook) {
                        let refered = { date = now(); user; kind };
                        let refereds = Prim.Array_tabulate<Types.Refered>(
                            referralBook.refereds.size() +1,
                            func x = if( x == 0 ) { refered } else { referralBook.refereds[x -1]}
                        );
                        ignore Map.put<Nat32, Types.ReferralBook>(
                            referralCodes, 
                            n32hash, 
                            code,
                            {referralBook with refereds }
                        );
                        true
                    }
                };
            }
        }   
    };


    //////////////////////////////// CRUD Data User ///////////////////////////////////

    public shared ({ caller }) func editProfile(data: Types.SignUpData): async {#Ok; #Err}{
        let user = Map.get<Principal, User>(users, phash, caller);
        switch user {
            case null { #Err };
            case (?user){
                ignore Map.put<Principal, User>(users, phash, caller, { user with data});
                #Ok
            };
        };
    };

    ///////////////////////////// Private functions ///////////////////////////////////
    func isAdmin(p: Principal): Bool { Set.has<Principal>(admins, phash, p) };

    func addressEqual(a: Types.Location, b: Types.Location ) : Bool {
        a.country == b.country and
        a.city == b.city and
        a.neighborhood == b.neighborhood and
        a.zipCode == b.zipCode and
        a.externalNumber == b.externalNumber and
        a.internalNumber == b.internalNumber
    };

    let NULL_LOCATION: Types.Location = {
        country = "";
        city = ""; 
        neighborhood = ""; 
        zipCode = 0; street = "";  
        externalNumber = 0; 
        internalNumber = 0;
        geolocation = null;
    };

    let defaultHousinValues = {
        active: Bool = false;
        rules: [Types.Rule] = [];
        price: ?Types.Price = null;
        checkIn: Nat = 15;
        checkOut: Nat = 12;
        address: Types.Location = NULL_LOCATION;
        properties: ?HousingType = null;
        housingType: ?Text = null;
        amenities = null;
        encodedAmenities: Nat64 = 0;
        encodedAmenities2: Nat64 = 0;
        reviews = List.nil<Nat>();
    };

    ///////////////////////////  Admins functions /////////////////////////////////

    public shared ({ caller }) func addAdmin(p: Principal): async  {#Ok; #Err} {
        if(not isAdmin(caller)){ 
            #Err
        } else{
            ignore Set.put<Principal>(admins, phash, p);
            #Ok
        }
    };

    public shared ({ caller }) func removeAdmin(p: Principal): async {#Ok; #Err} {
        if(caller != DEPLOYER){
            #Err;
        } else {
            ignore Set.remove<Principal>(admins, phash, p);
            #Ok
        } 
    };
    public shared ({ caller }) func settings(): async ?Types.Settings{
        if(not isAdmin(caller)){ return null };
        ?{
            cancellationFeeCompensateBuyer =  CancellationFeeCompensateBuyer;
            reservationFee = ReservationFee;
            timeToPay = TimeToPay;
            minDaysBeforeCheckinForCancellation = MinDaysBeforeCheckinForCancellation;
        }
    };

    public shared ({ caller }) func setMinter(m: Principal): async {#Ok; #Err: Text} {
        if(not isAdmin(caller)) { return #Err(msg.NotAdmin) };
        TourMinterCanister := actor(Principal.toText(m));
        TourLedgerCanisterID := Principal.toText(await TourMinterCanister.getLedgerCanisterId());
        #Ok
    };

    public shared ({ caller }) func getMinterCanisterId(): async Principal {
        if(not isAdmin(caller)) { return Principal.fromText(NULL_ADDRESS) };
        Principal.fromActor(TourMinterCanister);   
    };

    public shared ({ caller }) func getUserTourBalance(subaccount: ?Blob): async Nat {
        if(TourLedgerCanisterID != NULL_ADDRESS){
            let ledger = actor(TourLedgerCanisterID): actor {
                icrc1_balance_of : shared {owner: Principal; subaccount: ?Blob} -> async Nat
            };
            return await ledger.icrc1_balance_of({owner = caller; subaccount});
        };
        0
    };

    public shared ({ caller }) func setICPvTourRewardRatio(ratio: RewardRatio): async {#Ok; #Err}{
        if(not isAdmin(caller)) { return #Err };
        ICPvTourRewardRatio := ratio;
        #Ok
    };

    public shared ({ caller }) func serRewardRatio(v: Nat64): async {#Ok; #Err}{
        if(not isAdmin(caller)) { return #Err };
        RewardRatio := v;
        #Ok
    };

    public shared ({ caller }) func updateSettings(config: Types.Settings): async Bool{
        if(not isAdmin(caller)){ return false };
        CancellationFeeCompensateBuyer := config.cancellationFeeCompensateBuyer;
        ReservationFee := config.reservationFee;
        TimeToPay := config.timeToPay;
        MinDaysBeforeCheckinForCancellation := config.minDaysBeforeCheckinForCancellation;
        true

    };
   
    /////////////////////////// Admin functions ////////////////////////////////////////////// 
    /////////////////////////////// Verification process /////////////////////////////////////
    // TODO actualmente todos los usuarios se inicializan como verificados

    // func userIsVerificated(u: Principal): Bool {
    //     let user = Map.get<Principal,User>(users, phash, u);
    //     switch user{
    //         case null { false };
    //         case (?user) { user.verified};
    //     };
    // };

    //////////////////////////////// CRUD Housing ////////////////////////////////////////////

    public shared ({ caller }) func createHousing(dataInit: HousingCreateData): async {#Ok: Nat; #Err: Text} {
        let hostUser = Map.get<Principal, HostUser>(hostUsers, phash, caller);
        switch hostUser {
            case null {#Err(msg.NotHostUser)};
            case (?hostUser) {

                lastHousingId += 1;
                let newHousing: Housing = {
                    dataInit and 
                    defaultHousinValues with
                    housingId = lastHousingId;
                    owner = caller;
                    calendary = {dayZero = now(); reservations = []};
                    reservationsPending = [];
                    unavailability = { busy = []; pending = [] };
                };
                let housingIdsUser =  List.push<Nat>(lastHousingId, hostUser.housingIds);
                ignore Map.put<Principal, HostUser>(hostUsers, phash, caller, {hostUser with housingIds = housingIdsUser});
                ignore Map.put<HousingId, Housing>(housings, nhash, lastHousingId, newHousing );
                #Ok(lastHousingId)
            }
        }
    };

    func isPublishable(housing: Housing): Bool {
        (housing.price != null) and
        (not addressEqual(housing.address, NULL_LOCATION)) and
        (housing.properties != null)
    };

    public shared ({ caller }) func publishHousing(housingId: HousingId): async {#Ok; #Err: Text}{
        let hostUser = Map.get<Principal, HostUser>(hostUsers, phash, caller);
        switch hostUser {
            case null { #Err(msg.NotUser)};
            case ( ?hostUser ) {
                let housing = Map.get<HousingId, Housing>(housings, nhash, housingId);
                switch housing {
                    case null { #Err(msg.NotHousing)};
                    case ( ?housing ) {
                        if(housing.owner != caller) { return #Err(msg.CallerNotHousingOwner)};
                        if(isPublishable(housing)) {
                            ignore Map.put<HousingId, Housing>(housings, nhash, housingId, {housing with active = true});
                            #Ok
                        } else {
                            #Err(msg.IsNotpublishable)
                        }
                    }
                }
            }
        }

    };

    public shared ({ caller }) func addPhotoToHousing({id: HousingId; photo: Blob}): async {#Ok; #Err: Text} {
        let housing = Map.get<HousingId, Housing>(housings, nhash, id);
        switch housing {
            case null {
                #Err(msg.NotHousing)
            };
            case (?housing) {
                if(housing.owner != caller){
                    return #Err(msg.CallerNotHousingOwner)
                };
                let photos = Prim.Array_tabulate<Blob>(
                    housing.photos.size() +1,
                    func i = if(i < housing.photos.size()) {housing.photos[i]} else {photo}
                );
                ignore Map.put<HousingId, Housing>(housings, nhash, id, {housing with photos});
                print(debug_show({housing with photos}));
                #Ok
            }
        }
    };

    public shared ({ caller }) func addThumbnailToHousing({id: HousingId; thumbnail: Blob}): async {#Ok; #Err: Text} {
        let housing = Map.get<HousingId, Housing>(housings, nhash, id);
        switch housing {
            case null {
                #Err(msg.NotHousing)
            };
            case (?housing) {
                if(housing.owner != caller){
                    return #Err(msg.UnauthorizedCaller)
                };
                ignore Map.put<HousingId, Housing>(housings, nhash, id, {housing with thumbnail});
                #Ok
            }
        }
    };

    public shared ({ caller }) func updatePrices({id: HousingId; price_: Types.Price}): async  UpdateResult{
        let housing = Map.get(housings, nhash, id);
        switch housing {
            case null {
                return #Err(msg.NotHousing);
            };
            case (?housing) {
                if(housing.owner != caller){ return #Err(msg.UnauthorizedCaller) };
                ignore Map.put<HousingId, Housing>(housings, nhash, id, {housing with price = ?price_});
                return #Ok
            };
        } 
    };

    public shared ({ caller }) func setRulesForHousing({id: HousingId; rules: [Types.Rule]}): async {#Ok; #Err: Text}{
        let housing = Map.get(housings, nhash, id);
        switch housing {
            case null {
                return #Err(msg.NotHousing);
            };
            case (?housing) {
                if(housing.owner != caller){ return #Err(msg.UnauthorizedCaller) };
                ignore Map.put<HousingId, Housing>(housings, nhash, id, {housing with rules});
                return #Ok
            };
        } 
    };

    public shared ({ caller }) func setMinReservationLeadTime({id: HousingId; hours: Nat}):async  {#Ok; #Err: Text} {
        let housing = Map.get<HousingId, Housing>(housings, nhash, id);
        switch housing {
            case null {
                return #Err(msg.NotHousing);
            };
            case (?housing) {
                if(housing.owner != caller){
                    return #Err(msg.CallerNotHousingOwner);
                };
                ignore Map.put<HousingId, Housing>(
                    housings, 
                    nhash, 
                    id, 
                    {housing with minReservationLeadTimeNanoSeg = hours * 60 * 60 * 1_000_000_000});
                #Ok;
            }

        }
    };

    public shared ({ caller }) func setHousingStatus({id: HousingId; active: Bool}): async {#Ok; #Err: Text}{
        let housing = Map.get<HousingId, Housing>(housings, nhash, id);
        switch housing {
            case null { #Err(msg.NotHousing)};
            case ( ?housing ) {
                if(caller != housing.owner) {
                    return #Err(msg.CallerNotHousingOwner);
                };
                if (not isPublishable(housing)) {
                    return #Err(msg.IsNotpublishable)
                };
                ignore Map.put<HousingId, Housing>(housings, nhash, id, {housing with active});
                #Ok
            }
        }
    };

    public shared ({ caller }) func setChekInCheckOut({housingId: HousingId; checkIn: Nat; checkOut: Nat}): async {#Ok; #Err: Text}{
        if(checkOut >= checkIn) { return #Err(msg.ErrorSetHoursCheckInCheckOut) }; 
        let housing = Map.get<HousingId, Housing>(housings, nhash, housingId);
        switch housing {
            case null { #Err(msg.NotHousing)};
            case ( ?housing ) {
                if(caller != housing.owner) {
                    return #Err(msg.CallerNotHousingOwner);
                };
                ignore Map.put<HousingId, Housing>(housings, nhash, housingId, {housing with checkIn; checkOut});
                #Ok
            }
        }
    };

    public shared ({ caller }) func setAddress({housingId: HousingId; address: Types.Location}): async {#Ok; #Err: Text}{
        let housing = Map.get<HousingId, Housing>(housings, nhash, housingId);
        switch housing {
            case null { #Err(msg.NotHousing)};
            case ( ?housing ) {
                if(caller != housing.owner) {
                    return #Err(msg.CallerNotHousingOwner);
                };
                ignore Map.put<HousingId, Housing>(housings, nhash, housingId, {housing with address});
                #Ok
            }
        }
    };

    public shared ({ caller }) func locateOnTheMap({housingId: HousingId; lat: Int; lng: Int}): async {#Ok; #Err: Text} { // lat y lng van multiplicados por 10e7
        let housing = Map.get<HousingId, Housing>(housings, nhash, housingId);
        switch housing {
            case null { #Err(msg.NotHousing)};
            case ( ?housing ) {
                if(caller != housing.owner) {
                    return #Err(msg.CallerNotHousingOwner);
                };
                let address = {housing.address with geolocation = ?{lat; lng}};
                ignore Map.put<HousingId, Housing>(housings, nhash, housingId, {housing with address});
                #Ok
            }
        }
    };
    
    public shared ({ caller }) func cloneHousingWithProperties({housingId: HousingId; qty: Nat; housingTypeInit: HousingTypeInit}): async {#Ok; #Err: Text} {       
        let hostUser = Map.get<Principal, HostUser>(hostUsers, phash, caller);
        switch hostUser {
            case null {
                return #Err(msg.NotHostUser)
            };
            case ( ?hostUser ) {
                if (Map.has<Text, HousingType>(hostUser.housingTypes, thash, housingTypeInit.nameType)) {
                    return #Err(msg.HousingTypeExist)
                };
                let housing = Map.get<HousingId, Housing>(housings, nhash, housingId);
                switch housing {
                    case ( null ) { return #Err(msg.NotHousing)};
                    case ( ?housing ) {
                        if(housing.owner != caller) { 
                            return #Err(msg.CallerNotHousingOwner)
                        };
                        //Establecemos el tipo al housing a clonar
                        let housingType: HousingType =  {housingTypeInit with housingIds: [HousingId] = []};
                        ignore Map.put<HousingId, Housing>(
                            housings, 
                            nhash, 
                            housingId, 
                            { housing with properties = ?housingType; housingType = ?housingTypeInit.nameType});

                        var i = qty;
                        var housingIdsOfThisType = Buffer.fromArray<Nat>([housingId]);
                        while (i > 0) {
                            lastHousingId += 1;
                            housingIdsOfThisType.add(lastHousingId);

                            let newHousing: Housing = {
                                defaultHousinValues with
                                owner = caller;
                                housingId = lastHousingId;
                                namePlace = housing.namePlace;
                                nameHost = housing.nameHost;
                                descriptionPlace = housing.descriptionPlace;
                                descriptionHost = housing.descriptionHost;
                                link = housing.link;
                                photos = [];
                                properties = null;
                                housingType = ?housingTypeInit.nameType;
                                thumbnail = housing.thumbnail;
                                calendary = {dayZero = now(); reservations = []};
                                reservationsPending = [];
                                unavailability = { busy = []; pending = [] };
                            };
                            ignore Map.put<HousingId, Housing>(housings, nhash, lastHousingId,  newHousing );
                            i -= 1;
                        };
                        let housingIds = Buffer.toArray<Nat>(housingIdsOfThisType);
                        ignore Map.put<Text, HousingType>(hostUser.housingTypes, thash, housingType.nameType, {housingType with housingIds});
                        #Ok
                    }
                };    
            }
        };
    };
    

    // public shared ({ caller }) func removeHousingType(housingType: Text): async {#Ok; #Err: Text}{
    //     let myHousingTypesMap = Map.get<Principal, HousingTypesMap>(housingTypesByHostOwner, phash, caller);
    //     switch myHousingTypesMap {
    //         case null {#Err("Not housing types")};
    //         case (?housingTypesMap){
    //             let removedType = Map.remove<Text, {properties: Types.HousingType; housingIds: [HousingId]}>(
    //                 housingTypesMap, thash, housingType
    //             );
    //             switch removedType {
    //                 case null { #Err("Not housing type")};
    //                 case (?removedType) {#Ok}
    //             }
    //         }  
    //     }
    // };

    public shared ({ caller }) func setAmenities(amenities: Types.Amenities, housingId: HousingId): async {#Ok; #Err: Text}{
       let housing = Map.get<HousingId, Housing>(housings, nhash, housingId);
        switch housing {
            case null { #Err(msg.NotHousing)};
            case ( ?housing ) {
                if(caller != housing.owner) {
                    return #Err(msg.CallerNotHousingOwner);
                };
                let encodedAmenities = encodeAmenities(amenities);
                ignore Map.put<HousingId, Housing>(
                    housings, 
                    nhash, 
                    housingId, 
                    {housing with amenities = ?amenities; encodedAmenities});
                #Ok
            }
        } 
    };

    ///// Prueba 
    
    public shared ({ caller }) func setAmenities2(housingId: Nat, encodedAmenities2: Nat64): async {#Ok; #Err: Text} {
       let housing = Map.get<HousingId, Housing>(housings, nhash, housingId);
        switch housing {
            case null { #Err(msg.NotHousing)};
            case ( ?housing ) {
                if(caller != housing.owner) {
                    return #Err(msg.CallerNotHousingOwner);
                };
                ignore Map.put<HousingId, Housing>(
                    housings, 
                    nhash, 
                    housingId, 
                    {housing with encodedAmenities2});
                #Ok
            }
        } 
    };
    
    ///////////////////////////////////////// Getters ////////////////////////////////////////

    public query func getHousingPaginate({page: Nat; qtyPerPage: Nat}): async ResultHousingPaginate {
        if(Map.size(housings) < page * qtyPerPage){
            return #Err(msg.PaginationOutOfRange)
        };
        let values = Map.toArray<HousingId, Housing>(housings);
        let bufferHousingPreview = Buffer.fromArray<Housing>([]);
        var index = page * qtyPerPage;
        while (index < values.size() and index < (page + 1) * qtyPerPage){
            if(values[index].1.active){
                bufferHousingPreview.add(values[index].1);
            };
            index += 1;
        };
        let array = Buffer.toArray<Housing>(bufferHousingPreview);
        #Ok{
            array;
            hasNext = ((page + 1) * qtyPerPage < array.size())
        }
    };

    public query func filterByAmenities({filterCode: Nat64; page: Nat; qtyPerPage: Nat}): async ResultHousingPaginate {
        let filteredHosuings = Array.filter<Housing>(
            Iter.toArray<Housing>(Map.vals<HousingId, Housing>(housings)),
            func h = h.active and ((h.encodedAmenities & filterCode) == filterCode)
        );
        if(filteredHosuings.size() < page * qtyPerPage){
            return #Err(msg.PaginationOutOfRange)
        };
        let (size: Nat, hasNext: Bool) = if (filteredHosuings.size() >= (page + 1)  * qtyPerPage){
            (qtyPerPage, filteredHosuings.size() > (page + 1))
        } else {
            (filteredHosuings.size() % qtyPerPage, false)
        };
        let array = Array.subArray<Housing>(filteredHosuings, page * qtyPerPage, size);
        #Ok{ array; hasNext }
    };

    // public query func filterByProperties({filterCode: Nat64; page: Nat; qtyPerPage: Nat}): async ResultHousingPaginate {
    //     let filteredHosuings = Array.filter<Housing>(
    //         Iter.toArray<Housing>(Map.vals<HousingId, Housing>(housings)),
    //         func h = h.active and ((h.encodedAmenities & filterCode) == filterCode)
    //     );
    //     if(filteredHosuings.size() < page * qtyPerPage){
    //         return #Err(msg.PaginationOutOfRange)
    //     };
    //     let (size: Nat, hasNext: Bool) = if (filteredHosuings.size() >= (page + 1)  * qtyPerPage){
    //         (qtyPerPage, filteredHosuings.size() > (page + 1))
    //     } else {
    //         (filteredHosuings.size() % qtyPerPage, false)
    //     };
    //     let array = Array.subArray<Housing>(filteredHosuings, page * qtyPerPage, size);
    //     #Ok{ array; hasNext }
    // };


    public shared ({ caller }) func getCalendarById(id: Nat): async {#Ok: Calendary; #Err: Text}{
        switch (Map.get<HousingId, Housing>(housings, nhash, id)) {
            case (?housing) {
                if (housing.owner != caller ) {return #Err(msg.CallerNotHousingOwner)};
                let { calendary } = updateCalendary(id);
                #Ok(calendary)
            };
            case null { return #Err(msg.NotHousing)};   
        };
    };

    public shared ({ caller }) func getHousingById({housingId: HousingId;  photoIndex: Nat}): async {#Ok: HousingResponse; #Err: Text} {
        let housing = Map.get<HousingId, Housing>(housings, nhash, housingId);
        
        return switch housing {
            case null { #Err(msg.NotHousing)};
            case (?housing) {
                let reservationsPending = cleanPendingVerifications(housingId);
                if(not housing.active and housing.owner != caller) {
                    return #Err(msg.InactiveHousing)
                };
                let { unavailability } = updateCalendary(housingId);
                if(photoIndex == 0){
                    let housingResponse: HousingResponse = #Start({
                        housing with
                        reservationsPending;
                        calendary = {dayZero = 0 ; reservations = []}; //Informacion omitida para el publico
                        unavailability;
                        photos = if(housing.photos.size() > 0) { [housing.photos[0]] } else { [] };
                        hasNextPhoto = (housing.photos.size() > photoIndex + 1)
                    });
                    #Ok(housingResponse);
                } else {
                    if (photoIndex >= housing.photos.size()) { return #Err(msg.PaginationOutOfRange)};
                    let housingResponse: HousingResponse = #OnlyPhoto({
                        photo = housing.photos[photoIndex];
                        hasNextPhoto = (housing.photos.size() > photoIndex + 1)
                    });
                    print(debug_show(housing.photos));
                    #Ok(housingResponse)
                }
            };
        }
    };

    public shared ({ caller }) func getMyHousingTypes(): async {#Ok: [{typeName: Text; housingIds: [Nat]}]; #Err: Text}{
        let hostUser = Map.get<Principal, HostUser>(hostUsers, phash, caller);
        switch hostUser {
            case null {#Err(msg.NotHostUser)};
            case (?hostUser) {
                #Ok(
                    Array.map<(Text, HousingType),{ typeName: Text; housingIds: [Nat]} >(
                        Map.toArray<Text, HousingType>(hostUser.housingTypes),
                        func x = {typeName = x.0; housingIds = x.1.housingIds}
                    ) 
                )           
            };
        }
    };

    public shared query ({ caller }) func getMyHousingsByType({housingType: Text; page: Nat}): async ResultHousingPaginate{
        let hostUser = Map.get<Principal, HostUser>(hostUsers, phash, caller);
        switch hostUser {
            case null {#Err(msg.NotHostUser)};
            case (?hostUser) {
                switch (Map.get<Text, HousingType>(hostUser.housingTypes, thash, housingType)){
                    case null { return #Err(msg.HousingTypeNoExist)};
                    case ( ?housingType ) {
                        getPaginateHousings(housingType.housingIds, page)
                    }
                }           
            };
        }
    };

    func getPaginateHousings(ids: [HousingId], page: Nat): ResultHousingPaginate {
        let resultBuffer = Buffer.fromArray<HousingPreview>([]);
        var index = page * 10;
        while(index < (page + 1)* 10 and index < ids.size()){
            switch (Map.get<HousingId, Housing>(housings, nhash, ids[index])) {
                case null {};
                case (?housing) {          
                    resultBuffer.add( 
                        { 
                            active = housing.active;
                            housingId = ids[index];
                            address = housing.address;
                            thumbnail = housing.thumbnail;
                            price = housing.price;
                            encodedAmenities = housing.encodedAmenities
                        }
                    )
                }
            };
            index += 1;
        };
        let hasNext = ids.size() > (page + 1)* 10;
        #Ok({array = Buffer.toArray<HousingPreview>(resultBuffer); hasNext: Bool});
    };

    func getHousingsPaginateByOwner(owner: Principal, page: Nat, qtyPerPage: Nat, onlyActives: Bool): ResultHousingPaginate {
        let hostUser = Map.get<Principal, HostUser>(hostUsers, phash, owner);

        switch hostUser {
            case null { #Err(msg.NotHostUser)};
            case ( ?hostUser ) { 
                // let housingArray = List.toArray<HousingId>(hostUser.housingIds);
                let housingPreviewBuffer = Buffer.fromArray<HousingPreview>([]);
                for(id in List.toIter(hostUser.housingIds)){
                    switch (Map.get<HousingId, Housing>(housings, nhash, id)){
                        case (?housing) {
                            if(not onlyActives or housing.active){
                               housingPreviewBuffer.add(housing) 
                            } 
                        };
                        case _ { }
                    };
                };
                let arrayHousingPreview = Buffer.toArray(housingPreviewBuffer);
                if ( arrayHousingPreview.size() < page * qtyPerPage){
                    return #Err(msg.PaginationOutOfRange);
                };
                let (size: Nat, hasNext: Bool) = if (arrayHousingPreview.size() >= (page + 1)  * qtyPerPage){
                    (qtyPerPage, arrayHousingPreview.size() > (page + 1))
                } else {
                    (arrayHousingPreview.size() % qtyPerPage, false)
                };
                return #Ok({array = Array.subArray(arrayHousingPreview, page * qtyPerPage, size); hasNext : Bool})

            }
        }
    };

    public shared query ({ caller }) func getMyHousingsPaginate({page: Nat; qtyPerPage: Nat}): async ResultHousingPaginate{
        getHousingsPaginateByOwner(caller, page, qtyPerPage, false)
    };

    public shared query ({ caller }) func getMyActiveHousings({page: Nat; qtyPerPage: Nat}): async ResultHousingPaginate{
        getHousingsPaginateByOwner(caller, page, qtyPerPage, true)      
    };

    func encodeAmenities(a: Types.Amenities): Nat64 {
        var result = 0: Nat64; 
        // El orden de los elementos de este array tiene que coincidir con el array para la decodificacion 
        let arrayBools = [
            a.freeWifi,
            a.airCond,
            a.flatTV,
            a.minibar,
            a.safeBox,
            a.roomService,
            a.premiumLinen,
            a.ironBoard,
            a.privateBath,
            a.hairDryer,
            a.hotelRest,
            a.barLounge,
            a.buffetBrkfst,
            a.lobbyCoffee,
            a.catering,
            a.specialMenu,
            a.outdoorPool,
            a.spaWellness,
            a.gym,
            a.jacuzzi,
            a.gameRoom,
            a.tennisCourt,
            a.natureTrails,
        ];
        for(i in arrayBools.vals()) { result := result * 2  + (if i { 1 } else { 0 })};
        result
        //  Ejemplo aproximado para llenar array de Booleanos a partir de result y el array de amenidades equivalente en el front:
        //  let amenities = ["freeWifi", "airCond" ... etcetera]
        //  let amenitiesTrue = [];
        //  for (let i = 0; i < amenities.length; i++) {
        //      if ((encodedAmenities & (1 << amenities.length - 1 - i) != 0)){
        //          amenitiesTrue.push(amenities[i]);
        //      }
        //  }
        //  //Ejemplo para filtar por jacuzzi
        //  let jacuzzi =  (encodedAmenities >> (amenities.length - 19 -1)) % 2 === 1;
        //  //Ejemplo para filtrar por jasuzzi y minibar:
        //  let jacuzziYMiniBar =  (encodedAmenities & (1 << amenities.length - 1 - 20) != 0) and
        //  (encodedAmenities & (1 << amenities.length - 1 - 3) != 0);

    };

    // public func filterHousing(filters: Filter) {
        
    // };

    public shared query func getHousingByHostUser({host: Principal; page: Nat; qtyPerPage: Nat}): async ResultHousingPaginate{
        getHousingsPaginateByOwner(host, page, qtyPerPage, true)
    };

    type UpdateCalendaryResponse = {
        calendary: Calendary;
        unavailability: {busy: [Int]; pending: [Int]};
    };

    func updateCalendary(housingId: HousingId): UpdateCalendaryResponse{
        switch (Map.get<HousingId, Housing>(housings, nhash, housingId)){
            case null {
                assert false; // La siguiente linea no se ejecuta nunca pero se requiere que todas las ramificaciones tengan una ultima linea con una expresion del tipo de retorno
                { calendary = {dayZero = 0; reservations = []} ; unavailability = {busy = []; pending = []}};
            };
            case ( ?housing ) {
                let startOfCurrentDayGMT = now() - now() % nanoSecPerDay ; // Timestamp inicio del dia actual en GTM + 0
                let daysSinceLastUpdate = (startOfCurrentDayGMT - housing.calendary.dayZero) / nanoSecPerDay;
                // El siguiente bloque funciona bien pero se puede acomodar mejor
                if(daysSinceLastUpdate > 0){      
                    var updateArray = Array.filter<Reservation>(
                        housing.calendary.reservations, 
                        func(x: Reservation): Bool {x.checkOut >= daysSinceLastUpdate}
                    );
                    updateArray := Prim.Array_tabulate<Reservation>(
                        updateArray.size(),
                        func x {{
                            updateArray[x] with 
                            checkIn = updateArray[x].checkIn - daysSinceLastUpdate;
                            checkOut = updateArray[x].checkOut - daysSinceLastUpdate    
                        }}
                    );
                    let busy = extractDaysNotAvailable(#ReservationType(updateArray));
                    let pending = extractDaysNotAvailable(#IdsReservation(housing.reservationsPending));
                    let unavailability = {busy; pending};
                    let calendary = {dayZero = startOfCurrentDayGMT; reservations = updateArray};
                    let housingUpdate = {housing with calendary; unavailability};
                    ignore Map.put<HousingId, Housing>(housings, nhash, housingId, housingUpdate);
                    return {calendary; unavailability};
                } else {
                    let busy = extractDaysNotAvailable(#ReservationType(housing.calendary.reservations));
                    let pending = extractDaysNotAvailable(#IdsReservation(housing.reservationsPending));
                    let unavailability = {busy; pending};
                    return {calendary = housing.calendary; unavailability }
                };
            }
        }
    };

    func extractDaysNotAvailable(input: {#ReservationType: [Reservation]; #IdsReservation : [Nat]}): [Int] {
        let bufferDaysUnavailable = Buffer.fromArray<Int>([]);
        let reservationsArray = switch input {
            case ( #ReservationType(reservationsArray)){ reservationsArray };
            case ( #IdsReservation(idsArray) ) {
                let bufferReservations = Buffer.fromArray<Reservation>([]);
                for (id in idsArray.vals()) {
                    switch (Map.get<Nat, Reservation>(reservationsPendingConfirmation, nhash, id)) {
                        case null { };
                        case (?reservation) { bufferReservations.add(reservation)}
                    };
                };
                Buffer.toArray<Reservation>(bufferReservations);
            }
        };       
        for (r in reservationsArray.vals()) {
            var dayOccuped = r.checkIn;
            while(dayOccuped < r.checkOut ) {
                bufferDaysUnavailable.add(dayOccuped);
                dayOccuped += 1;
            }
        };
        Array.sort(Buffer.toArray(bufferDaysUnavailable), Int.compare);    
            
        
    };

    func cleanPendingVerifications(housingId: Nat): [Nat] { //Remueve las solicitudes no confirmadas y con el tiempo de confirmacion transcurrido;
        // TODO Esta funcion viola los principios solid ya que se encarga de limpiar las solicitudes pendientes tanto del Map general
        // como tambien los id de solicitudes de dentro de las estructuras de los housing y ademas devuelve un array con los ids vigentes 
        // correspondientes al HousingID pasado por parametro. Ealuar alguna refactorizacion
        // var reservationsPendingForId = ids;
        var reservationsPendingForTheProvidedID: [Nat] = [];
        for ((id, reservation) in Map.toArray<Nat, Reservation>(reservationsPendingConfirmation).vals()) {
            if (now() > reservation.date + TimeToPay) {
                // print("Solicitud de reserva " # Nat.toText(id) # " Eliminada por timeout");
                ignore Map.remove<Nat, Reservation>(reservationsPendingConfirmation, nhash, id);
                let housing = Map.get<HousingId, Housing>(housings, nhash, reservation.housingId);
                switch housing {
                    case null { };
                    case (?housing) {
                        let reservationsPending = Array.filter<Nat>(
                            housing.reservationsPending,
                            func x = x != id
                        );
                        // print("Id de solicitud " # Nat.toText(id) # " borrado\nreservas pendientes: ");
                        // print(debug_show(reservationsPending)); // revisar el filter
                        if (id == housingId ) { reservationsPendingForTheProvidedID := reservationsPending };
                        ignore Map.put<HousingId, Housing>(housings, nhash, reservation.housingId, {housing with reservationsPending});
                    }
                }
            }
        };
        reservationsPendingForTheProvidedID
    };

    func getPendingReservations(ids: [Nat]): {pendings: [Reservation]; pendingReservUpdate: [Nat]}{
        let bufferReservations = Buffer.fromArray<Reservation>([]);
        let bufferReservUpdate = Buffer.fromArray<Nat>([]); 
        for (id in ids.vals()) {
            switch (Map.get<Nat, Reservation>(reservationsPendingConfirmation, nhash, id)) {
                case null {bufferReservUpdate.add(id)};
                case ( ?reservation ) {
                    // Si la solicitud es antigua se elimina del map y se devuelte el id para limpiar
                    if ( now() > reservation.date + TimeToPay) {
                        ignore Map.remove<Nat, Reservation>(reservationsPendingConfirmation, nhash, id);
                        // print("reserva " # Nat.toText(id) # " eliminada");
                    } else {
                        bufferReservations.add(reservation);
                        bufferReservUpdate.add(id);
                    }  
                };
            };
        };
        {pendings = Buffer.toArray(bufferReservations); pendingReservUpdate = Buffer.toArray(bufferReservUpdate)}
    };

    func checkDisponibility(housingId: HousingId, chechIn: Nat, checkOut: Nat): Bool {
        switch (Map.get<HousingId, Housing>(housings, nhash, housingId)) {
            case (?housing) { 
                if(not housing.active) { return false } 
                else {
                    // let updatedCalendary = updateCalendary(housing.calendary);
                    let { calendary } = updateCalendary(housingId);
                    var checkDay = chechIn;
                    let {pendings; pendingReservUpdate} = getPendingReservations(housing.reservationsPending);
                    ignore Map.put<HousingId, Housing>(housings, nhash, housingId, {housing with reservationsPending = pendingReservUpdate});
                    while (checkDay < checkOut) {
                        for (occuped in calendary.reservations.vals()){
                            if(checkDay >= occuped.checkIn and checkDay < occuped.checkOut) {
                                return false;
                            };
                        };
                        if (pendingReservUpdate.size() > 0) {
                            print("Hay " # Nat.toText(pendingReservUpdate.size()) # " reservations pendientes");
                            for (bloqued in pendings.vals()){
                                print(debug_show(bloqued));
                                if(checkDay >= bloqued.checkIn and checkDay < bloqued.checkOut) {
                                    return false;
                                }; 
                            }
                        };
                        checkDay += 1;
                    };
                    return true
                }
            };
            case  _ { return false }
        };            
    };
    ////////// view reservations pendding /////////////////
    public query func pendingReserv(): async () {
        print(debug_show(Map.toArray<Nat, Reservation>(reservationsPendingConfirmation)))
    };

    //////////////////////////////////////////////////////
    public shared query ({ caller }) func getMyHousingDisponibility({checkIn: Nat; checkOut: Nat; page: Nat; qtyPerPage: Nat}): async ResultHousingPaginate{
        let response = getHousingsPaginateByOwner(caller, page, qtyPerPage, true);
        switch response {
            case (#Ok({array; hasNext} )){
                let bufferResults = Buffer.fromArray<HousingPreview>([]);
                for(hostPreview in array.vals()){
                    if(checkDisponibility(hostPreview.housingId, checkIn, checkOut)){
                       bufferResults.add(hostPreview);
                    };
                };
                #Ok({array = Buffer.toArray<HousingPreview>(bufferResults); hasNext})
            };
            case (#Err(msg)) { #Err(msg) }
        }
    };

    public query func getAmenities({housingId: HousingId}): async ?Types.Amenities {
        let housing = Map.get<HousingId, Housing>(housings, nhash, housingId);
        switch housing {
            case null { null };
            case (?housing) {
                housing.amenities
            }
        }
    };

    ///////////////////////////// Reservations ////////////////////////////

    func blobToText(t: Blob): Text {
        var result = "";
        let chars = ["0", "1" , "2" , "3" ,"4" , "5" , "6" , "7" , "8" , "9" , "a" , "b" , "c" , "d" , "e" , "f"];
        for (c in Blob.toArray(t).vals()){
            result #= chars[Nat8.toNat(c) / 16];
            result #= chars[Nat8.toNat(c) % 16] 
        };
        result
    };

    func calculatePrice(price: ?Types.Price, daysInt: Int): Nat64 {
        switch price {
            case null {assert (false); 0 };
            case (?price) {
                var currentDiscount = 0;
                let days = Int.abs(daysInt);
                let discounts = Array.sort<{minimumDays: Nat; discount: Nat}>(
                    price.discountTable,
                    func (a, b) = if (a.minimumDays < b.minimumDays) { #less } else { #greater } 
                );
                for(discount in discounts.vals()){
                    // print(debug_show(discount));
                    if(days < discount.minimumDays) { return Nat64.fromNat((price.base * days) - (price.base * days * currentDiscount / 100)) };
                    currentDiscount := discount.discount;   
                };
                return Nat64.fromNat((price.base * days) - (price.base * days * currentDiscount / 100));
            }
        }
    };

    func putRequestReservationToHousing(housingId: HousingId, requestId: Nat) {
        let housing = Map.get<HousingId, Housing>(housings, nhash, housingId);
        switch housing {
            case null {assert false};
            case ( ?housing ) {
                let reservationsPending = Prim.Array_tabulate<Nat>(
                    housing.reservationsPending.size() + 1,
                    func x = if( x == 0 ) {requestId} else {housing.reservationsPending[x - 1]}
                );
                ignore Map.put<HousingId, Housing>(housings, nhash, housingId, {housing with reservationsPending});
            }
        } 
    };

    public shared ({ caller = requester }) func requestReservation(data: Types.ReservationDataInput): async TransactionResponse {
        let {housingId; guest; email; phone; checkIn; checkOut}: Types.ReservationDataInput = data;
        let housing = Map.get<HousingId, Housing>(housings, nhash, housingId);
        if ( not Map.has<Principal, User>(users, phash, requester) ) { 
            return #Err(msg.NotUser)
        };
        if ( checkIn >= checkOut or checkIn < 0) { 
            return #Err(msg.ErrorSetHoursCheckInCheckOut) 
        };

        switch housing {
            case null { #Err(msg.NotHousing)};
            case ( ?housing ) {
                if(checkDisponibility(housingId, Prim.abs(checkIn), Prim.abs(checkOut))){
                    lastReservationId += 1; 
                    let amount = calculatePrice(housing.price,  Prim.abs(checkOut - checkIn));
                    let reservation: Reservation = {
                        date = now();
                        timestampCheckIn = (now() - now() % nanoSecPerDay) + (checkIn * nanoSecPerDay) /* + (housing.checkIn * 60 * 60 * 1000000000) */;
                        housingId;
                        reservationId = lastReservationId;
                        requester;
                        ownerHousing = housing.owner;
                        checkIn;
                        checkOut;
                        guest;
                        email;
                        phone;
                        // confirmated = false;
                        status = #Pending;
                        amount;
                        dataTransaction = Types.NullTrx;
                    };
                    ignore Map.put<Nat, Reservation>(reservationsPendingConfirmation, nhash, lastReservationId, reservation);
                    putRequestReservationToHousing(housingId, lastReservationId);
                    
                    let dataTransaction: TransactionParams = {
                        // Se toma el account por defecto correspondiente al principal del dueño del Host
                        // Se puede establecer otro account proporcionado por el usuario 
                        to = blobToText(AccountIdentifier.accountIdentifier(housing.owner, AccountIdentifier.defaultSubaccount()));
                        amount;
                    };
                    #Ok({transactionParams = dataTransaction; reservationId = lastReservationId});
                } else {
                    #Err(msg.NotAvalableAllDays)
                };           
            }
        } 
    };

    func verifyTransaction({from; to; amount}: DataTransaction, registeredAmount: Nat64): async Bool {
        // TODO Verificar tambien aca 
        return true; // Test
        if(amount != registeredAmount) { return false };
        let indexer_icp = actor("qhbym-qaaaa-aaaaa-aaafq-cai"): actor {
                get_account_identifier_transactions : 
                    shared query Indexer_icp.GetAccountIdentifierTransactionsArgs -> async Indexer_icp.GetAccountIdentifierTransactionsResult;
        };
        let result = await indexer_icp.get_account_identifier_transactions({max_results = 10; start = null; account_identifier = from});
        switch result {
            case (#Ok(response)) {
                for (transaction in response.transactions.vals()) {
                    let operation = transaction.transaction.operation;
                    switch operation {
                        case( #Transfer(tx)) {
                            if (tx.from == from and
                            tx.to == to and
                            tx.amount.e8s >= amount){
                                return true
                            }
                        };
                        case ( _ ) { }
                    }; 
                };
                false
            };
            case (#Err(_)) { false }
        }
    };

    func calculateReward(amount: Nat64, coin: Text): async  Nat64 {
        let urlApi = "https://api3.binance.com/api/v3/ticker/price?symbol=" # Text.toUppercase(coin) # "USDT";
        //TODO convertir amount al equivalente en usdt
        1 * amount / RewardRatio;
    };

    public shared ({ caller }) func confirmReservation({reservationId: Nat; txData: DataTransaction}): async {#Ok: Reservation; #Err: Text} {
        let reservation = Map.remove<Nat, Reservation>(reservationsPendingConfirmation, nhash, reservationId);
        switch reservation {
            case null { #Err(msg.NotReservation)};
            case ( ?reservation ){
                if (await verifyTransaction(txData, reservation.amount)){
                    if(reservation.requester != caller) { 
                        return #Err(msg.CallerIsNotRequester # Nat.toText(reservationId))
                    };
                  
                    let housing = Map.get<HousingId, Housing>(housings, nhash, reservation.housingId);
                    switch housing {
                        case null { #Err(msg.NotHousing)};
                        case ( ?housing ) {
                            let currentReservation = {   
                                reservation with 
                                status = #Confirmed; 
                                dataTransaction = {txData with amount = reservation.amount}  
                            };
                            let calendary = {
                                housing.calendary with
                                reservations = Prim.Array_tabulate<Reservation>(
                                housing.calendary.reservations.size() + 1,
                                func x = if (x == 0) { currentReservation } else { housing.calendary.reservations[x - 1] })
                            };
                            // print(debug_show(calendary));
                            let reservationsPending = Array.filter<Nat>(housing.reservationsPending, func x = x !=reservationId );
                            ignore Map.put<Nat, Reservation>(reservationsHistory, nhash, reservationId, currentReservation);
                            ignore Map.put<HousingId, Housing>(
                                housings, 
                                nhash, 
                                reservation.housingId, 
                                { housing with calendary; reservationsPending }
                            );
                        ///// Rewards for confirm reservation ////////////////////////////////////////////////////
                            // TODO calcular recompenza en base al aquialente en dolares de reservation.amount
                            if (Principal.fromActor(TourMinterCanister) != Principal.fromText(NULL_ADDRESS)){
                                let rewardAmount = await calculateReward(reservation.amount, "ICP"); 
                                print("Mintenado recompenza: " # debug_show(rewardAmount) # " Tour");
                                let accounts = [
                                    {owner = caller; subaccount = null },
                                    {owner = housing.owner; subaccount = null}
                                ];
                                ignore await TourMinterCanister.issueRewards({accounts; amount = rewardAmount })   
                            };
                        //////////////////////////////////////////////////////////////////////////////////////////
                            #Ok(currentReservation)
                        }
                    }
                } else {
                    #Err(msg.TransactionNotVerified)
                };        
            }
        }  
    };    

    public shared ({ caller }) func requestToCancelReservation(reservationId: Nat): async TransactionResponse {
        // TODO Actualizar el estado de las reservas en general, antes de proceder
        let reservation = Map.get<Nat, Reservation>(reservationsHistory, nhash, reservationId);
        switch reservation {
            case null { return #Err(msg.NotReservation)};
            case ( ?reservation ) {
                if (reservation.ownerHousing != caller) { 
                    return #Err(msg.CallerNotHousingOwner # " corresponding to reservation # " # Nat.toText(reservationId)) 
                };
                if (reservation.status == #Confirmed) {
                    if(reservation.timestampCheckIn <= now() + MinDaysBeforeCheckinForCancellation * nanoSecPerDay){
                        return #Err("The reservation cannot be cancelled less than " # Nat.toText(MinDaysBeforeCheckinForCancellation) # " days");
                    };
                    let dataTransaction: TransactionParams = {
                        to = reservation.dataTransaction.from;
                        amount = reservation.dataTransaction.amount + (reservation.dataTransaction.amount * CancellationFeeCompensateBuyer) / 100;
                    };
                    #Ok({transactionParams = dataTransaction; reservationId = reservationId})
                } else {
                    let status = switch (reservation.status) {
                        case (#Pending) { " Pending Reservation" };
                        case (#Canceled) { " Canceled " };
                        case ( #Ended ) { " Ended " };
                        case _ {""}
                    };
                    #Err("Reservation status is " # status)
                }
            }
        };
    };

    public shared ({ caller }) func confirmCancelReservation({reservationId: Nat; txData: DataTransaction}): async {#Ok: Reservation; #Err: Text}{
        let reservation = Map.get<Nat, Reservation>(reservationsHistory, nhash, reservationId);
        switch reservation {
            case null { return #Err(msg.NotReservation)};
            case ( ?reservation ) {
                if (reservation.ownerHousing != caller) { 
                    return #Err(msg.CallerNotHousingOwner # " corresponding to reservation # " # Nat.toText(reservationId)) 
                };
                if (reservation.status != #Confirmed) {
                    return #Err("Reservation status is not confirmed")
                };
                let amountWithFee = reservation.dataTransaction.amount + (reservation.dataTransaction.amount * CancellationFeeCompensateBuyer) / 100;
                if (await verifyTransaction(txData, amountWithFee)) {
                    ignore Map.put<Nat, Reservation>(reservationsHistory, nhash, reservationId, {reservation with status = #Canceled});
                    let housing = Map.get<HousingId, Housing>(housings, nhash, reservation.housingId);
                    switch housing {
                        case null { return #Err(msg.NotHousing)};
                        case ( ?housing ) {
                            let reservationsPending = Array.filter<Nat>(housing.reservationsPending, func x = x != reservationId);
                            ignore Map.put<HousingId, Housing>(
                                housings, 
                                nhash, 
                                reservation.housingId, 
                                { housing with reservationsPending }
                            );
                            #Ok({reservation with status = #Canceled})
                        }
                    };
                } else {
                    #Err(msg.TransactionNotVerified)
                }     
            }
        };
    };

    public shared ({ caller }) func getReservationByDay(housingId: Nat, day: Nat): async {#Ok: Reservation; #Err: Text}{
        let housing = Map.get<HousingId, Housing>(housings, nhash, housingId);
        switch housing {
            case null { return #Err(msg.NotHousing)};
            case ( ?housing ) {
                //// Actualización del calendario ////
                let { calendary } = updateCalendary(housingId);
                // ignore Map.put<HousingId, Housing>(housings, nhash, housingId, {housing with calendary; unavailability});  
                /////////////////////////////////////
                if (housing.owner != caller) { return #Err(msg.CallerNotHousingOwner)};
                for (reservation in calendary.reservations.vals()) {
                    if (day >= reservation.checkIn and day < reservation.checkOut) {
                        return #Ok(reservation)
                    }
                };
                return #Err("No reservation for this day")
            }
        }
    };
};

