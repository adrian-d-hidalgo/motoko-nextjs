# #!/bin/bash
# # ------------ Usuario deployer ------------
# dfx identity new 0000TestUser0
# dfx identity use 0000TestUser0
# dfx deploy backend

# ------------ Usuario Host 1 --------------
dfx identity new 0000TestUser1
dfx identity use 0000TestUser1
echo "registro de User Host Alberto Campos ... "
dfx canister call backend signUpAsHost '(record {
    firstName="Alberto";
    lastName="Campos";
    email="null";
    phone = opt 542238780892;
    referralBy = null;
})'
# CreateHousing 1
echo "Alberto registra un housing ... "
dfx canister call backend createHousing '(record {
    namePlace="Far West";
    nameHost="Alberto Campos";
    descriptionPlace="Lugar tranquilo y seguro";
    descriptionHost="Al lado de Far West disco bar y apuestas";
    link="https://media.istockphoto.com/id/2045383950/photo/digital-render-of-a-serene-bedroom-oasis-with-natural-light.jpg?s=2048x2048&w=is&k=20&c=2Rw4fqnC08kfiuc58jhzbCAOYwPp9V8w4e3Ma2TY984=";
    photos = vec {};
    thumbnail = blob "Qk06AAAAAAAAADYAAAAoAAAAAQAAAAEAAAABAAEAAAA"
})'
# Update Prices housing 1
echo "Alberto setea el precio del housing de id 1, o sea el que acaba de crear ... "
dfx canister call backend updatePrices '(record {
    id = 1 : nat;
    price = record {
      base = 100_000_000 : nat; 
      discountTable = vec {
        record { minimumDays = 5 : nat; discount = 5 : nat };
        record { minimumDays = 10 : nat; discount = 15 : nat };
      };
    }
})'

dfx canister call backend setAmenities '( record { 
    freeWifi = false; 
    airCond = false; 
    flatTV = false; 
    minibar = true; 
    safeBox = false; 
    roomService = false; 
    premiumLinen = false; 
    ironBoard = false; 
    privateBath = false; 
    hairDryer = true; 
    hotelRest = false; 
    barLounge = false; 
    buffetBrkfst = false; 
    lobbyCoffee = false; 
    catering = false; 
    specialMenu = false; 
    outdoorPool = false; 
    spaWellness = false; 
    gym = false; 
    jacuzzi = true; 
    gameRoom = false; 
    tennisCourt = false; 
    natureTrails = false; 
    custom = vec {}; 
}, 1)'




#Assing housing Type
echo "Alberto crea un tipo de habitacion a partir de su housing de id 1 indicando que existen 4 ... "
dfx canister call backend cloneHousingWithProperties '(record {
  housingId = 1 : nat;
  qty = 1 : nat;
  housingTypeInit = record {
    extraGuest = 2 : nat;
    bathroom = vec {record {
      shower = true;
      sink = true;
      toilette = true;
      isShared = false;
      bathtub = true;
    }};
    beds = vec { variant { Matrimonial = 1 : nat } };
    maxGuest = 4 : nat;
    nameType = "Standard";
  };
})'

#Set Address Housing 1
echo "Alberto establece la dirección de su housing de id 1"

dfx canister call backend setAddress '(record {
  housingId = 1 : nat;
  address = record {
    street = "9 de Julio";
    externalNumber = 1207;
    internalNumber = 43;
    city = "Mar del Plata";
    neighborhood = "Centro";
    country = "Argentina";
    zipCode = 7600 ;
  };
})'

echo "Alberto publica su housing de id 1 ..." 
dfx canister call backend publishHousing 1

# CreateHousing 2
echo "Alberto crear otro housing ..." 
dfx canister call backend createHousing '(record {
    namePlace="";
    nameHost="Alberto Campos";
    descriptionPlace="Lugar tranquilo y seguro";
    descriptionHost="Espacioso y luminoso con vista al mar";
    link="https://media.istockphoto.com/id/1837566278/photo/scandinavian-style-apartment-interior.jpg?s=2048x2048&w=is&k=20&c=ZT-ZoefdikBU9DhdEg4fV6bW-SdZi_HLRFg_mupNd9E=";
    photos = vec {};
    thumbnail = blob "Qk06AAAAAAAAADYAAAAoAAAAAQAAAAEAAAABAAEAALKLKAKHUJHAA"
})'

echo codigo de referidos de alberto...
export albertoCode=$(dfx canister call backend getMyReferralCode)
echo $albertoCode



# ------------ Usuario Host 2 -------------- 
dfx identity new 0000TestUser2
dfx identity use 0000TestUser2
echo "se registra una usuario llamada Lucila..."
dfx canister call backend signUpAsUser '(record {
    firstName="Lucila";
    lastName="Peralta";
    email="lucilaperalta@live.com";
    phone = opt 542298712438
})'

# ------------ Usuario Host 3 --------------
echo "se registra una  UserHost llamada Claudia..."
dfx identity new 0000TestUser3
dfx identity use 0000TestUser3
dfx canister call backend signUpAsHost '(record {
    firstName="Claudia";
    lastName="Gimenez";
    email="claugimenez@gmail.com";
    phone = opt 558789878522;
})'

# ------------ Usuario Host 4 -------------- 
dfx identity new 0000TestUser4
dfx identity use 0000TestUser4
echo "se registra un usuario llamado Mario..."
dfx canister call backend signUpAsUser '(record {
    firstName="Mario";
    lastName="Pappa";
    email="mariopapa@gmail.com";
    phone = opt 542235227692;
})'

# ------------ Usuario Host 5 -------------- 
dfx identity new 0000TestUser5
dfx identity use 0000TestUser5
echo "se registra un  UserHost llamado Rodolfo..."
dfx canister call backend signUpAsHost '(record {
    firstName="Rodolfo";
    lastName="Anchorena";
    email="rodolfoanchorena.com";
    phone = opt 542278795421
})'

# ------------ Usuario Host 6 -------------- 
dfx identity new 0000TestUser6
dfx identity use 0000TestUser6
dfx canister call backend signUpAsUser '(record {
    firstName="Carlos";
    lastName="Maldonado";
    email="carlosmaldonado.com";
    phone = opt 5422145789544
})'

# ------------ Usuario 4 solicita una reserva de 6 dias para dentro de 3 dias
dfx identity use 0000TestUser4
dfx canister call backend requestReservation '(record {
  housingId = 1; 
  checkIn = 7; 
  checkOut = 10; 
  guest = "Mario";
  email = "mario@gmil.com";
  phone = 542236676567
})'

# ------------ Usuario 4 confirma la reserva

dfx canister call backend confirmReservation '(record {
  reservationId  = 1; 
  txData = record {
    to = "walletHousingInRequest"; 
    amount = 4_000_000_000; 
    from = "walletUser"
  }
})'
# ------------ Usuario 2 pide reserva para dentro de 12 dias y se queda 3

dfx identity use 0000TestUser2
dfx canister call backend requestReservation '(record {
  housingId = 1; 
  checkIn = 12; 
  checkOut = 14; 
  guest = "Lucila";
  email = "cucila@gmil.com";
  phone = 556578787998
})'

# ------------ Usuario 2 confirma la reserva

dfx canister call backend confirmReservation '(record {
  reservationId  = 2; 
  txData = record {
    to = "walletHousingInRequest"; 
    amount = 4_000_000_000; 
    from = "walletUser"
  }
})'
# ------------ Usuario 6 pide reserva para dentro de 9 dias y se queda 2

dfx identity use 0000TestUser6
dfx canister call backend requestReservation '(record {
  housingId = 1; 
  checkIn = 21; 
  checkOut = 31; 
  guest = "Carlos";
  email = "carlos@gmil.com";
  phone = 536657090
})'


# ------------ Usuario 6 confirma la reserva
dfx canister call backend confirmReservation '(record {
  reservationId  = 4; 
  txData = record {
    to = "walletHousingInRequest"; 
    amount = 4_000_000_000; 
    from = "walletUser"
  }
})'