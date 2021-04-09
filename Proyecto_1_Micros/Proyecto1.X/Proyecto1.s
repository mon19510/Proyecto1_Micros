;Archivo: Proyecto1.S
; Dispositivo: PIC16F887
; Autora: Ximena Monzon
; Compilador: pic-as (v2.30), MPLABX V5.40
;
;Programa: Displays Simultaneos
;Hardware: LEDs, pushbutton, display 7-seg, resistencias
;
;Creado: 15 Marzo, 2021
;Ultima modificacion:  6 de Abril, 2021

PROCESSOR 16F887
#include <xc.inc>

;configuration word 1
    CONFIG FOSC=INTRC_NOCLKOUT //Oscilador Interno sin salida
    CONFIG WDTE=OFF //WDT disabled (reinicio repetitivo del pic)
    CONFIG PWRTE=ON //PWRT enabled (espera de 72ms al iniciar) antes de ejecutar cualquier cosa
    CONFIG MCLRE=OFF // El pin de MCRL se utiliza como I/O (masterclear) (pin RE3 en micro) (si esta on poner resistencia)
    CONFIG CP=OFF // Sin proteccion de codigo (por si vendemos)
    CONFIG CPD=OFF // Sin proteccion de datos
    
    CONFIG BOREN=OFF // Sin reinicio cuando el voltaje de alimentacion baja de 4V (reset por si baja el voltaje) (detecta problemas)
    CONFIG IESO=OFF // Reinicio sin cambio de reloj de interno a externo (abajo)
    CONFIG FCMEN=OFF // Cambio de relo externo a interno en caso de fallo (necesita resist. si esta prendido)
    CONFIG LVP=ON // programacion en bajo voltaje permitida
    
;configuration word 2
    CONFIG WRT=OFF // proteccion de autoescritura por el programa desactivada
    CONFIG BOR4V=BOR40V // Reinicio abajo de 4v, (BOR21V=2.1V)
    
;-------- MACROS---------:
    
    delay_small macro
    movlw 248 ;valor inicial del contador
    movwf contsmall
    decfsz contsmall, 1 ;decremento de contador
    goto $-1
    endm
    
;---------------------variables-------------------;
    
PSECT udata_shr ;Common memory
    
    WT:	    ; Variable para que se guarde w
	DS 1
    ST:    ; Variable para que guarde status
	DS 1
    disp:
	DS  8 

PSECT udata_bank0 
    TL: DS  1
    count1: DS  1
    time1: DS  1
    time2: DS  1
    time3: DS 1	
    timer1: DS 1
    timer2: DS 1
    timer3: DS 1
    fix: DS  1
    control1: DS 1
    control2: DS 1
    control3: DS 1
    control4: DS 1
    control5: DS 1
    control6: DS 1
    control7: DS 1
    control8: DS 1
    contsmall: DS 1
    restart: DS 1
    residue: DS 1
    subs: DS 1
    stage: DS 1
    select: DS 1
    flags: DS 1
    flagsTL: DS 1
    flagss: DS 1
    flagreset: DS 1
    cflag: DS 1
    cselect: DS 1
    prtime1: DS 1
    prtime2: DS 1
    prtime3: DS 1
    selectdisp: DS 1
    greenc: DS 1
    greent: DS 1
    yello: DS 1
    accept: DS 1

    
;--------------vector reset ---------------------;
PSECT resVect, class=code,abs, delta=2
    ORG 00h
    resetVec:
    PAGESEL setup
    goto setup
    
;---------------interrupt vector----------------;
PSECT code, abs, delta=2
ORG 04h
push: ;mueve las variables temp a w
    movwf WT
    swapf STATUS, W
    movwf ST
    
isr: ;interrupcion
    BANKSEL PORTB
    ;interrupcion puerto b
    btfsc RBIF ;revision de interrupciones portb
    call pushbuttons
    ;interrupcion tmr0
    btfsc T0IF ;revision overflow tmr0
    call intmr0
    ;interrupcion tmr1
    btfsc TMR1IF ;revision overflow tmr1
    call intmr1

pop: ;regreso de w a STATUS
    swapf ST, W
    movwf STATUS
    swapf WT, F
    swapf WT, W
    retfie
    
;--------- config sub rutinas de interrupcion------------;
    ;interrupcion del timer1
    intmr1: ;esta configurada para que vaya incrementando la variable cada segundo
    BANKSEL TMR1H
    movlw 0xE1 ;modificando registros del tmr1
    movwf TMR1H
    
    BANKSEL TMR1L
    movlw 0x7C
    movwf TMR1L
    
    incf count1 ;incrementando variable para timer
    bcf TMR1IF
    return
    
    intmr0:
    call reset0 ;limpiando tmr0
    clrf PORTD ;limpiando puerto de 7seg
    
    ;con la instruccion btfsc se revisa que si el bit b en f es 1 nos vamos a la
    ;siguiente instruccion, es decir, esta revisando que el display este activado
    ;y continue al siguiente.
    btfsc flags, 0
    goto disp2
    btfsc flags, 1
    goto disp3
    btfsc flags, 2
    goto disp4
    btfsc flags, 3
    goto disp5
    btfsc flags, 4
    goto disp6
    btfsc flags, 5
    goto disp7
    btfsc flags, 6
    goto disp8
    
    ;multiplexado: va llamando y prendiendo banderas para "rotar" displays
    ;creamos rutinas internas para activar los displays
    
    disp1:
    movf control1, w
    movwf PORTC
    bsf PORTD, 0
    goto ndisp
    
    disp2:
    movf control2, W
    movwf PORTC
    bsf PORTD, 1 
    goto ndisp1
    
    disp3:
    movf control3, W
    movwf PORTC
    bsf PORTD, 2
    goto ndisp2
    
    disp4: 
    movf control4, W
    movwf PORTC
    bsf PORTD, 3
    goto ndisp3
    
    disp5: 
    movf control5, W
    movwf PORTC
    bsf PORTD, 4
    goto ndisp4
    
    disp6:
    movf control6, W
    movwf PORTC
    bsf PORTD, 5
    goto ndisp5
    
    disp7:
    movf control7, W
    movwf PORTC
    bsf PORTD, 6
    goto ndisp6
    
    disp8:
    movf control8, W
    movwf PORTC
    bsf PORTD, 7
    goto ndisp7
    
    ;creando xor para cada display para hacer rotaciones
    ndisp:
    movlw 00000001B
    xorwf flags, 1
    return
    
    ndisp1:
    movlw 00000011B
    xorwf flags, 1
    return
    
    ndisp2: 
    movlw 00000110B
    xorwf flags, 1
    return
    
    ndisp3:
    movlw 00001100B
    xorwf flags, 1
    return
    
    ndisp4:
    movlw 00011000B
    xorwf flags, 1
    return
    
    ndisp5:
    movlw 00110000B
    xorwf flags, 1
    return
    
    ndisp6:
    movlw 01100000B
    xorwf flags, 1
    return
    
    ndisp7:
    clrf flags
    return
;----------sub rutina interna pushbuttons--------;
    
    pushbuttons:
    btfss PORTB, 0 ;revisando si push 1 esta presionado
    call up
    btfss PORTB, 1 ;revisando si push 2 esta presionado
    call down
    btfss PORTB, 2 ;dirigiendo a rutina de seleccion de estado
    call tlstage
    bcf RBIF
    return
    
;------------ configuracion de tabla-------------;    
PSECT code, delta=2, abs
 ORG 100h ;posicion para el codigo
 ;------------configuracion------------;

 ;esto define los valores del display
tablita:
    clrf PCLATH
    bsf PCLATH, 0
    andlw   0x0F    ; Se pone como limite d.16 
    addwf   PCL
    retlw   00111111B    ; 0
    retlw   00000110B    ; 1
    retlw   01011011B    ; 2
    retlw   01001111B    ; 3
    retlw   01100110B    ; 4
    retlw   01101101B    ; 5
    retlw   01111101B    ; 6
    retlw   00000111B    ; 7
    retlw   01111111B    ; 8
    retlw   01101111B    ; 9
    retlw   01110111B    ; A
    retlw   01111100B    ; b
    retlw   00111001B    ; C
    retlw   01011110B    ; d
    retlw   01111001B    ; E
    retlw   01110001B    ; F
    
    
;---------------- SET UP -------------------;    
    ORG 118h 
    setup:
    
    call config_io ;llamando configuracion de entradas y salidas
    call config_pullup ;llamando configuracion del pullup interno
    call config_clock ;llamando configuracion del oscilador interno
    
;------------- Config Interrupciones ------;
    BANKSEL IOCB ;activando interrupciones
    movlw 00000111B ;activando en RB0 y RB1
    movwf IOCB ;moviendo a banksel
    
    BANKSEL INTCON ;limpiando y activando interrupciones globales
    bcf RBIF ;portb change on interrupt flag bit
    bsf GIE ;global interrupt enable bit
    bsf RBIE ;PORTB interrupt change enable bit
    bsf T0IE ;timer0 interrupt
    bcf T0IF ;time interrupt enable flag
    
;-------------------------------------------;
    
    call config_tmr0 ;llamando configuracion de tmr0
    call config_tmr1 ;llamando configuracion tmr1
    call config_tmr2 ;llamando configuracion tmr2
    call default_config ;llamando configuracion default
    
    ;limpiando puertos
    clrf restart
    BANKSEL PORTA
    clrf PORTA
    clrf PORTB
    clrf PORTC
    clrf PORTD
    clrf PORTE
    
;-----------------LOOP-----------------------;
    loop:
    
    ;3 divisiones para los displays
    btfsc selectdisp, 0 ;revisando bandera dependiendo de cual
    call div1 ;activada pone una rutina de division
    btfsc selectdisp, 1 ;guardando valor en la variable
    call div2
    btfsc selectdisp, 2
    call div3
    btfsc selectdisp, 3
    call config_accept ;rutina para aceptar
    
    call config_TL ;llamando configuracion de leds en semaforos
    
    btfsc restart, 0 ;apagando un instante los leds
    goto $+5
    call timers ;configuracion de tiempos
    call d_div1 ;divisiones de cada timer
    call d_div2
    call d_div3
    
    goto loop
    
;----------------- sub rutinas --------------;
    
    reset0: ;control de velocidad del multiplexado
    movlw 255 ;tiempo de instruccion
    movwf TMR0
    bcf T0IF ;volver 0 a bit de overflow
    return 
        
    config_clock: ;configuracion de oscilador interno
    BANKSEL OSCCON
    bcf IRCF2 ;010
    bsf IRCF1
    bcf IRCF0 ;250kHz
    bsf SCS ;activando oscilador interno
    return
    
    div1: ;primera subrutina de separacion de variables
    clrf select
    clrf residue
    bcf STATUS, 0
    movf TL, 0 ;moviendo datos del contador a w
    movwf prtime1
    movwf select ;moviendo a w variable de residuo
    movlw 10 ;moviendo 10 a w
    incf residue
    subwf select, f ;resta a residuos 10
    btfsc STATUS, 0 ;verificando bandera
    goto $-3
    decf residue ;incrementa variable decenas
    addwf select 
    movf residue, w
    call tablita
    movwf control7
    movf select, w
    call tablita
    movwf control8
    return 
    
    div2: ;segunda subrutina de separacion de valores
    clrf select
    clrf residue
    bcf STATUS, 0
    movf TL, 0 ;moviendo datos del contador a w
    movwf prtime2
    movwf select ;moviendo w a variable de residuo
    movlw 10 ;moviendo 10 a w
    incf residue 
    subwf select, f ;resta a residuos 10
    btfsc STATUS, 0
    goto $-3
    decf residue ;incremento variable decenas
    addwf select 
    movf residue, w
    call tablita
    movwf control7
    movf select, w
    call tablita
    movwf control8    
    return 
    
    div3: ;tercera subrutina de separacion de valores
    clrf select
    clrf residue
    bcf STATUS, 0
    movf TL, 0 ;moviendo datos del contador a w
    movwf prtime3
    movwf select ;moviendo w a variable de residuo
    movlw 10 ;moviendo 10 a w
    incf residue
    subwf select, f ;resta a residuos 10
    btfsc STATUS, 0
    goto $-3
    decf residue ;incremento variable decenas
    addwf select 
    movf residue, w
    call tablita
    movwf control7
    movf select, w
    call tablita
    movwf control8
    return 
    
    ;divisiones para timers
    d_div1:
    clrf select
    clrf residue
    bcf STATUS, 0
    movf timer1, w
    movwf select 
    movlw 10
    incf residue
    subwf select, f
    btfsc STATUS, 0
    goto $-3
    decf residue
    addwf select 
    movf residue, w
    call tablita
    movwf control1
    movf select, w
    call tablita
    movwf control2    
    return
    
    d_div2:
    clrf select
    clrf residue
    bcf STATUS, 0
    movf timer2, w
    movwf select 
    movlw 10
    incf residue
    subwf select, f
    btfsc STATUS, 0
    goto $-3
    decf residue
    addwf select 
    movf residue, w
    call tablita
    movwf control3
    movf select, w
    call tablita
    movwf control4
    return 
    
    d_div3:
    clrf select
    clrf residue
    bcf STATUS, 0
    movf timer3, w
    movwf select 
    movlw 10
    incf residue
    subwf select, f
    btfsc STATUS, 0
    goto $-3
    decf residue
    addwf select 
    movf residue, w
    call tablita
    movwf control5
    movf select, w
    call tablita
    movwf control6
    return
    
    config_accept:
    movlw 10
    call tablita ;muestra AC en el display para saber el modo
    movwf control7
    movlw 12
    call tablita
    movwf control8
    
    btfss PORTB, 0 ;revisa si se presiona boton aceptar
    call confirm0 ;llamando rutina de confirmacion
    btfss PORTB, 1 ;revisa si se presiona boton cancelar
    call option5 ;llamando rutina de limpieza de estados
    return
    
    tlstage: ;rutina de seleccion de estados
    
    incf stage ;incrementa variable para verificar el estado
    btfsc flagss, 0
    goto option2
    btfsc flagss, 1
    goto option3
    btfsc flagss, 2
    goto option4
    btfsc flagss, 3
    goto option5
    ;como la variable se encuentra en 0, entra en el primer modo 
    option1: ;modo1
    bcf PORTB, 5 ;apagando leds
    bcf PORTB, 6
    bcf PORTB, 7
    bcf STATUS, 2 ;limpiando bandera de status
    movlw 1
    movwf cselect ;revisando si variable es 1
    movf stage, w
    subwf cselect, w
    btfss STATUS, 2 ;cuando variable sea 1 se activa status
    goto $+4
    bsf PORTB, 5 ;activando led para siguiente estado
    bsf flagss, 0 ;activando bandera de estado
    bsf selectdisp, 0 ;activando bandera de seleccion de division
    return
    
    option2: ;Modo 2
    bcf STATUS, 2
    movlw 2
    movwf cselect ;verificando que variable sea 2
    movf stage, w
    subwf cselect, w
    btfss STATUS, 2 ;se activa status cuando sea 2
    goto $+7
    bcf PORTB, 5
    bsf PORTB, 6 ;se apaga led anterior y prende la siguiente
    bcf flagss, 0
    bsf flagss, 1 ;cambio de banderas
    bcf selectdisp, 0
    bsf selectdisp, 1
    return
    
    option3: ;Modo 3
    bcf STATUS, 2
    movlw 3
    movwf cselect
    movf stage, w
    subwf cselect, w
    btfss STATUS, 2
    goto $+7
    bsf PORTB, 5
    bsf PORTB, 6
    bcf flagss, 1
    bsf flagss, 2
    bcf selectdisp, 1
    bsf selectdisp, 2
    return
    
    option4: ;Modo 4
    bcf STATUS, 2
    movlw 4
    movwf cselect
    movf stage, w
    subwf cselect, w
    btfss STATUS, 2
    goto $+6
    bcf PORTB, 5
    bcf PORTB, 6
    bsf PORTB, 7
    bcf flagss, 2
    bsf flagss, 3
    bcf selectdisp, 2
    bsf selectdisp, 3
    return
    
    option5: ;Modo 5 reinicio
    clrf control7 ;limpiando variables de display para que esten apagados en modo 1
    clrf control8
    bcf PORTB, 7 ;apagando ultima led
    clrf flagss ;limpiando banderas
    clrf stage ;limpiando variable de estado
    clrf selectdisp
    return
    
    up: ;incremento de seleccion
    incf TL ;incrementando variable
    bcf STATUS, 2 ;limpiando status
    movlw 21
    subwf TL, w ;verificando que no sea mayor a 21
    btfss STATUS, 2
    goto $+3
    movlw 10 ;si mayor a 20, regresa a 10
    movwf TL
    return 
    
    down: ;decremento de seleccion
    decf TL ;decrementando variable
    bcf STATUS, 2
    movlw 9 
    subwf TL, w ;verificando que no sea menos a 10
    btfss STATUS, 2
    goto $+3
    movlw 20 ;si llega a menos de 10, regresa a 20
    movwf TL
    return
    
    timers: ;configuracion de los tiempos // en tiempo real
    btfsc flagsTL, 0
    goto TL2
    btfsc flagsTL, 1
    goto TL3
    btfsc flagsTL, 2
    goto clear
    
    TL1: ;timer 1
    bcf STATUS, 2 ;limpiando status
    movf time1, w ;moviendo tiempo a w
    movwf timer1 ;moviendo w a variable
    movf count1, w ;moviendo contador a w
    subwf timer1, 1 ;restando variable del tiempo
    btfss STATUS, 2 ;espera hasta 0
    goto $+4
    bsf flagsTL, 0 ;prende bandera de tl2
    movlw 0 
    movwf count1 ;reinicio de contador de tmr1
    return
    
    TL2: ;timer 2
    bcf STATUS, 2
    movf time2, w
    movwf timer2
    movf count1, w
    subwf timer2, 1
    btfss STATUS, 2
    goto $+5
    bcf flagsTL, 0
    bsf flagsTL, 1
    movlw 0
    movwf count1
    return
    
    TL3: ;timer 3
    bcf STATUS, 2
    movf time3, w
    movwf timer3
    movf count1, w
    subwf timer3, 1
    btfss STATUS, 2
    goto $+3
    bcf flagsTL, 1
    bsf flagsTL, 2
    return
    
    clear: ;reinicio de timers
    clrf count1 ;limpiando contador del timer 1
    clrf flagsTL ;limpiando banderas 
    bcf TMR1IF ;limpiando overflow de timer 1
    return
    
    config_TL: ;se crea un modo para cada luz de semaforo
    ;se utilizan banderas para saber el color en el que deben de estar
    btfsc cflag, 0
    goto TL_2
    btfsc cflag, 1
    goto TL_3
    btfsc cflag, 2
    goto TL_4 
    btfsc cflag, 3
    goto TL_5
    btfsc cflag, 4
    goto TL_6
    btfsc cflag, 5
    goto TL_7
    btfsc cflag, 6
    goto TL_8
    btfsc cflag, 7
    goto TL_9
    btfsc flagreset, 0
    goto resetear
    
    TL_1: ;totalmente verde
    bcf STATUS, 2
    bcf PORTA, 0 ;rojo via 1
    bcf PORTA, 1 ;Amarillo via 1
    bsf PORTA, 2 ;verde via 1
    bsf PORTA, 3 ;rojo via 2
    bcf PORTA, 4 ;amarillo via 2
    bcf PORTA, 5 ;verde via 2
    bsf PORTA, 6 ;rojo via 3
    bcf PORTA, 7 ;amarillo via 3
    bcf PORTB, 4 ;rojo via 3
    
    movf time1, w ;muevo tiempo a w
    movwf greenc ;muevo w a variable totalmente verde
    movlw 6 
    subwf greenc, 1 ;le resto al verde los 6 fijos
    movf greenc, w ;moviendo lo restante a otra variable
    movwf subs
    movf count1, w ;con tmr decremento verde
    subwf greenc, 1
    btfss STATUS, 2 ; cuando esta en 0 se activa bandera status
    goto $+3 ;pasando al siguiente color
    bcf PORTA, 2
    bsf cflag, 0
    return
    
    TL_2: ;verde titilante
    bcf STATUS, 2
    bsf PORTA, 2
    delay_small
    bcf PORTA, 2
    movlw 3
    addwf subs, w
    movwf greent
    movf count1, w
    subwf greent, 1
    btfss STATUS, 2 
    goto $+3
    bcf cflag, 0
    bsf cflag, 1
    return
    
    TL_3: ;amarillo
    bcf STATUS, 2
    bsf PORTA, 1
    movlw 6
    addwf subs, w
    movwf yello
    movf count1, w
    subwf yello, 1
    btfss STATUS, 2
    goto $+4
    bcf cflag, 1
    bsf cflag, 2
    bcf PORTA, 1
    return 
    
    TL_4: ;verde
    bcf STATUS, 2
    bcf PORTA, 3
    bsf PORTA, 0
    bsf PORTA, 5
    movf time2, w
    movwf greenc
    movlw 6
    subwf greenc, 1
    movf greenc, w
    movwf subs
    movf count1, w
    subwf greenc, 1
    btfss STATUS, 2
    goto $+4
    bcf PORTA, 5
    bcf cflag, 2
    bsf cflag, 3
    return
    
    TL_5:;verde titilante
    bcf STATUS, 2
    bsf PORTA, 5
    delay_small
    bcf PORTA, 5
    movlw 3
    addwf subs, w
    movwf greent
    movf count1, w
    subwf greent, 1
    btfss STATUS, 2
    goto $+3
    bcf cflag, 3
    bsf cflag, 4
    return
    
    TL_6: ;amarillo
    bcf STATUS, 2
    bsf PORTA, 4
    movlw 6
    addwf subs, w
    movwf yello
    movf count1, w
    subwf yello, 1
    btfss STATUS, 2
    goto $+4
    bcf cflag, 4
    bsf cflag, 5
    bcf PORTA, 4
    return
    
    TL_7: ;completamente verde
    bcf STATUS, 2
    bcf PORTA, 6
    bsf PORTA, 3
    bsf PORTB, 4
    movf time2, w
    movwf greenc 
    movf fix, w
    subwf greenc, 1
    movf fix, w
    subwf greenc, 1
    movf greenc, w
    movwf subs
    movf count1, w
    subwf greenc, 1
    btfss STATUS, 2
    goto $+4
    bcf PORTB, 4
    bcf cflag, 5
    bsf cflag, 6
    return
    
    TL_8: ;verde titilante
    bcf STATUS, 2
    bsf PORTB, 4
    delay_small
    bcf PORTB, 4
    movlw 3
    addwf subs, w
    movwf greent
    movf count1, w
    subwf greent, 1
    btfss STATUS, 2
    goto $+3
    bcf cflag, 6
    bsf cflag, 7
    return
    
    TL_9: ;amarillo
    bcf STATUS, 2
    bsf PORTA, 7
    movlw 6
    addwf subs, w
    movwf yello
    movf count1, w
    subwf yello, 1
    btfss STATUS, 2
    goto $+5
    bcf cflag, 7
    bsf flagreset, 0
    bcf PORTA, 7
    bsf PORTA, 6
    return
    
    resetear: ;reseteo de los semaforos
    clrf greenc
    clrf greent
    clrf yello
    clrf subs
    clrf cflag
    bcf flagreset, 0
    clrf STATUS
    return
    
    delay_small:
    movlw 248 ;valor inicial del contador
    movwf contsmall
    decfsz contsmall, 1 ;decrementando contador
    goto $-1 ;ejecutando linea anterior
    return
    
    complete_reset: ;limpiando banderas para un reinicio total
    
    call option5
    clrf flagsTL
    clrf cflag
    clrf flagss
    clrf count1
    clrf selectdisp
    clrf timer1
    clrf timer2
    clrf timer3
    return
    
    ;cargando valores a displays
    confirm0:
    ;resetea todo, como si se apagara el pic pero le carga los tiempos de las
    ;divisiones 
    movlw 5
    movwf fix ;arreglo para el semaforo
    bsf restart, 0 ;para detener displays
    call complete_reset ;llamando al reseteo total
    movf prtime1, w ;moviendo variables a timers
    movwf time1
    movf prtime2, w
    movwf time2
    movf prtime3, w
    movwf time3
    delay_small
    bcf restart, 0 ;apaga un instante los displays
    return
    
   
    
;---------------- CALLS - Config ------------;
    
config_io:
    
    BANKSEL ANSEL
    clrf ANSEL
    clrf ANSELH
    
    ;configurando puerto A como salida
    BANKSEL TRISA
    bcf TRISA, 0
    bcf TRISA, 1
    bcf TRISA, 2
    bcf TRISA, 3
    bcf TRISA, 4
    bcf TRISA, 5
    bcf TRISA, 6
    bcf TRISA, 7
    
    ;configurando puerto B como entrada y salida
    BANKSEL TRISB
    bsf TRISB, 0
    bsf TRISB, 1
    bsf TRISB, 2
    bcf TRISB, 4
    bcf TRISB, 5
    bcf TRISB, 6
    bcf TRISB, 7
    
    ;configurando puerto c como salida
    BANKSEL TRISC
    bcf TRISC, 0
    bcf TRISC, 1
    bcf TRISC, 2
    bcf TRISC, 3
    bcf TRISC, 4
    bcf TRISC, 5
    bcf TRISC, 6
    bcf TRISC, 7
    
    ;Configurando puerto d como salida
    BANKSEL TRISD
    bcf TRISD, 0
    bcf TRISD, 1
    bcf TRISD, 2
    bcf TRISD, 3
    bcf TRISD, 4
    bcf TRISD, 5
    bcf TRISD, 6
    bcf TRISD, 7
    return
    
    config_pullup:
    ;poniendo puerto b en pullup
    BANKSEL OPTION_REG
    bcf OPTION_REG, 7
    
    BANKSEL WPUB
    bsf WPUB, 0 ;activando pullup interno
    bsf WPUB, 1 
    bsf WPUB, 2 
    bcf WPUB, 3 ;desactivando pullups internos
    bcf WPUB, 4
    bcf WPUB, 5
    bcf WPUB, 6
    bcf WPUB, 7 
    return
  
    config_tmr0:
    BANKSEL OPTION_REG
    bcf T0CS
    bcf PSA ;prescaler asignado al tmr0
    bsf PS0 ;valor 1:256
    bsf PS1
    bsf PS2
    return
    
    config_tmr1:
    BANKSEL T1CON
    bsf T1CKPS1 ;prescaler 1:8
    bsf T1CKPS0
    bcf TMR1CS ;internal clock
    bsf TMR1ON ;habilitando tmr1
    return
     
    config_tmr2:
    BANKSEL T2CON
    movlw 1001110B ;1001 para postcaler, 1 timer 2 on, 10 prescaler 16
    movwf T2CON
    return
    
    default_config: ;moviendo a variables determinadas para que empiecen donde se quiere 
    movlw 10
    movwf TL ;variable del display de estado
    movwf time1 ;tiempo inicial timer 1
    movwf time2 ;tiempo inicial timer 2
    movwf time3 ;tiempo inicial timer 3
    movlw 6
    movwf fix ;correccion desfase de tiempos
    return
   
    END
   
    