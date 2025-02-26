import Map "mo:map/Map";
import Nat "mo:base/Nat";
module {
  ////////////////////////////// Users /////////////////////////////////////

    public type SignUpData = {
        firstName: Text;
        lastName: Text;
        phone: ?Nat;
        email: Text;
        //avatar: ?Blob;
    };

    public type User = SignUpData and {
        // id: Nat;
        kinds: [UserKind];
        // userKind: UserKind;
        verified: Bool;
        score: Nat;    
    };

    public type UserKind = {
        #Initial;
        #Guest: [ReviewsId];
        #Host: [HousingId];
    };

    public type SignUpResult = { #Ok : User; #Err : Text };
    
    // type GetProfileError = {
    //     #userNotAuthenticated;
    //     #profileNotFound;
    // };

    // type CreateProfileError = {
    //     #profileAlreadyExists;
    //     #userNotAuthenticated;
    // };

  ///////////////////////////////// Housing /////////////////////////////////


    public type HousingCreateData = {
        namePlace: Text;
        nameHost: Text;
        descriptionPlace: Text;
        descriptionHost: Text;
        link: Text;
        photos: [Blob];
        thumbnail: Blob;

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

    public type Amenities = {
        freeWifi: Bool;
        airCond: Bool; // Aire acondicionado
        flatTV: Bool; // TV de pantalla plana
        minibar: Bool;
        safeBox: Bool; // Caja de seguridad
        roomService: Bool; // Servicio a la habitación
        premiumLinen: Bool; // Ropa de cama premium
        ironBoard: Bool; // Plancha y tabla de planchar
        privateBath: Bool; // Baño privado con artículos de tocador
        hairDryer: Bool; // Secador de pelo
        hotelRest: Bool; // Restaurante en el hotel
        barLounge: Bool; // Bar y lounge
        buffetBrkfst: Bool; // Desayuno buffet
        lobbyCoffee: Bool; // Servicio de café/té en el lobby
        catering: Bool; // Servicio de catering para eventos
        specialMenu: Bool; // Menú para dietas especiales (bajo solicitud)
        outdoorPool: Bool; // Piscina al aire libre
        spaWellness: Bool; // Spa y centro de bienestar
        gym: Bool;
        jacuzzi: Bool;
        gameRoom: Bool; // Salón de juegos
        tennisCourt: Bool; // Pista de tenis
        natureTrails: Bool; // Acceso a senderos naturales
        custom: [{amenitieName: Text; value: Bool}];
    };

    public type Location = {
        country: Text;
        city: Text;
        neighborhood: Text;
        zipCode: Nat;
        street: Text;
        externalNumber: Nat;
        internalNumber: Nat;
    };

    public type Housing = HousingCreateData and {
        active: Bool;
        id: Nat;
        price: ?Price;
        owner: Principal;
        rules: [Rule];
        checkIn: Int;
        checkOut: Int;
        address: Location;
        properties: [Property];
        amenities: ?Amenities;
    };

    public type Bathroom = {
        toilette: Bool;
        shower: Bool;
        bathtub: Bool;
        isShared: Bool;
        sink: Bool;
    };
    public type Property = {
        nameType: Text;
        beds: [BedKind]; 
        bathroom: Bathroom;
        maxGuest: Nat;
        extraGuest: Nat;
    };

    // public type HousingDataInit = {
    //     minReservationLeadTimeNanoSec: Int; //valor en nanoSeg de anticipación para efectuar una reserva
    //     address: Text;
    //     prices: [Price];
    //     kind: HousingKind;
    //     maxCapacity: Nat;
    //     description: Text;
    //     rules: [Text];
    //     amenities: [Text];
    //     properties: [Property];
    // };

    // public type Housing = HousingDataInit and {

    //     id: Nat; // Example L234324
    //     owner: Principal;
    //     calendar: [var CalendaryPart];
    //     reservationRequests: Map.Map<Nat, Reservation>;
    //     reviews: [Text];
    //     photos: [Blob];
    //     thumbnail: Blob; // Se recomienda la foto principal en tamaño reducido
    //     active: Bool;
    // };

    type BedKind = {
        #Single: Nat;
        #Matrimonial: Nat;
        #SofaBed: Nat;
        // Agregar mas variantes
    };

    public type HousingResponse = {
        #Start : Housing and {
            hasNextPhoto: Bool;
        };
        #OnlyPhoto :{
            photo: Blob;
            hasNextPhoto: Bool;
        }
    };

    public type HousingPreview = {
        active: Bool;
        id: Nat;
        address: Location;
        thumbnail: Blob;
        price: ?Price;
    };

    public type HousingId = Nat;

    public type UpdateResult = {
        #Ok;
        #Err: Text;
    };

    // public type HousingKind = {
    //     #House;
    //     #Hotel_room: Text; //Ejemplo #Hotel_room("Single Room")
    //     #RoomWithSharedSpaces: [Rule]; //Hostels/Pensiones
    // };

    // public type Price = {
    //     #PerNight: Nat;
    //     #PerWeek: Nat;
    //     #CustomPeriod: [{dais: Nat; price: Nat}];
    // };

    public type Price = {
        base: Nat; // price per nigth
        discountTable: [{minimumDays: Nat; discount: Nat}]; // Ej. [{minimumDays = 5; discount = 10}, {minimumDays = 15; discount = 15}]
    };

    // public type Rules = { // Ejemplo de Rule: {key = "Horarios"; value = "Sin ruidos molestos entre las 22:00 y las 8:00"}
    //     key: Text;
    //     value: Text
    // };

    public type ReviewsId = Text;
  ///////////////////////////////// Reservations /////////////////////////////

    public type ReservationDataInput = {
        checkIn: Int;   //Timestamp NanoSeg
        checkOut: Int;  //Temestamp NanoSeg
        guest: Text;
    };
        
    public type Reservation = ReservationDataInput and {
        applicant: Principal;
    };

    // La primer posicion es siempre el dia actual con lo cual cada vez que se consulta se tiene que actualizar antes
    // Para facilitar la implementacion inicial se considera una lista de Disponibility mutable de 30 posiciones
    // public type Disponibility = {day: Int; available: Bool};


    // public type CalendaryPart = Disponibility and {reservation: ?Reservation};




} 

    