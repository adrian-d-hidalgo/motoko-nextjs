import Prim "mo:⛔";
import Map "mo:map/Map";
import Set "mo:map/Set";
import { phash; nhash; thash } "mo:map/Map";
import Principal "mo:base/Principal";
import Buffer "mo:base/Buffer";
import Blob "mo:base/Blob";
import Types "types";
// import Int "mo:base/Int";
import { now } "mo:base/Time";
// import Rand "mo:random/Rand";
import msg "constants";

////////////// Debug imports ////////////////
import { print } "mo:base/Debug";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Int "mo:base/Int";
 
shared ({ caller }) actor class Triourism () = this {

    type User = Types.User;
    type UserKind = Types.UserKind;
    type SignUpResult = Types.SignUpResult;
    // type CalendaryPart = Types.CalendaryPart;
    type Calendary = {dayZero: Int; reservedDays: [Int]};
    type ReservationDataInput = Types.ReservationDataInput;
    type Reservation = Types.Reservation;
    type HousingId = Types.HousingId;
    // type HousingDataInit = Types.HousingDataInit;
    type Housing = Types.Housing;
    type HousingResponse = Types.HousingResponse;
    type HousingPreview = Types.HousingPreview;
    type HousingCreateData = Types.HousingCreateData;
    type HousingTypesMap = Map.Map<Text, {properties: Types.Property; housingIds: [HousingId]}>;

    type UpdateResult = Types.UpdateResult;
    type ResultHousingPaginate = {#Ok: {array: [HousingPreview]; hasNext: Bool}; #Err: Text};
    type PublishResult = {#Ok: HousingId; #Err: Text};

    type ReservationResult = {
        #Ok: {
            reservationId: Nat;
            msg: Text;   
        };
        #Err: Text;        
    };

    // TODO revisar day, actualemnte es el timestamp de una hora especifica que delimita el comienzo del dia 
    
  
    stable let DEPLOYER = caller;
    // let NANO_SEG_PER_HOUR = 60 * 60 * 1_000_000_000;
    // let ramdomGenerator = Rand.Rand();

    // stable var minReservationLeadTime = 24 * 60 * 60 * 1_000_000_000; // 24 horas en nanosegundos
    
    stable let admins = Set.new<Principal>();
    ignore Set.put<Principal>(admins, phash, caller);
    stable let users = Map.new<Principal, User>();
    stable let housings = Map.new<HousingId, Housing>();
    stable let housingTypesByHostOwner = Map.new<Principal, HousingTypesMap>();
    stable let calendars = Map.new<HousingId, Calendary>();
    stable let reservationsRequests = Map.new<HousingId, Reservation>();
    stable let reservationsConfirmed = Map.new<HousingId, Reservation>();

    stable var lastHousingId = 0;
    

  ///////////////////////////////////// Update functions ////////////////////////////////////////

    private func _safeSignUp(p: Principal, data: Types.SignUpData, kind: UserKind): SignUpResult {
        if(Principal.isAnonymous(p)){
            return #Err(msg.NotUser)
        };
        let user = Map.get(users, phash, p);
        switch user {
            case (?User) { #Err("User already exists") };
            case null {
                let newUser: User = {
                    data with
                    kinds: [UserKind] = [kind];
                    verified = true;
                    score = 0;
                };
                ignore Map.put(users, phash, p, newUser);
                #Ok(newUser);
            };
        };
    };

    public shared ({ caller }) func signUp(data: Types.SignUpData) : async SignUpResult {
        _safeSignUp(caller, data, #Initial)
    };

    public shared ({ caller }) func signUpAsHost(data: Types.SignUpData) : async SignUpResult {
        _safeSignUp(caller, data, #Host([]));

    };

    public shared query ({ caller }) func logIn(): async {#Ok: User; #Err} {
        let user = Map.get<Principal, User>(users, phash, caller);
        switch user {
            case null { #Err };
            case ( ?u ) { #Ok(u)}
        };
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

    func isUser(p: Principal): Bool { Map.has<Principal, User>(users, phash, p)};
 
    func isHostUser(p: Principal): Bool {
        let user = Map.get<Principal, User>(users, phash, p);
        switch user {
            case null { false };
            case (?user) {
                for (kind in user.kinds.vals()) {
                    switch kind {
                        case (#Host(_)) { return true };
                        case _ {}
                    };
                };
                return false
            }
        }
    };

    func addIdToHostKind(arr: [Types.UserKind], id: HousingId): [Types.UserKind]{
        let bufferKinds = Buffer.fromArray<Types.UserKind>([]);
        for (k in arr.vals()) {
            switch k {
                case (#Host(ids)){
                    let setIds = Set.fromIter<HousingId>(ids.vals(), nhash);
                    ignore Set.put<HousingId>(setIds, nhash, id);
                    bufferKinds.add(#Host(Set.toArray(setIds)))
                };
                case (k) {bufferKinds.add(k)}
            };
        };
        Buffer.toArray<Types.UserKind>(bufferKinds);
    };

    func addressEqual(a: Types.Location, b: Types.Location ) : Bool {
        a.country == b.country and
        a.city == b.city and
        a.neighborhood == b.neighborhood and
        a.zipCode == b.zipCode and
        a.externalNumber == b.externalNumber and
        a.internalNumber == b.internalNumber
    };

    let NULL_LOCATION = {
        country = "";
        city = ""; 
        neighborhood = ""; 
        zipCode = 0; street = "";  
        externalNumber = 0; 
        internalNumber = 0
    };

    let defaultHousinValues = {
        active: Bool = false;
        rules: [Types.Rule] = [];
        price: ?Types.Price = null;
        checkIn: Nat = 15;
        checkOut: Nat = 12;
        address: Types.Location = NULL_LOCATION;
        properties: [Types.Property] = [];
        amenities = null;
        // calendar: [var Types.CalendaryPart] = [var];
    };



  /////////////////////////// Manage admins functions /////////////////////////////////

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
        let user = Map.get<Principal, User>(users, phash, caller);
        switch user {
            case null {#Err(msg.NotUser)};
            case (?user) {
                if (not isHostUser(caller)) { return #Err(msg.NotHostUser)};
                lastHousingId += 1;

                let newHousing: Housing = {
                    dataInit and 
                    defaultHousinValues with
                    id = lastHousingId;
                    owner = caller;
                };
                let kinds = addIdToHostKind(user.kinds, lastHousingId);
                ignore Map.put<Principal, User>(users, phash, caller, {user with kinds });
                ignore Map.put<HousingId, Housing>(housings, nhash, lastHousingId,newHousing );
                ignore Map.put<HousingId, Calendary>(calendars, nhash, lastHousingId, {dayZero= now(); reservedDays=  []});
                #Ok(lastHousingId)
            }
        }
    };

    func isPublishable(housing: Housing): Bool {
        (housing.price != null) and
        (not addressEqual(housing.address, NULL_LOCATION)) and
        (housing.properties.size() > 0)
    };

    public shared ({ caller }) func publishHousing(housingId: HousingId): async {#Ok; #Err: Text}{
        let user = Map.get<Principal, User>(users, phash, caller);
        switch user {
            case null { #Err(msg.NotUser)};
            case ( ?user ) {
                let housing = Map.get<HousingId, Housing>(housings, nhash, housingId);
                switch housing {
                    case null { #Err(msg.NotHousing)};
                    case ( ?housing ) {
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

    // public shared ({ caller }) func setMinReservationLeadTime({id: HousingId; hours: Nat}):async  {#Ok; #Err: Text} {
    //     let housing = Map.get<HousingId, Housing>(housings, nhash, id);
    //     switch housing {
    //         case null {
    //             return #Err(msg.NotHosting);
    //         };
    //         case (?housing) {
    //             if(housing.owner != caller){
    //                 return #Err(msg.CallerNotHousingOwner);
    //             };
    //             ignore Map.put<HousingId, Housing>(
    //                 housings, 
    //                 nhash, 
    //                 id, 
    //                 {housing with minReservationLeadTimeNanoSeg = hours * NANO_SEG_PER_HOUR});
    //             #Ok;
    //         }

    //     }
    // };

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

    func createHousingType(user: Principal, propertiesOfType: Types.Property): {#Ok; #Err: Text} {
        let housingTypesMap: HousingTypesMap =
            switch(Map.get<Principal, HousingTypesMap>(housingTypesByHostOwner, phash, user)){
                case null {Map.new<Text, {properties: Types.Property; housingIds: [HousingId]}>() };
                case ( ?map ) { map }
            };
        switch (Map.get<Text, {properties: Types.Property; housingIds: [HousingId]}>(
            housingTypesMap,
            thash,
            propertiesOfType.nameType)) {
            case null {
                // Creación del nuevo tipo 
                ignore Map.put<Text, {properties: Types.Property; housingIds: [HousingId]}>(
                    housingTypesMap,
                    thash,
                    propertiesOfType.nameType,
                    {properties = propertiesOfType; housingIds: [HousingId] = []}
                );
                ignore Map.put<Principal, HousingTypesMap>(housingTypesByHostOwner, phash, user, housingTypesMap);
                #Ok
            };
            case (_) {
                #Err(msg.HousingTypeExist)
            }
        }
    };

    func putHousingType(user: Principal, propertiesOfType: Types.Property, housingId: HousingId ){
        let housingTypesMap: HousingTypesMap =
            switch(Map.get<Principal, HousingTypesMap>(housingTypesByHostOwner, phash, user)){
                case null {Map.new<Text, {properties: Types.Property; housingIds: [HousingId]}>() };
                case ( ?map ) { map }
            };
        let housingType: {properties: Types.Property; housingIds: [HousingId]} =
            switch (Map.get<Text, {properties: Types.Property; housingIds: [HousingId]}>(
                housingTypesMap,
                thash,
                propertiesOfType.nameType)){
                case null {{properties = propertiesOfType; housingIds = [housingId]}};
                case (?housingType) {
                    let housingIds= Prim.Array_tabulate<HousingId>(
                        housingType.housingIds.size() + 1,
                        func x = if(x == 0) { housingId } else { housingType.housingIds[x - 1] }
                    );
                    {properties = propertiesOfType; housingIds}
                }
            };
        ignore Map.put<Text, {properties: Types.Property; housingIds: [HousingId]}>(
            housingTypesMap, thash, propertiesOfType.nameType, housingType
        );

    };
    
    public shared ({ caller }) func assignHousingType({housingId: HousingId; qty: Nat; propertiesOfType: Types.Property}): async {#Ok; #Err: Text} {
        
        let user = Map.get<Principal, User>(users, phash, caller);
        switch user {
            case null {return #Err(msg.NotUser)};
            case ( ?user ) {
                if (qty < 1) { return #Err(msg.ZeroIsNotAllowed)};
                let housing = Map.get<HousingId, Housing>(housings, nhash, housingId);
                switch housing {
                    case null { #Err(msg.NotHousing)};
                    case ( ?housing ) {
                        if(caller != housing.owner) {
                            return #Err(msg.CallerNotHousingOwner);
                        };
                        let createResponse = createHousingType(caller, propertiesOfType);
                        switch createResponse {
                            case (#Ok) {
                                ignore Map.put<HousingId, Housing>(housings, nhash, housingId, {housing with properties = [propertiesOfType]});
                                // agregamos la habitacion actual al nuevo tipo creado
                                putHousingType(caller, propertiesOfType, housingId);
                                // Clonacion de habitacion segun qty con valores por defecto para las nuevas
                                var index = 1; // la habitacion a partir de la que se define el tipo no se cuenta porque ya tiene su propio id
                                while (index < qty ){
                                    lastHousingId += 1;
                                    let newHousing: Housing = {
                                        housing with
                                        id = lastHousingId;
                                        active = false;
                                        propertiesOfType
                                    };
                                    putHousingType(caller, propertiesOfType, lastHousingId);
                                    ignore Map.put<Principal, User>(users, phash, caller, user );
                                    ignore Map.put<HousingId, Housing>(housings, nhash, lastHousingId, newHousing );

                                    index += 1;
                                };
                                #Ok
                            };
                            case (#Err(msg)) {#Err(msg)}
                        };
                    }
                }
            }
        };
    };

    public shared ({ caller }) func removeHousingType(housingType: Text): async {#Ok; #Err: Text}{
        let myHousingTypesMap = Map.get<Principal, HousingTypesMap>(housingTypesByHostOwner, phash, caller);
        switch myHousingTypesMap {
            case null {#Err("Not housing types")};
            case (?housingTypesMap){
                let removedType = Map.remove<Text, {properties: Types.Property; housingIds: [HousingId]}>(
                    housingTypesMap, thash, housingType
                );
                switch removedType {
                    case null { #Err("Not housing type")};
                    case (?removedType) {#Ok}
                }
            }  
        }
    };

    public shared ({ caller }) func setAmenities(amenities: Types.Amenities, housingId: HousingId): async {#Ok; #Err: Text}{
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
                    {housing with amenities = ?amenities});
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
        #Ok{
            array = Buffer.toArray<Housing>(bufferHousingPreview);
            hasNext = ((page + 1) * qtyPerPage < values.size())
        }
    };

    public shared query ({ caller }) func getCalendarById(id: Nat): async {#Ok: Calendary; #Err: Text}{
        switch (Map.get<HousingId, Housing>(housings, nhash, id)) {
            case (?housing) { 
                if(housing.active) {
                    switch (Map.get<HousingId, Calendary>(calendars, nhash, id)) {
                        case null { return #Err(msg.NotHousing)};    
                        case (?calendar) { return #Ok(calendar) }
                    }
                } else {
                    return #Err(msg.InactiveHousing)
                }
            };
            case null { return #Err(msg.NotHousing)};   
        };
        
    };

    public query func getHousingById({housingId: HousingId;  photoIndex: Nat}): async {#Ok: HousingResponse; #Err: Text} {
        let housing = Map.get<HousingId, Housing>(housings, nhash, housingId);
        return switch housing {
            case null { #Err(msg.NotHousing)};
            case (?housing) {
                if(not housing.active and housing.owner != caller) {
                    return #Err(msg.InactiveHousing)
                };
                if(photoIndex == 0){
                    let housingResponse: HousingResponse = #Start({
                        housing with
                        photos = if(housing.photos.size() > 0) { [housing.photos[0]] } else { [] };
                        hasNextPhoto = (housing.photos.size() > photoIndex + 1)
                    });
                    #Ok(housingResponse);
                } else {
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

  //TODO servicio que devuelva los tipos 

    public shared query ({ caller }) func getMyHousingsByType({housingType: Text; page: Nat}): async ResultHousingPaginate{
        let housingTypeMap = Map.get<Principal, HousingTypesMap>(housingTypesByHostOwner, phash, caller);
        switch housingTypeMap {
            case null {#Err("Not Housing Types")};
            case (?map) {
                let housingsType = Map.get<Text, {properties: Types.Property; housingIds: [HousingId]}>(
                    map,
                    thash,
                    housingType
                );
                switch housingsType {
                    case null { #Err("Not housing type")};
                    case (?housingType) {
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
                            id = ids[index];
                            address = housing.address;
                            thumbnail = housing.thumbnail;
                            price = housing.price;
                        }
                    )
                }
            };
            index += 1;
        };
        let hasNext = ids.size() > (page + 1)* 10;
        #Ok({array = Buffer.toArray<HousingPreview>(resultBuffer); hasNext: Bool});
    };

    func getHousingsPaginateByOwner({owner: Principal; page: Nat}): ResultHousingPaginate {
        let user = Map.get<Principal, User>(users, phash, owner);
        switch user {
            case null { #Err("There is no user associated with the caller")};
            case ( ?user ) {
                for( k in user.kinds.vals()){
                    switch k {
                        case (#Host(hostIds)) {
                            let bufferHousingreview = Buffer.fromArray<HousingPreview>([]);
                            var index = page * 10;
                            while(index < hostIds.size() and index < 10 * (page + 1)){
                                let housing = Map.get<Nat, Housing>(housings, nhash, hostIds[index]);
                                switch housing {
                                    case null{ };
                                    case ( ?housing ) {
                                        let prev: HousingPreview = housing;
                                        bufferHousingreview.add(prev);
                                    }
                                };          
                                index += 1;
                            };
                            return #Ok({array = Buffer.toArray<HousingPreview>(bufferHousingreview); hasNext = hostIds.size() > 10 * (page +1)})
                        };
                        case _ {};
                    }
                };
                #Err("The user is not a hosting type user")
            }
        }
    };

    public shared query ({ caller }) func getMyHousingsPaginate({page: Nat}): async ResultHousingPaginate{
        getHousingsPaginateByOwner({owner = caller; page})
    };

    func updateCalendary(housingId: HousingId, calendary: Calendary): Calendary {
        print("Actualizando calendario");
        let curranDay = now();
        let pastDays = (curranDay - calendary.dayZero) / (24 * 60 * 60 * 1_000_000_000);
        print("Dias pasados: " # Int.toText(pastDays));
        if(pastDays > 0){
            var updateArray = Array.filter<Int>(
                calendary.reservedDays, 
                func(x: Int): Bool {x > pastDays}
            );
            updateArray := Prim.Array_tabulate<Int>(
                updateArray.size(),
                func (x: Nat) = updateArray[x] - pastDays
            );
            let updateCalendar = {dayZero = curranDay; reservedDays = updateArray};
            ignore Map.put<HousingId, Calendary>(calendars, nhash, housingId, updateCalendar);
            return updateCalendar;
        };
        calendary
    };

    func checkDisponibility(housingId: HousingId, chechIn: Int, checkOut: Int): Bool {
        switch (Map.get<HousingId, Housing>(housings, nhash, housingId)) {
            case (?housing) { if(not housing.active) { return false } };
            case  _ { return false }
        };
        switch (Map.get<HousingId, Calendary>(calendars, nhash, housingId)) {
            case null { false };
            case (?calendar) {
                print("Calendario encontrado");
                let updatedCalendary = updateCalendary(housingId, calendar);
                var checkDay = chechIn;
                while (checkDay <= checkOut) {
                    for(occuped in updatedCalendary.reservedDays.vals()){
                        if(checkDay == occuped) {
                            return false;
                        };
                    };
                    checkDay += 1;
                };
                return true
            }
        }
    };

    public shared query ({ caller }) func getMyHousingDisponibility({checkIn: Nat; checkOut: Nat; page: Nat}): async ResultHousingPaginate{
        let response = getHousingsPaginateByOwner({owner = caller; page});
        switch response {
            case (#Ok({array; hasNext} )){
                let bufferResults = Buffer.fromArray<HousingPreview>([]);
                for(hostPreview in array.vals()){
                    if(checkDisponibility(hostPreview.id, checkIn, checkOut)){
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


    // public shared query ({ caller }) func getReservations({housingId: Nat}): async {#Ok: [(Nat, Reservation)]; #Err: Text}{
    //     let housing = Map.get<HousingId, Housing>(housings, nhash, housingId);
    //     switch housing {
    //         case null {#Err(msg.NotHousing)};
    //         case ( ?housing ) {
    //             if(housing.owner != caller ){
    //                 return #Err(msg.CallerNotHousingOwner);
    //             };
    //             #Ok(Map.toArray<Nat, Reservation>(housing.reservationRequests))
    //         }
    //     }
    // };

  ///////////////////////////////// Reservations ///////////////////////////////////////////

    // public shared ({ caller }) func requestReservationOld({housingId: HousingId; data: ReservationDataInput}):async ReservationResult {
    //     let housing = Map.get<HousingId, Housing>(housings, nhash, housingId);
    //     switch housing {
    //         case null {
    //             #Err(msg.NotHosting);
    //         };
    //         case (?housing) {
    //             print("housing");
    //             /////// housing calendar update / housing Map update //////
    //             let calendar = updateCalendar(housing.calendar);
    //             ignore Map.put<HousingId, Housing>(housings, nhash, housingId, {housing with calendar});

    //             ///////////////////////////////////////////////////// DEBUGIN //////////////////////////////////////////////////////////
    //             print("Momento actual en NanoSeg:  " # Int.toText(now()));
    //             print("horas de anticipacio:       " # Int.toText(housing.minReservationLeadTimeNanoSec ));
    //             print("Reserva a partir de fecha:  " # Int.toText((now() + housing.minReservationLeadTimeNanoSec)));
    //             print("Fecha de ingreso silicitada " # Int.toText(data.checkIn));
    //             ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    //             if(now() + housing.minReservationLeadTimeNanoSec > data.checkIn){ 
    //                 return #Err("Reservations are requested at least " #
    //                 Int.toText(housing.minReservationLeadTimeNanoSec /(NANO_SEG_PER_HOUR)) #
    //                 " hours in advance.");
    //             };
    //             if(availableAllDaysResquest(data.checkIn, data.checkOut)){
    //                 let reservationId = await ramdomGenerator.randRange(1_000_000_000, 9_999_999_999);
    //                 let reservation = {data with applicant = caller};
    //                 let responseReservation = {
    //                     reservationId;
    //                     msg = "Espere"
    //                 };
    //                 ignore Map.put<Nat, Reservation>(housing.reservationRequests, nhash, reservationId, reservation );
    //                 #Ok( responseReservation )
    //             } else {
    //                 #Err( msg.NotAvalableAllDays);
    //             }
    //         };
    //     }    
    // };

    // public shared ({ caller }) func requestReservation({housingId: HousingId; data: ReservationDataInput}): async ReservationResult{
    //     let housing = Map.get<HousingId, Housing>(housings, nhash, housingId);
    //     switch housing {
    //         case null {
    //             #Err(msg.NotHosting);
    //         };
    //         case (?housing) {
    //             print("housing");
    //             /////// housing calendar update / housing Map update //////
    //             let calendar = updateCalendar(housing.calendar);
    //             ignore Map.put<HousingId, Housing>(housings, nhash, housingId, {housing with calendar});

    //             ///////////////////////////////////////////////////// DEBUGIN //////////////////////////////////////////////////////////
    //             print("Momento actual en NanoSeg:  " # Int.toText(now()));
    //             print("horas de anticipacio:       " # Int.toText(housing.minReservationLeadTimeNanoSec ));
    //             print("Reserva a partir de fecha:  " # Int.toText((now() + housing.minReservationLeadTimeNanoSec)));
    //             print("Fecha de ingreso silicitada " # Int.toText(data.checkIn));
    //             ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    //             if(now() + housing.minReservationLeadTimeNanoSec > data.checkIn){ 
    //                 return #Err("Reservations are requested at least " #
    //                 Int.toText(housing.minReservationLeadTimeNanoSec /(NANO_SEG_PER_HOUR)) #
    //                 " hours in advance.");
    //             };
    //             if(availableAllDaysResquest(data.checkIn, data.checkOut)){
    //                 let reservationId = await ramdomGenerator.randRange(1_000_000_000, 9_999_999_999);
    //                 let reservation = {data with applicant = caller};
    //                 let responseReservation = {
    //                     housingId;
    //                     reservationId;
    //                     data = reservation;
    //                     msg = msg.PayRequest;
    //                     paymentCode = await ramdomGenerator.randRange(1_000_000_000_000_000_000_000, 9_999_999_999_999_999_999_999)
    //                 };
    //                 ignore Map.put<Nat, Reservation>(housing.reservationRequests, nhash, reservationId, reservation );
    //                 #Ok( responseReservation )
    //             } else {
    //                 #Err( msg.NotAvalableAllDays);
    //             }
    //         };
    //     }
    // };
    // func paymentVerification(txHash: Nat):async Bool{
    //     // TODO protocolo de verificacion de pago
    //     true
    // };

    // public shared ({ caller }) func confirmReservation({reservId: Nat; hostId: HousingId; txHash: Nat}): async {#Ok; #Err: Text}{
    //     let housing = Map.get<HousingId, Housing>(housings, nhash, hostId);
    //     switch housing {
    //         case null { #Err(msg.NotHosting) };
    //         case ( ?housing ) {
    //             let updatedCalendar = updateCalendar(housing.calendar);
    //             ignore Map.put<HousingId, Housing>(housings, nhash, hostId, {housing with updatedCalendar}); 
    //             let reserv = Map.remove<Nat, Reservation>(housing.reservationRequests, nhash, reservId);
    //             switch reserv {
    //                 case null { #Err(msg.NotReservation) };
    //                 case ( ?reserv ) {
    //                     if(caller != reserv.applicant) {
    //                         return #Err(msg.CallerIsNotrequester)
    //                     };
    //                     // TODO Verificacion datos de pago a traves del txHhahs
    //                     if (await paymentVerification(txHash)){
    //                         print("insertando la reserva en el calendario");
    //                         let calendar = insertReservationToCalendar(updatedCalendar, reserv);
    //                         switch calendar {
    //                             case (#Ok(calendar)) {

    //                                 ignore Map.put<HousingId, Housing>(housings, nhash, hostId, {housing with calendar});
    //                                 return #Ok
    //                             };
    //                             case (_) { 
    //                                 ignore Map.put<Nat, Reservation>(housing.reservationRequests, nhash, reservId, reserv);
    //                                 return #Err("Error") 
    //                             }
    //                         }
    //                     };
    //                     #Err("Incorrect payment verification")
    //                 }
    //             }
    //         }
    //     }
    // };

    // // TODO confirmacion de reservacion por parte del dueño del Host
    // public shared ({ caller }) func confirmReservation({reservId: Nat; hostId: HousingId}): async (){
        
    // };


};

