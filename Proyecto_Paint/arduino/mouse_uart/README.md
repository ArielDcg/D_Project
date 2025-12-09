# Firmware Arduino

Lee datos del mouse PS/2 y los envía por UART a la FPGA.

## Archivos

| Archivo | Descripción |
|---------|-------------|
| mouse_uart.ino | Programa principal |
| PS2Mouse.cpp | Librería PS/2 |
| PS2Mouse.h | Header de la librería |

## Conexiones

| Pin Arduino | Función |
|-------------|---------|
| 5 | DATA del mouse PS/2 |
| 6 | CLOCK del mouse PS/2 |
| 7 | TX hacia FPGA (UART) |
| 5V | Alimentación mouse |
| GND | Tierra mouse |

## Protocolo

Envía 3 bytes por cada movimiento o cambio de botón:
- Byte 0: Estado de botones
- Byte 1: Delta X
- Byte 2: Delta Y

Velocidad: 9600 baud
