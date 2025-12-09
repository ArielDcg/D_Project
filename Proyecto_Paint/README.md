# Proyecto Paint - FPGA

Sistema de pintado usando un mouse PS/2 conectado a un Arduino que envía datos por UART a una FPGA Tang Primer 25K, la cual controla un panel LED RGB de 64x64.

## Estructura

```
Proyecto_Paint/
├── main/           # Código Verilog para la FPGA
├── arduino/        # Firmware del Arduino
└── README.md
```

## Cómo usar

1. Programar el Arduino con `arduino/mouse_uart.ino`
2. Sintetizar y programar la FPGA con los archivos en `main/`
3. Conectar:
   - Mouse PS/2 al Arduino (CLK=pin6, DATA=pin5)
   - Arduino TX (pin7) al UART RX de la FPGA (pin B2)
   - Panel LED a los pines definidos en `constraints/tang_primer_25k.cst`

## Funcionamiento

- El cursor se mueve siguiendo el mouse
- Click izquierdo: pinta en rojo
- El panel muestra una imagen de fondo cargada desde archivos .hex
