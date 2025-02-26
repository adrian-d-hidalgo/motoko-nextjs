``` 
dfx deploy backend

```
registro de usuario huesped general:

```
dfx canister call backend signUp '(record { 
        firstName="Juan";
        lastName="Perez";
        phone= null;
        email="juanperez@gmail.com"; 
    }
)'
```

registro de usuario tipo Host

```
dfx canister call backend signUpAsHost '(record { 
        firstName="Gerardo";
        lastName="Anchorena";
        phone= opt 54221548797;
        email="gerardonchorena@gmail.com";  
    }
)'
```

publicacion de hosting

```
dfx canister call backend publishHousing '(record {
    minReservationLeadTimeNanoSec = 86400000000000;
    address = "San Martin 555";
    description= "Vista al mar, 56 Mts2, silencioso";
    maxCapacity= 6;
    amenities = vec{"Jacuzzi"; "Piscina"; "Gimnasio"};
    rules = vec {"No fumar"};
    
    prices = vec {
        variant {PerNight = 90};
        variant {PerWeek = 550};
        variant {CustomPeriod = vec {
                record {dais = 15; price = 1000};
                record {dais = 30; price = 1900};
            }
        }
    }; 
    kind = variant {House};
    properties = record{
        beds= vec{
            variant {Single = 2};
            variant {SofaBed = 2}
        };
        bathroom = true 
    };
}
)'
```

agregar foto a publicacion

```
dfx canister call backend addPhotoToHousing '(record {
    id = 1; 
    photo = blob "00/11/22/33/44/"}
)'
```

agregar foto miniatura (foto principal de tamaño reducido)

```
dfx canister call backend addThumbnailToHousing '(record {
    id = 1; 
    thumbnail = blob "00/66/88/44/45/98/45/98"}
)'
```

actualizacion de precios

```
dfx canister call backend updatePrices '(record {
    id = 1;
    prices = vec {
        variant {PerNight = 400};
        variant {PerWeek = 2800};
    }
})'
```
Set amenities

```
dfx canister call backend setAmenities '( record { 
    freeWifi = false; 
    airCond = false; 
    flatTV = false; 
    minibar = true; 
    safeBox = false; 
    roomService = false; 
    premiumLinen = false; 
    ironBoard = false; 
    privateBath = true; 
    hairDryer = false; 
    hotelRest = false; 
    barLounge = false; 
    buffetBrkfst = false; 
    lobbyCoffee = false; 
    catering = true; 
    specialMenu = false; 
    outdoorPool = false; 
    spaWellness = false; 
    gym = false; 
    jacuzzi = false; 
    gameRoom = true; 
    tennisCourt = false; 
    natureTrails = false; 
    custom = vec {}; 
}, 1)'

```
Solicitud de reserva

```
dfx canister call backend requestReservation '(record {
  housingId = 1; 
  checkIn = 9; 
  checkOut = 11; 
  guest = "Carlos"
})'


dfx canister call backend confirmReservation '(record {
  reservationId  = ; 
  txData = record {
    to = ""; 
    amount = 4_000_000_000; 
    from = ""
  }
})'

```
