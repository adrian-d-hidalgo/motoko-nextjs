### Verificacion de usuarios:

Se deja implementada una funcion para evaluar el estado de verificacion de un usuario **`userIsVerificated()`**  mediante la cual, en un contexto de produccion, se permitirá la publicacion de espacios de alojamiento solo cuando el usuario publicante esté verificado mediante algun tipo de procedimiento KYC.
En un contexto de MVP todos los usuarios serán inicializados por defecto como verificados.

---

1: Solicitud de reserva.
    A: Se evalua si el la fecha de la reserva es mayor al tiempo actual mas el tiempo minimo fijado por el host, o sea si el host dice que se puede reservar con 24 horas  de anticipación y el usuario quiere reserva para dentro de 10 horas, se devuelve un error.
    B: Si todo va bien, el backend devuelve los datos de la solicitud mas un codigo de pago.
    C: Cuando se arma la transacción en el front, el codigo de pago se pone en el campo Memo y se hace la transacción.
2: Tiempo de bloqueo configurable (40 minutos por ejemplo):
    A: Durante este plaso de tiempo se marca como no disponible o pre reservado todo el rango de tiempo correspondiente a la reserva.
    B: El usuario tiene tiempo en este plaso (40 minutos segun ejemplo), de proceder con el pago de confirmación.
    C: Si el plaso finaliza sin que se haya concretado la confirmacion, se vuuelve a marcar como disponible.
2: Confirmación de reserva
    A: Si el usuario realiza la transaccián, la cual devuelve un transaction hash, se llama a otra funcion de backend enviando el id de la reserva mas el transaction hash.
    B: Mediante una consulta al Ledger correspondiente a la moneda de pago, desde el bakend se envia el transaction hash, confirmando que los datos de retorno sean los correspondientes a la transaccion solicitada (Campo memo).
    C: Luego de la confirmacion y verificación se marca como ocupado en el calendario el rango de tiempo de alojamineto


---
#### Modificación del flujo de confirmaciones de reservas. (Confirmación del lado del Host)
##### Ventajas y desventajas

### Ventajas:
1. El Host puede elegir, para un mismo periodo de alojamiento, el huesped que mejor se acomode a sus conveniencias de entre todos los que hayan requerido ese periodo de alojamiento.

### Desventajas:
#### Desventajas Para la plataforma:
1. Por cada solicitud de reserva, la platafoma tiene que enviar una notificación al dueño de Host y esperar respuesta
2. Durante el tiempo de espera, para ese mismo periodo de hospedaje solicitado se pueden acumular mas solicitudes, las cuales tienen que ser notificadas también.
3. Que el usuario salga de la plataforma sin haber concretado un pago es motivo suficiente para que no vuelva.
3. Cuando el dueño del Host confirma, la plataforma tiene que notificar tanto al potencial huesped como a los rechazados
4. Al tiempo de demora de la confirmación hay que sumarle el tiempo de demora de confirmacion de la confirmacion por parte del huesped.
4. Es decir, el potencial huesped tiene que reponder de alguna manera a la confirmacion. ¿Mediante un pago?
5. Es incierto el momento en el que se establece definitivamente en el calendario un periodo de alojamiento como ocupado 
#### Desventajas Para el dueño:
1. La ventaja de poder elegir es equivalente a la desventaja de tener que elegir en cualquier momento del dia y rápido. Filosoficamente: No es una elección tener que elegir ya
2. Si el tiempo de demora de la confirmación supera los 20 o 30 minutos, es muy probable que en ese momento el potencial huesped ya haya conseguido hospedaje en otro lugar.
3. Posiblemente los rechazados no vuelven nunca más e incluso pidan explicaciones, que de no ser satisfechas consistentemente generen problemas legales.
4. La confirmación de una reserva para un periodo largo de alojamiento y que luego no se materializa en un hospedaje (porque el usuario ya encontro otro lugar u otros motivos) puede tener como consecuencia, el rechazo de multiples solicitudes de alojamiento para ese mismo periodo y que no necesariamente hayan tenido solapamientos entre si. 
##### Ejemplo:
##### Solicitud confirmada: 
+ dias  [20... 30]
##### Solicitudes rechazadas:
+ dias  [20... 24], 
+ dia 25, 
+ dias  [27... 28]
+ dia 29,
+ dia 30

#### Desventajas Para el Usuario:
1. Que el usuario salga de la plataforma con las manos vacias pudiendo salir con un problema solucionado es algo evitable.

#### Notas mentales. Volumen 2
##### Comisiones por alojmiento
Para las comisiones por alojamiento se puede establecer un porcentage del monto final, el cuál será deducido del monto recibido por el Housing en funcion del precio publicado.
Para disminuir la friccion del usuario final, el cobro de la comisión puede hacerse directamente mediante un transfer_from luego de la recepcion de fondos en la wallet del Housing.
Para poder proceder con ese transfer_from es necesario que la wallet del housing, haya firmado un approve y para eso puede ser conveniente hacerlo durante la creacion del Housing.
En este proceso ya quedaría establecida la wallet del housing y además se habria adquirido la firma del approve en favor de la plataforma.
Actualmente la wallet receptora de fondos de un housing se calcula a partir del Principal ID del owner de ese Housing, de manera tal que es unicamente ese principal quien puede moverlos, lo cual está bien pero para ello hay que implementar una funcion con la que el usuario pueda desde la plataforma hacer transferencias de esos tokens hacia una wallet o hacia algun exchange.  
La opcion de conectar una wallet durante la creacion del housing elimina la necesidad de desarrollar un mecanismo de withdraw extra ya que el dueño del Housing puede visualizar su balance directamente en su plug wallet o ser notificado automaticamente cada vez que recibe el pago por algun alojamiento.
