import Map "mo:map/Map";
import Nat "mo:base/Nat";
import List "mo:base/List";

module {

    ///////////////////////////////// Settings ///////////////////////////////////

    public type Settings = {
        cancellationFeeCompensateBuyer: Nat64;
        minDaysBeforeCheckinForCancellation: Nat;
        timeToPay: Nat;
        reservationFee: Nat64;
    };

    ///////////////////////////////// Users /////////////////////////////////////

    public type SignUpData = {
        firstName: Text;
        lastName: Text;
        phone: ?Nat;
        email: Text;
        referralBy: ?Nat32;
    };

    public type UserData = {
        firstName: Text;
        lastName: Text;
    };

    public type User = SignUpData and {
        verified: Bool;
        reservations: List.List<Nat>;
        score: Nat;
        reviewsIssued: List.List<Nat>;
    };

    public type HostUser = SignUpData and {
        verified: Bool;
        score: Nat;
        housingIds: List.List<Nat>;
        housingTypes: Map.Map<Text, HousingType>;
    };

    public type SignUpResult = {
        #Ok: UserData;
        #Err: Text;
    };

    public type Review = {
        autor: Principal;
        hostId: Nat;
        date: Int;
        body: Text;
    };

    ///////////////////////////////// Housing ///////////////////////////////////

    public type HousingCreateData = {
        namePlace: Text;
        nameHost: Text;
        descriptionPlace: Text;
        descriptionHost: Text;
        link: Text;
        photos: [Blob];
        thumbnail: Blob;
    };

    public type Housing = HousingCreateData and {
        active: Bool;
        housingId: Nat;
        price: ?Price;
        owner: Principal;
        rules: [Rule];
        checkIn: Nat;
        checkOut: Nat;
        address: Location;
        properties: ?HousingType;
        housingType: ?Text;
        amenities: ?Amenities;
        encodedAmenities: Nat64;
        encodedAmenities2: Nat64; // Prueba
        reviews: List.List<Nat>;
        calendary: Calendary;
        reservationsPending: [Nat];
        unavailability : {busy: [Int]; pending: [Int]} 
    };

    public type HousingTypeInit = {
        nameType: Text;
        beds: [BedKind];
        bathroom: [Bathroom];
        maxGuest: Nat;
        extraGuest: Nat;
    };

    public type HousingType = HousingTypeInit and {
        housingIds: [HousingId];
    };

    public type HousingId = Nat;

    public type HousingPreview = {
        active: Bool;
        housingId: Nat;
        address: Location;
        thumbnail: Blob;
        price: ?Price;
        encodedAmenities: Nat64;
    };

    public type HousingResponse = {
        #Start: Housing and {
            hasNextPhoto: Bool;
        };
        #OnlyPhoto: {
            photo: Blob;
            hasNextPhoto: Bool;
        };
    };

    public type Bathroom = {
        toilette: Bool;
        shower: Bool;
        bathtub: Bool;
        isShared: Bool;
        sink: Bool;
    };

    public type Rule = {
        #PetsAllowed: Bool;
        #SmookingAllowed: Bool;
        #PartiesAllowed: Bool;
        #AdditionalGuests: Bool;
        #NoiseAfter10pm: Bool;
        #ParkOnTheStreet: Bool;
        #VisitsAllowed: Bool;
        #CustomRule: {rule: Text; allowed: Bool};
    };

    public type BedKind = {
        #Single: Nat;
        #Matrimonial: Nat;
        #SofaBed: Nat;
    };

    public type Amenities = {
        //
        freeWifi: Bool;
        airCond: Bool;         // Aire acondicionado
        flatTV: Bool;          // TV de pantalla plana
        minibar: Bool;
        safeBox: Bool;         // Caja de seguridad
        roomService: Bool;     // Servicio a la habitación
        premiumLinen: Bool;    // Ropa de cama premium
        ironBoard: Bool;       // Plancha y tabla de planchar
        privateBath: Bool;     // Baño privado con artículos de tocador
        hairDryer: Bool;       // Secador de pelo
        hotelRest: Bool;       // Restaurante en el hotel
        barLounge: Bool;       // Bar y lounge
        buffetBrkfst: Bool;    // Desayuno buffet
        lobbyCoffee: Bool;     // Servicio de café/té en el lobby
        catering: Bool;        // Servicio de catering para eventos
        specialMenu: Bool;     // Menú para dietas especiales (bajo solicitud)
        outdoorPool: Bool;     // Piscina al aire libre
        spaWellness: Bool;     // Spa y centro de bienestar
        gym: Bool;
        jacuzzi: Bool;
        gameRoom: Bool;        // Salón de juegos
        tennisCourt: Bool;     // Pista de tenis
        natureTrails: Bool;    // Acceso a senderos naturales
        custom: [{amenitieName: Text; value: Bool}];
    };

    public type Amenities2 = [Text]; // Eventualmente se pueden establecer las amenidades dinamicamente
    public let amenitiesArray = ["freeWifi", "airCond", "flatTV", "minibar", "safeBox", "roomService", "premiumLinen", "ironBoard", "privateBath", "hairDryer", "hotelRest", "barLounge",
        "buffetBrkfst", "lobbyCoffee", "catering", "specialMenu", "outdoorPool", "spaWellness", "gym", "jacuzzi", "gameRoom", "tennisCourt", "natureTrails"];

    public type Location = {
        country: Text;
        city: Text;
        neighborhood: Text;
        zipCode: Nat;
        street: Text;
        externalNumber: Nat;
        internalNumber: Nat;
        geolocation: ?{lat: Int; lng: Int}
    };

    public type Price = {
        base: Nat;
        discountTable: [{minimumDays: Nat; discount: Nat}]; // Ej. [{minimumDays = 5; discount = 10}, {minimumDays = 15; discount = 15}]
    };

    ////////////////////////////// Referrals ///////////////////////////////////

    public type Refered = {
        date: Int;
        user: Principal; 
        kind: ReferalKind
    };

    public type ReferalKind = {
        #User: StatusReferral; 
        #Host: StatusReferral
    };

    public type ReferralBook = {
        owner: Principal;
        refereds: [Refered];
    };
    public type StatusReferral = {
        #Level1;
        #Level2;
        #Level3;
        #Level4;
        #Level5;
    };


    ////////////////////////////// Reservations ////////////////////////////////

    public type Calendary = {
        dayZero: Int;
        reservations: [Reservation];
    };

    public type ReservationDataInput = {
        housingId: HousingId;
        checkIn: Int;    // Número de día de ingreso. Siendo 0 el día actual
        checkOut: Int;   // El egreso tiene que ser mayor que 1 + el ingreso
        guest: Text;     // Nombre del huésped
        email: Text;
        phone: Nat;
    };

    public type ReservationStatus = {
        #Pending;
        #Confirmed;
        #Canceled;
        #InProgress;
        #Ended;
    };

    public type Reservation = ReservationDataInput and {
        date: Int;
        timestampCheckIn: Int;
        // checkIn: Int;   // Int es un supertipo de Nat por lo tanto no hay conflicto con el checkIn que se "hereda" de ReservationDataInput y queda como Int
        // checkOut: Int;  // Idem
        reservationId: Nat;
        requester: Principal;
        ownerHousing: Principal;
        // confirmated: Bool;
        status: ReservationStatus;
        amount: Nat64;
        dataTransaction: DataTransaction;
    };

    public let NullTrx: DataTransaction = {
        from = "";
        to = "";
        amount = 0
    };

    public type TransactionParams = {
        to: Text;
        amount: Nat64;
    };

    public type DataTransaction = TransactionParams and {
        from: Text;
    };

    public type TransactionResponse = {
        #Ok: {transactionParams: TransactionParams; reservationId: Nat};
        #Err: Text;
    };

    ///////////////////////////////// General ///////////////////////////////////

    public type UpdateResult = {
        #Ok;
        #Err: Text;
    };

}
