# Medidor de tiempo de reacción en FPGA

Circuito digital que mide el tiempo de reacción de una persona ante un estímulo visual, diseñado en **VHDL** e implementado en una FPGA **Xilinx Artix-7** (placa **Digilent Basys3**). El resultado se muestra en milisegundos en el display de 7 segmentos.

Proyecto de la asignatura **Electrónica Digital** del Grado en Ingeniería Electrónica Industrial y Automática (Universidad Carlos III de Madrid, curso 2025-26).

<!-- Añade aquí una foto o un GIF de la placa funcionando -->
<!-- ![Placa Basys3 midiendo el tiempo de reacción](docs/placa.jpg) -->

<img width="2090" height="1497" alt="image" src="https://github.com/user-attachments/assets/6c4f70f6-c9db-4698-a068-ab37849cc51d" />

## Funcionamiento

1. El display está parado, esperando a que el usuario pulse el botón.
2. Al pulsarlo, la cuenta se pone a `0000` y el circuito espera un **tiempo aleatorio de hasta 1 segundo**.
3. Pasado ese tiempo, el contador empieza a avanzar: es la señal para reaccionar.
4. El usuario vuelve a pulsar lo más rápido posible. La cuenta se detiene y el display muestra su **tiempo de reacción** (de 0000 a 9999 ms).

## Diseño

El sistema está controlado por una **máquina de estados de Moore** con cuatro estados:

| Estado | Qué hace | Transición |
|---|---|---|
| `Espera` | Display detenido, mostrando la última medida | Pulsación → `Inicializa` |
| `Inicializa` | Pone los contadores a cero y carga el tiempo aleatorio | Siempre → `Aleatorio` |
| `Aleatorio` | Cuenta atrás del tiempo de espera aleatorio | Fin de la cuenta → `Cuenta` |
| `Cuenta` | Cuenta los milisegundos hasta que el usuario reacciona | Pulsación → `Espera` |

<!-- Si tienes el diagrama de estados escaneado, añádelo aquí -->
<!-- ![Diagrama de estados](docs/diagrama_estados.jpg) -->

<img width="1367" height="1000" alt="diagrama_estados" src="https://github.com/user-attachments/assets/4cd7b8fa-6cac-40ea-ba5b-8bac41c3c0cb" />

Bloques principales:

- **Base de tiempos**: a partir del reloj de 100 MHz genera un pulso cada 1 ms (para la cuenta) y otro cada 10 ms (para el display).
- **Contadores BCD encadenados**: cuatro instancias del mismo contador 0-9 (unidades, decenas y centenas de milisegundo, y segundos). Cada uno habilita al siguiente al desbordar, y todos tienen puesta a cero síncrona controlada por la máquina de estados.
- **Detector de flanco** en el botón, para que cada pulsación se registre una sola vez.
- **Tiempo aleatorio**: un contador libre de 0 a 999 ms avanza continuamente, y su valor en el instante de la pulsación fija la espera. Como el usuario no puede controlar ese instante al milisegundo, el resultado es impredecible.
- **Multiplexado del display**: los cuatro dígitos se encienden por turnos cada 10 ms, lo bastante rápido para que el ojo los vea todos a la vez.
- **Decodificador BCD a 7 segmentos** (lógica activa a nivel bajo).

## Verificación y resultados

- Simulado con un **banco de pruebas** (`reflejos_tb.vhd`) que reproduce el ciclo completo: reset, primera pulsación, espera aleatoria, cuenta y segunda pulsación.
- Sintetizado e implementado en **Vivado**, cumpliendo las restricciones de tiempo a 100 MHz y con un uso de recursos de en torno al 1 % de LUTs y biestables de la FPGA.
- Probado en la placa Basys3.

## Archivos

```
src/
├── reflejos.vhd      # Entidad principal: máquina de estados, temporización y display
└── contador.vhd      # Contador BCD 0-9 con habilitación y puesta a cero síncrona
sim/
└── reflejos_tb.vhd   # Banco de pruebas
```

## Cómo usarlo

1. Crea un proyecto en **Vivado** para la FPGA `XC7A35T-1CPG236C` (Basys3).
2. Añade los archivos de `src/` como fuentes de diseño y `reflejos_tb.vhd` como fuente de simulación.
3. Añade un fichero de restricciones `.xdc` con los pines de la Basys3 (reloj, botones, display), por ejemplo a partir del `Basys3_Master.xdc` de Digilent.
4. Sintetiza, implementa, genera el *bitstream* y cárgalo en la placa.

## Autores

- Rafael Torres Olmedo
- Iván Noguera Campanario
- Miguel Lansac Hernanz
