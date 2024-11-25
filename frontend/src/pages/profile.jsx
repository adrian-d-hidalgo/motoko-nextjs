import { zodResolver } from "@hookform/resolvers/zod";
import Image from "next/image";
import React from "react";
import { useForm } from "react-hook-form";
import { z } from "zod";
import { useRouter } from 'next/router';

// Esquema de validación con zod
const schema = z.object({
  name: z
    .string()
    .min(1, { message: "Nombre es requerido" })
    .regex(/^[a-zA-Z\s]+$/, { message: "Solo se permiten letras" }),
  lastname: z
    .string()
    .min(1, { message: "Apellido es requerido" })
    .regex(/^[a-zA-Z\s]+$/, { message: "Solo se permiten letras" }),
  email: z.string().email({ message: "Debe tener un formato de correo válido" }),
  phone: z
    .string()
    .regex(/^\d{2}\s\d{2}\s\d{2}\s\d{2}\s\d{2}$/, { message: "Formato de teléfono debe ser XX XX XX XX XX" })
    .optional(),
});

function Profile() {
  const router = useRouter();
  const {
    register,
    handleSubmit,
    setValue,
    formState: { errors },
  } = useForm({
    resolver: zodResolver(schema),
  });

  const onSubmit = (data) => {
		router.push('/dashboard');
  };

  // Función para formatear el número de teléfono
  const formatPhoneNumber = (e) => {
    let input = e.target.value.replace(/\D/g, ""); // Remueve caracteres no numéricos
    if (input.length > 10) input = input.slice(0, 10); // Limita a 10 dígitos
    const formattedPhone = input.replace(/(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})/, "$1 $2 $3 $4 $5");
    setValue("phone", formattedPhone); // Establece el valor formateado
  };

  return (
    <>
      <div className="flex flex-col min-h-screen w-full overflow-hidden relative">
        <section className="absolute inset-0">
          <Image src="/images/background.svg" alt="Hero Illustration" layout="fill" objectFit="cover" />
        </section>

        <div className="fixed z-20 flex flex-col w-[567px] h-[80%] justify-start p-6 rounded-3xl border border-[#E2E8F0] bg-[#E3EFFD] top-1/2 right-16 transform -translate-y-1/2">
          <span className="text-2xl font-bold text-[#1C1E21] mt-8 mb-6">Crea tu perfil</span>
          <form
            onSubmit={handleSubmit(onSubmit)}
            className="flex flex-col items-start justify-start space-y-4">
            <div className="space-y-2 w-full">
              <label htmlFor="name" className="font-medium text-sm">
                Nombre
              </label>
              <input
                id="name"
                {...register("name")}
                className="h-9 w-full rounded-md border border-[#CBD5E1]"
                type="text"
              />
              {errors.name && <span className="text-red-500 text-sm">{errors.name.message}</span>}
            </div>

            <div className="space-y-2 w-full">
              <label htmlFor="lastname" className="font-medium text-sm">
                Apellido
              </label>
              <input
                id="lastname"
                {...register("lastname")}
                className="h-9 w-full rounded-md border border-[#CBD5E1]"
                type="text"
              />
              {errors.lastname && <span className="text-red-500 text-sm">{errors.lastname.message}</span>}
            </div>

            <div className="space-y-2 w-full">
              <label htmlFor="email" className="font-medium text-sm">
                Correo electrónico
              </label>
              <input
                id="email"
                {...register("email")}
                className="h-9 w-full rounded-md border border-[#CBD5E1]"
                type="email"
              />
              {errors.email && <span className="text-red-500 text-sm">{errors.email.message}</span>}
            </div>

            <div className="space-y-2 w-full">
              <label htmlFor="phone" className="font-medium text-sm">
                Teléfono (opcional)
              </label>
              <input
                id="phone"
                {...register("phone")}
                className="h-9 w-full rounded-md border border-[#CBD5E1]"
                type="text"
                onChange={formatPhoneNumber} // Formatear número en cada cambio
              />
              {errors.phone && <span className="text-red-500 text-sm">{errors.phone.message}</span>}
            </div>
            <div className="h-14 w-full p-2 rounded-lg bg-[#C8D6EA] mt-2">
              <span className="text-xs font-normal text-[#1C1E21]">
                Tus datos no serán compartidos. Solo los utilizaremos para enviarte notificaciones sobre tu
                reservación.
              </span>
            </div>
            <button
              type="submit"
              className="h-10 w-28 flex items-center justify-center rounded-md bg-[#3581EC] text-white transition-colors duration-150 ease-in-out cursor-pointer">
              <span className="text-sm font-medium text-white">Crear</span>
            </button>
          </form>
        </div>
      </div>
    </>
  );
}

export default Profile;
