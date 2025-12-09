# Diagramas del Sistema

## Arquitectura General

```mermaid
graph TB
    subgraph Arduino
        PS2[Mouse PS/2] --> ARD[Arduino]
    end
    
    subgraph FPGA
        ARD -->|UART 9600| UART_RX[uart_rx]
        UART_RX --> ACUM[Acumulador XY]
        ACUM --> CTRL_P[ctrl_paint]
        CTRL_P <--> MEM[memory]
        MEM --> MUX[mux]
        MUX --> PANEL[Panel LED 64x64]
        CTRL_PANEL[ctrl_panel] --> PANEL
    end
```

## Diagrama de Bloques - paint_top

```mermaid
graph LR
    subgraph Entradas
        CLK[clk 50MHz]
        RST[rst]
        RX[uart_rx]
    end
    
    subgraph uart_rx
        RX --> UART_CORE[uart]
        UART_CORE --> FSM_RX[FSM 3 bytes]
        FSM_RX --> BTN[btn_left/right/middle]
        FSM_RX --> DELTA[delta_x, delta_y]
    end
    
    subgraph Acumulador
        DELTA --> SIGN[Extensión signo]
        SIGN --> ADD[Suma + límites]
        ADD --> POS[pos_x, pos_y]
    end
    
    subgraph ctrl_paint
        POS --> CALC[Cálculo dirección]
        BTN --> FSM_P[FSM pintado]
        FSM_P --> WR[wr0, wr1]
        FSM_P --> ADDR[address]
        FSM_P --> WDATA[wdata]
    end
    
    subgraph memory
        ADDR --> MEM0[MEM0/MEM1]
        WR --> MEM0
        MEM0 --> RDATA[rdata 24bit]
    end
    
    subgraph Panel_LED
        RDATA --> MUX_LED[mux]
        MUX_LED --> RGB[RGB0, RGB1]
        CTRL[ctrl_panel] --> LATCH
        CTRL --> NOE
        CTRL --> LP_CLK
        CTRL --> ROW
    end
```

## FSM - ctrl_paint

```mermaid
stateDiagram-v2
    [*] --> IDLE
    IDLE --> RESTORE: movimiento detectado
    RESTORE --> PAINT_PERM: btn_left = 1
    RESTORE --> PAINT_CURSOR: btn_left = 0
    PAINT_PERM --> PAINT_CURSOR
    PAINT_CURSOR --> IDLE
```

| Estado | Acción |
|--------|--------|
| IDLE | Espera movimiento |
| RESTORE | Restaura píxel anterior desde backup |
| PAINT_PERM | Pinta permanente (escribe en MEM y B_MEM) |
| PAINT_CURSOR | Pinta cursor temporal |

## FSM - ctrl_panel

```mermaid
stateDiagram-v2
    [*] --> START
    START --> GET_PIXEL: init
    GET_PIXEL --> INC_COL
    INC_COL --> INC_COL: !ZC
    INC_COL --> SEND_ROW: ZC
    SEND_ROW --> DELAY_ROW
    DELAY_ROW --> DELAY_ROW: !ZD
    DELAY_ROW --> NEXT_BIT: ZD
    NEXT_BIT --> NEXT_DELAY
    NEXT_DELAY --> INC_ROW
    INC_ROW --> READY_FRAME
    READY_FRAME --> START: ZR
    READY_FRAME --> GET_PIXEL: !ZR
```

## FSM - uart_rx

```mermaid
stateDiagram-v2
    [*] --> WAIT_BYTE0
    WAIT_BYTE0 --> WAIT_BYTE1: rx_avail
    WAIT_BYTE1 --> WAIT_BYTE2: rx_avail
    WAIT_BYTE2 --> PROCESS: rx_avail
    PROCESS --> WAIT_BYTE0
    
    WAIT_BYTE1 --> WAIT_BYTE0: timeout
    WAIT_BYTE2 --> WAIT_BYTE0: timeout
```

## Diagrama de Memoria

```mermaid
graph TB
    subgraph Memoria Dual Port
        subgraph Puerto_A["Puerto A (Lectura Panel)"]
            ADDR_R[addr_read] --> MEM
            MEM --> RDATA[rdata 24bit]
        end
        
        subgraph Puerto_B["Puerto B (Mouse)"]
            ADDR_W[addr_write] --> MEM
            WR0[wr0] --> MEM0[MEM0]
            WR1[wr1] --> MEM1[MEM1]
            PERM[paint_permanent] --> BMEM[B_MEM0/B_MEM1]
        end
        
        subgraph Backup
            BMEM --> BREAD0[b_rdata0]
            BMEM --> BREAD1[b_rdata1]
        end
    end
```

## Protocolo UART

```mermaid
sequenceDiagram
    participant Mouse
    participant Arduino
    participant FPGA
    
    Mouse->>Arduino: Datos PS/2
    Arduino->>Arduino: Escala y acumula
    Arduino->>FPGA: Byte 0 (buttons)
    Arduino->>FPGA: Byte 1 (delta_x)
    Arduino->>FPGA: Byte 2 (delta_y)
    FPGA->>FPGA: Procesa y pinta
```
