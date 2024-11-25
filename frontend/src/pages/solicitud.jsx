import Image from "next/image";
import { useState } from "react";

function Dashboard() {
  const [selectedOption, setSelectedOption] = useState("Solicitudes");
  const iconMapping = {
    Solicitudes: "/images/iconSolicitude.svg",
    "Detalles de la propiedad": "/images/iconProperty.svg",
    Disponibilidad: "/images/iconDisponibility.svg",
    "Datos de pago": "/images/iconPayment.svg",
  };

  const renderContent = () => {
    switch (selectedOption) {
      case "Solicitudes":
        return <SolicitudesComponent />;
      case "Detalles de la propiedad":
        return <DetallesPropiedadComponent />;
      case "Disponibilidad":
        return <DisponibilidadComponent />;
      case "Datos de pago":
        return <DatosPagoComponent />;
      default:
        return null;
    }
  };

  return (
    <div className="flex flex-col">
      <div className="h-[92px] bg-white pl-5 flex items-center">
        <Image src="/images/logo.svg" width={203} height={48} alt="Logo" />
      </div>

      <div className="bg-[#E3EFFD] flex flex-col px-12 py-6 h-[calc(100vh-92px)]">
        <span className="text-sm font-normal text-[#0F172A] mt-4 mb-6">
          Mis propiedades | Hotel verde | <strong>Solicitudes</strong>
        </span>

        <div className="flex">
          <div className="w-[239px] flex flex-col gap-3">
            {Object.keys(iconMapping).map((option) => (
              <div
                key={option}
                className={`flex items-center border-l-2 h-[40px] px-2 gap-2 cursor-pointer ${
                  selectedOption === option ? "border-[#3581EC] bg-[#FFFFFF]" : "border-[#1C1E21]"
                }`}
                onClick={() => setSelectedOption(option)}>
                <Image src={iconMapping[option]} width={24} height={24} alt={`${option} Icon`} />
                <span className="text-sm font-normal text-[#1C1E21]">{option}</span>
              </div>
            ))}
          </div>

          {renderContent()}
        </div>
      </div>
    </div>
  );
}

function SolicitudesComponent() {
  return (
    <>
      <div className="flex flex-col w-full px-5 py-10 gap-1 ">
        <div className="flex flex-col w-full h-52 px-8 py-6 gap-3 bg-white border border-[#EBF0F8] rounded-2xl">
          <span className="text-sm font-semibold text-[#000000]">
            Habitación categoría “Vista a la calle sencilla”
          </span>
          <span className="text-sm font-semibold text-[#1C1E21]">Total $600 + IVA</span>
          <span className="text-sm font-normal text-[#0F172A]">Dom 25/10/2024 - Dom 31/10/2024</span>
          <span className="text-sm font-normal text-[#1C1E21]">2 Adultos, 1 niño</span>
          <span className="text-sm font-normal text-[#3581EC] ml-2 underline hover:cursor-pointer">
            Ver detalles
          </span>
        </div>
        <div className="flex flex-col w-full h-52 px-8 py-6 gap-3 bg-white border border-[#EBF0F8] rounded-2xl">
          <span className="text-sm font-semibold text-[#000000]">
            Habitación categoría “Vista a la calle sencilla”
          </span>
          <span className="text-sm font-semibold text-[#1C1E21]">Total $600 + IVA</span>
          <span className="text-sm font-normal text-[#0F172A]">Dom 25/10/2024 - Dom 31/10/2024</span>
          <span className="text-sm font-normal text-[#1C1E21]">2 Adultos, 1 niño</span>
          <span className="text-sm font-normal text-[#3581EC] ml-2 underline hover:cursor-pointer">
            Ver detalles
          </span>
        </div>
        <div className="flex flex-col w-full h-52 px-8 py-6 gap-3 bg-white border border-[#EBF0F8] rounded-2xl">
          <span className="text-sm font-semibold text-[#000000]">
            Habitación categoría “Vista a la calle sencilla”
          </span>
          <span className="text-sm font-semibold text-[#1C1E21]">Total $600 + IVA</span>
          <span className="text-sm font-normal text-[#0F172A]">Dom 25/10/2024 - Dom 31/10/2024</span>
          <span className="text-sm font-normal text-[#1C1E21]">2 Adultos, 1 niño</span>
          <span className="text-sm font-normal text-[#3581EC] ml-2 underline hover:cursor-pointer">
            Ver detalles
          </span>
        </div>
      </div>

      <div className="flex flex-col fixed right-0 top-[94px] h-[calc(100vh-94px)] w-[440px] rounded-tl-[24px] rounded-bl-[24px] bg-[#FFFFFF] px-6 py-8 border border-[#E3EFFD]">
        <div>
          <Image src="/images/iconSolicitude.svg" width={32} height={32} alt="Solicitudes Icon" />
          <span className="text-xl font-bold text-[#1C1E21]">Detalles de reservación</span>
          <div className="flex flex-col w-[381px] rounded-2xl p-4 mt-6 border border-[#64748B] hover:border-[#3581EC]">
            <span className="text-sm font-semibold text-[#1C1E21]">Huésped</span>
            <span className="text-sm font-normal text-[#64748B]">
              Carlos Carrera
              <br />
              Llegada 25/10/2024
              <br />
              Salida 31/10/2024
              <br />2 adultos, 1 niño, 2 perros
            </span>
            <span className="text-sm font-normal text-[#64748B] my-3">Contacto</span>
            <div className="flex">
              <Image src="/images/iconPhone.svg" width={24} height={24} alt="Phone Icon" />
              <span className="text-sm font-normal text-[#64748B]">(+52) 123 456 7890</span>
            </div>
            <div className="flex">
              <Image src="/images/iconEmail.svg" width={24} height={24} alt="Email Icon" />
              <span className="text-sm font-normal text-[#64748B]">hola@hotelverde.com</span>
            </div>
          </div>

          <div className="flex flex-col w-[381px] rounded-2xl p-4 mt-6 border border-[#64748B] hover:border-[#3581EC]">
            <span className="text-sm font-semibold text-[#1C1E21]">Cliente</span>
            <span className="text-sm font-normal text-[#64748B]">
              Carlos Carrera
              <br />
              Pago mediante Tarjeta de crédito $696 MXN
            </span>
            <span className="text-sm font-normal text-[#20961E]">Pago confirmado</span>
            <span className="text-sm font-normal text-[#64748B] my-3">Contacto</span>
            <div className="flex">
              <Image src="/images/iconPhone.svg" width={24} height={24} alt="Phone Icon" />
              <span className="text-sm font-normal text-[#64748B]">(+52) 123 456 7890</span>
            </div>
            <div className="flex">
              <Image src="/images/iconEmail.svg" width={24} height={24} alt="Email Icon" />
              <span className="text-sm font-normal text-[#64748B]">hola@hotelverde.com</span>
            </div>
          </div>

          <button className="h-12 w-full flex items-center justify-center rounded-lg bg-[#0F172A] transition-colors duration-150 ease-in-out mt-14">
            <span className="text-sm font-normal text-[#E3EFFD]">Aceptar</span>
          </button>
          <button className="h-12 w-full flex items-center justify-center rounded-lg border border-[#1C1E21] bg-[#FFFFFF] mt-3">
            <span className="text-sm font-normal text-[#1C1E21]">Denegar</span>
          </button>
        </div>
      </div>
    </>
  );
}

function DetallesPropiedadComponent() {
  return <div>Contenido de Detalles de la propiedad</div>;
}

function DisponibilidadComponent() {
  const [openMenu, setOpenMenu] = useState(null);

  const data = [
    {
      id: "123-A",
      nombre: "Habitación A",
      tipo: "Habitacion con vista a la calle ",
      disponibilidad: "Disponible",
    },
    {
      id: "123-B",
      nombre: "Habitación B",
      tipo: "Habitacion con vista a la calle ",
      disponibilidad: "No disponible",
    },
    {
      id: "123-C",
      nombre: "Habitación C",
      tipo: "Habitacion con vista a la calle ",
      disponibilidad: "Disponible",
    },
    {
      id: "123-D",
      nombre: "Habitación D",
      tipo: "Habitacion con vista a la calle ",
      disponibilidad: "No disponible",
    },
    {
      id: "123-E",
      nombre: "Habitación A",
      tipo: "Habitacion con vista a la calle ",
      disponibilidad: "Disponible",
    },
    {
      id: "123-F",
      nombre: "Habitación B",
      tipo: "Habitacion con vista a la calle ",
      disponibilidad: "No disponible",
    },
    {
      id: "123-G",
      nombre: "Habitación C",
      tipo: "Habitacion con vista a la calle ",
      disponibilidad: "Disponible",
    },
    {
      id: "123-H",
      nombre: "Habitación D",
      tipo: "Habitacion con vista a la calle ",
      disponibilidad: "No disponible",
    },
    {
      id: "123-I",
      nombre: "Habitación A",
      tipo: "Habitacion con vista a la calle ",
      disponibilidad: "Disponible",
    },
    {
      id: "123-J",
      nombre: "Habitación B",
      tipo: "Habitacion con vista a la calle ",
      disponibilidad: "No disponible",
    },
    {
      id: "123-K",
      nombre: "Habitación C",
      tipo: "Habitacion con vista a la calle ",
      disponibilidad: "Disponible",
    },
    {
      id: "123-L",
      nombre: "Habitación D",
      tipo: "Habitacion con vista a la calle ",
      disponibilidad: "No disponible",
    },
  ];

  const toggleMenu = (id) => {
    setOpenMenu(openMenu === id ? null : id);
  };
  return (
    <div className="w-full bg-[#FCFDFF] rounded-3xl m-3">
      <div className="bg-[#FCFDFF] rounded-tl-[24px] rounded-tr-[24px] h-[60px] border-b border-gray-200 font-medium text-base text-[#71717A]">
        <div className="flex w-full  h-[60px]">
          <div className="w-[100px] flex justify-center items-center">ID</div>
          <div className="w-[200px] flex justify-center items-center">Nombre</div>
          <div className="w-[300px] flex justify-center items-center">Tipo</div>
          <div className="w-[250px] flex justify-center items-center">Disponibilidad</div>
        </div>
      </div>

      {data.map((item) => (
        <div
          key={item.id}
          className="flex border-b border-gray-200 h-[44px] font-medium text-sm text-[#000000]">
          <div className="flex w-full">
            <div className="w-[100px] flex justify-center items-center">{item.id}</div>
            <div className="w-[200px] flex justify-center items-center">{item.nombre}</div>
            <div className="w-[300px] flex justify-center items-center">{item.tipo}</div>
            <div className="w-[250px] flex justify-center items-center">
              <div
                className={` flex justify-center items-center h-8  min-w-[105px] rounded-sm ${
                  item.disponibilidad === "No disponible" ? "bg-[#FEC4C4]" : "bg-[#DEFFDD]"
                }`}>
                {item.disponibilidad}
              </div>
            </div>
          </div>
          <div className="relative flex justify-end items-center w-[50px]">
            <button
              onClick={() => toggleMenu(item.id)}
              className="p-2 rounded-full hover:bg-gray-100 focus:outline-none">
              &#x2022;&#x2022;&#x2022;
            </button>
            {openMenu === item.id && (
              <div className="absolute right-0 mt-2 w-32 bg-white border border-gray-200 rounded-lg shadow-lg z-10">
                <ul className="py-1">
                  <li
                    onClick={() => {
                      setOpenMenu(null);
                      alert(`Editar ${item.nombre}`);
                    }}
                    className="px-4 py-2 cursor-pointer hover:bg-gray-100">
                    Editar
                  </li>
                  <li
                    onClick={() => {
                      setOpenMenu(null);
                      alert(`Bloqueo manual de ${item.nombre}`);
                    }}
                    className="px-4 py-2 cursor-pointer hover:bg-gray-100">
                    Bloqueo manual
                  </li>
                </ul>
              </div>
            )}
          </div>
        </div>
      ))}
    </div>
  );
}

function DatosPagoComponent() {
  return (
    <div className="flex flex-col w-full px-5 gap-2 ">
      <div className="flex w-full justify-between items-center h-24 px-10 py-6 gap-3 bg-white border border-[#EBF0F8] rounded-2xl">
        <Image src="/images/iconStripe.svg" width={75} height={31} alt="Logo" />
        <div className="flex items-center justify-center rounded-lg bg-[#FFF4D6] w-20 h-7">
          <span className="text-sm font-normal text-[#9D7E25] ">Pendiente </span>
        </div>
        <button className="h-9 w-28 flex items-center justify-center rounded-md bg-[#3581EC] transition-colors duration-150 ease-in-out">
          <span className="text-sm font-medium text-[#FCFDFF]">Sincronizar</span>
        </button>
      </div>
      <div className="flex w-full justify-between items-center h-24 px-10 py-6 gap-3 bg-white border border-[#EBF0F8] rounded-2xl">
        <div className="flex gap-3">
          <Image src="/images/iconWallet.svg" width={24} height={24} alt="Logo" />
          <span className="text-sm font-semibold text-[#1C1E21]">Wallet Bitcoin</span>
        </div>
        <div className="flex items-center justify-center rounded-lg bg-[#E2F5E2] w-28 h-7">
          <span className="text-sm font-normal text-[#20961E] ">Sincronizada </span>
        </div>
        <button className="h-9 w-28 flex items-center justify-center rounded-md bg-[#F4F4F5] transition-colors duration-150 ease-in-out">
          <span className="text-sm font-medium text-[#1C1E21]">Eliminar</span>
        </button>
      </div>
    </div>
  );
}

export default Dashboard;
