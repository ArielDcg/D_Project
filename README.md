# Proyecto Paint - FPGA

---

## Integrantes del Equipo

| Nombre Completo | Identificación SIA |
|----------------|-------------------|
| Kevin Santiago Aldana Muñoz| 1014979769 |
| Emmanuel Bonilla Mitrotti | 1109543118 |
| Ariel Giovanni Cardenas Santisteban | 7494038 |

---

Sistema de pintado usando un mouse PS/2 conectado a un Arduino que envía datos por UART a una FPGA Tang Primer 25K, la cual controla un panel LED RGB de 64x64.

El proyecto implementa una arquitectura pipeline donde la data del mouse atraviesa tres etapas principales (Adquisición, Procesamiento y Visualización) antes de afectar la pantalla LED.

### 1. Adquisición de Datos (Arduino)

1.  **Lectura PS/2:** El firmware del Arduino lee de forma síncrona el mouse PS/2, capturando el estado de los botones y los cambios relativos de posición ($\Delta X$ y $\Delta Y$).
2.  **Encapsulación UART:** El Arduino ensambla estos datos en un paquete serial de **3 bytes** (`[Botones] [Delta X] [Delta Y]`). Este paquete es transmitido continuamente a 9600 baudios a través del pin TX hacia la FPGA.



### 2. Procesamiento Lógico (FPGA)

La FPGA (Módulo `paint.v`) maneja dos submódulos críticos que operan en serie:

* **Receptor de Paquetes UART (`mouse_uart_receiver`):** Este módulo utiliza una FSM para sincronizar la llegada de los 3 bytes del paquete. Solo cuando el tercer byte es recibido, se activa la señal `data_valid`, liberando el paquete completo de movimiento a la lógica de pintado.
* **Lógica de Pintado (`PS2_TO_SCREEN`):** Este es el núcleo del sistema, implementado como una compleja FSM.
    * **Movimiento:** La FSM recibe $\Delta X$ y $\Delta Y$ y los suma a las coordenadas absolutas actuales del cursor ($X_{abs}, Y_{abs}$). Realiza verificaciones constantes para asegurar que $0 \le X_{abs} \le 63$ y $0 \le Y_{abs} \le 63$.
    * **Pintado:** Si se detecta un **Clic Izquierdo**, la FSM calcula la dirección exacta de la memoria y activa la señal de escritura (`wr`) en la memoria para sobrescribir el píxel con el color de pintado (p. ej., Rojo).
    * **Cursor:** El módulo también gestiona la visualización temporal del cursor, alternando entre el color de fondo y un color de cursor para indicar la posición actual.

### 3. Visualización (FPGA - Controlador LED)

Este proceso opera de manera **independiente y concurrente** a la lógica de pintado:

* **Refresco Constante:** El **Controlador LED** (`panel_controller.v`) implementa la lógica de barrido (scan) de la matriz. Recorre cíclicamente las 32 (o 64) filas del panel.
* **Lectura de Memoria:** Por cada ciclo de reloj y para cada fila, el controlador lee el dato de color de la RAM de video y lo desplaza (shift) hacia los *drivers* del panel LED.
* **Sincronización:** Utiliza las señales `LATCH` (para transferir los datos desplazados a los *buffers* de salida) y `OE` (para el control de brillo y evitar el efecto *ghosting*) para mantener la imagen estable y visible, incluso mientras la lógica de pintado está actualizando píxeles individuales.

---

## Conexiones Físicas

El camino de las conexiones físicas se presentan a continuación:

<img width="1035" height="362" alt="image" src="https://github.com/user-attachments/assets/ee028650-b43a-44d6-98da-35575289e94c" />

A continuación, se describen los pines clave para la interconexión de los tres componentes principales del sistema (Mouse PS/2, Arduino, FPGA y Panel LED).

### Conexión PS2 Mouse - ARDUINO UNO

Esta sección establece la interfaz de comunicación bidireccional entre el mouse PS/2 (utilizando el protocolo PS/2) y el microcontrolador Arduino. El Arduino leerá el movimiento y el estado de los botones del mouse. Para realizar la conexion del Mouse PS2 al arduino UNO se usó el proyecto [rucek/arduino-ps2-mouse](https://github.com/rucek/arduino-ps2-mouse)

| PS2 pin | ARDUINO pin |
| :--- | :--- |
| DATA | 5 |
| CLK | 6 |
| VCC | 5V |
| GND | GND |

### Conexión UART: ARDUINO UNO (TX) a FPGA (RX)

Esta sección define el canal de comunicación serial unidireccional por UART, utilizado para enviar los datos procesados del mouse (movimiento y botones) desde el Arduino (Transmisor) hacia el módulo UART Receptor implementado en la FPGA.

| ARDUINO UNO TX pin | FPGA RX pin |
| :---: | :---: |
| 7 | B2 |
| GND | GND |

### Conexión: FPGA a Panel LED

Esta es la interfaz de hardware donde la FPGA actúa como el controlador de video, generando las señales de tiempo y datos para mostrar la imagen de 64x64 píxeles y el cursor del "Paint".

| FPGA Pin | Panel LED Pin | Descripción |
| :---: | :---: | :--- |
| G10 | R0 | Fila 0 - Rojo |
| G11 | G0 | Fila 0 - Verde |
| D10 | B0 | Fila 0 - Azul |
| B10 | R1 | Fila 1 - Rojo |
| B11 | G1 | Fila 1 - Verde |
| C10 | B1 | Fila 1 - Azul |
| A10 | A | Dirección Fila A (Fila Select) |
| A11 | B | Dirección Fila B (Fila Select) |
| E10 | C | Dirección Fila C (Fila Select) |
| E11 | D | Dirección Fila D (Fila Select) |
| C11 | E | Dirección Fila E (Fila Select) |
| L11 | CLK | Señal de Reloj (Shift Clock) |
| K11 | LATCH | Señal Latch (Strobe) |
| K5 | OE | Output Enable (Control de Brillo) |
| GND | GND | Tierra |
| GND | N | (GND o Pin sin uso) |

---

## Estructura

Esta sección detalla el funcionamiento interno de los módulos lógicos y protocolos utilizados en el proyecto.

```
paint_top
├── mouse_rx       # Recibe 3 bytes del mouse por UART
│   └── uart       # Módulo UART base
├── ctrl_paint     # FSM de pintado (cursor + pintura)
├── memory         # Framebuffer dual-port
└── ctrl_panel     # FSM del panel LED
    ├── count      # Contadores (fila, columna, delay, index)
    ├── lsr_led    # Registro de desplazamiento para delay
    ├── comp_4k    # Comparador de igualdad
    └── mux        # Multiplexor de bits RGB
```

### 1. Protocolo PS/2 (Mouse)

El protocolo PS/2 utiliza dos líneas (Clock y Data) para la transmisión serial síncrona de datos desde el dispositivo (Mouse) hacia el host (Arduino). El host lee los datos en el flanco de bajada del reloj.

<img width="2692" height="6948" alt="Potocolo PS2_page-0001" src="https://github.com/user-attachments/assets/46e40f8c-6ebe-4e06-9699-1737543d14f9" />
*Diagrama de flujo del funcionamiento del protocolo PS/2*

### 2. Protocolo UART (Módulo Genérico)
El módulo UART en la FPGA se encarga de deserializar los datos entrantes. Utiliza un sobremuestreo (16 veces la tasa de baudios) para detectar el bit de inicio y muestrear los datos en el centro del periodo de cada bit, garantizando la integridad de la recepción.

* **Diagrama de Flujo:** Muestra la máquina de estados de recepción (Detección de Start Bit -> Muestreo de Bits 0-7 -> Stop Bit).
* **Camino de Datos:** Ilustra los registros de desplazamiento y contadores utilizados.

Diagrama de Flujo UART 

![Protocolo UART](https://github.com/user-attachments/assets/1425b0ae-a033-4ea5-a168-539f06cf7889)


Camino de Datos UART 

![Data Path UART](https://github.com/user-attachments/assets/e4e35282-f9b6-438d-b667-2fee0377618c)


### 3. Interfaz UART: Arduino a FPGA
Este módulo superior gestiona la recepción de paquetes completos de 3 bytes provenientes del Arduino. La máquina de estados asegura que los datos se interpreten en el orden correcto: `[Byte 1: Botones]` -> `[Byte 2: Movimiento X]` -> `[Byte 3: Movimiento Y]`.

* **Diagrama de Flujo:** Describe la FSM que espera secuencialmente los 3 bytes y valida la integridad del paquete.
* **Camino de Datos:** Muestra el buffer de 3 posiciones y cómo se asignan a las señales de salida (`btn`, `delta_x`, `delta_y`).

Flujo Arduino-FPGA

<img width="1774" height="4189" alt="Blank diagram (2)" src="https://github.com/user-attachments/assets/b429a505-11bd-4611-87e2-851e54cfc7c7" />


Datapath Arduino-FPGA

![Data Path UART ARDUINO](https://github.com/user-attachments/assets/5125b8cf-ae13-48ef-ae73-eadaf5fbb809)

Diagrama de estados Arduino-FPGA


<img width="1261" height="542" alt="Diagrama de estados UART-Arduino" src="https://github.com/user-attachments/assets/c2bce290-ab1d-46e0-baa5-612f6f40ef66" />


### 4. Controlador FPGA a Pantalla (Lógica de Pintado)
Este es el núcleo del proyecto (`PS2_TO_SCREEN`). Recibe las coordenadas del mouse, calcula la posición de memoria correspondiente en la matriz de 64x64, y actualiza el color del píxel si se detecta un clic ("Pintar"). También maneja la lógica de lectura de memoria para refrescar el panel LED continuamente.

* **Diagrama de Flujo:** Detalla el algoritmo para limitar las coordenadas (0-63), calcular la dirección de memoria (`Address = Y*64 + X`) y la lógica de escritura/lectura.
* **Camino de Datos:** Muestra los comparadores (para límites de pantalla), sumadores (para movimiento relativo) y la interfaz con la memoria de video.

Flujo Lógica de Pantalla

<img width="3705" height="6040" alt="Diagramas digital" src="https://github.com/user-attachments/assets/23de03f1-3e4d-495d-9c4d-847a1f8c48ef" />

Datapath Lógica de Pantalla

![Data Path PS2_TO_SCREEN](https://github.com/user-attachments/assets/4b6ad8c2-2fa0-4b84-86f2-c43a5e9fd4c9)

Diagrama de estados Lógica de Pantalla

![Diagrama de estados PS2_TO_SCREEN](Proyecto_Paint/img/Captura de pantalla 2025-12-10 223924.png)

### 5. Conexión FPGA a pantalla (Lectura de memoria)

Con este modulo se permite que la pnatalla lea la memoria ya modificada por la lógica de pintado, y muestra la imagen en el panel LED.

Diagrama de Flujo

<img width="584" height="1135" alt="Screenshot 2025-12-08 233329" src="https://github.com/user-attachments/assets/675c46eb-37df-4bed-a49c-1678cc857a6d" />

Datapath

<img width="913" height="658" alt="Screenshot 2025-12-08 233348" src="https://github.com/user-attachments/assets/1ef5d0ad-f54f-4645-99c8-c82adc4a2952" />

Diagrama de estados

<img width="1179" height="1112" alt="Screenshot 2025-12-08 233402" src="https://github.com/user-attachments/assets/5bdc517b-2a72-470e-a508-4cb9bbcc8724" />

## Cómo usar

Para desplegar y usar el proyecto, sigue estos pasos:

1.  **Realizar Conexiones Físicas:**
    * Conectar el Mouse PS/2 al Arduino (usando los pines **CLK=6** y **DATA=5**).
    * Conectar el Arduino **TX** (**pin 7**) al UART **RX** de la FPGA (**pin B2**).
    * Conectar el **Panel LED** a los pines de la FPGA según se detalla en la sección **"Conexión: FPGA a Panel LED"**.

2.  **Programar el Arduino (Firmware):**
    * Cargar el sketch ubicado en `arduino/mouse_uart.ino` en el Arduino UNO. Este firmware se encarga de leer el mouse PS/2 y encapsular los datos de movimiento/clic en paquetes de 3 bytes que se envían por UART.

3.  **Programar la FPGA (Hardware Lógico):**
    * Sintetizar el diseño Verilog con los archivos de la carpeta `main/` (el módulo de nivel superior es `paint.v`). Asegúrate de que los archivos de *constraints* estén configurados correctamente para la placa Tang Primer 25K.
    * Cargar el *bitstream* resultante en la FPGA.

4.  **Operación del Sistema:**
    * Al encender el sistema, el panel LED mostrará la imagen de fondo inicial cargada desde la memoria de la FPGA.
    * Mueve el mouse para desplazar el cursor sobre la pantalla.
    * Presiona el **Clic Izquierdo** del mouse para pintar o cambiar el color del píxel actual.
    * El sistema mostrará los trazos en tiempo real gracias a la alta velocidad de refresco del controlador LED.

## Funcionamiento

- El cursor se mueve siguiendo el mouse
- Click izquierdo: pinta en rojo
- El panel muestra una imagen de fondo cargada desde archivos .hex
