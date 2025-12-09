# Módulos Verilog

## Arquitectura

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

## Archivos

| Archivo | Módulo | Descripción |
|---------|--------|-------------|
| paint_top.v | paint_top | Módulo top que conecta todo |
| mouse_rx.v | mouse_rx | Receptor UART para paquetes del mouse |
| uart.v | uart | Módulo UART base (RX/TX) |
| ctrl_paint.v | ctrl_paint | Control de pintado y cursor |
| memory.v | memory | Memoria dual-port con backup |
| ctrl_panel.v | ctrl_panel | Control FSM del panel LED |
| count.v | count | Contador genérico |
| lsr.v | lsr_led | Registro de desplazamiento |
| comp.v | comp_4k | Comparador |
| mux.v | mux | Multiplexor de bits |

## Protocolo UART

El Arduino envía paquetes de 3 bytes:
- Byte 0: Botones (bit0=izq, bit1=der, bit2=medio)
- Byte 1: Delta X (con signo)
- Byte 2: Delta Y (con signo)

## Síntesis

```bash
make GOWIN_BOARD=primer_25k configure_tang_primer_25k
```
