;)              _
;)  ___ ___ _ _|_|___ ___
;) |  _| .'|_'_| |_ -|_ -|
;) |_| |__,|_,_|_|___|___|
;)    raxiss (c) 2019,2020

;********************************
;*   APPLE-II  PSEUDO MACHINE   *
;*         INTERPRETER          *
;*      COPYRIGHT (C) 1977      *
;*     APPLE COMPUTER,  INC     *
;*     ALL  RIGHTS RESERVED     *
;*         S. WOZNIAK           *
;********************************
;* TITLE   SWEET 16 INTERPRETER *
;********************************

;------------------------------
#define R0      $40
#define RL(x)   (R0+((x)*2))
#define RH(x)   (RL(x)+1)

;------------------------------
R0L      =   RL(0)
R0H      =   RH(0)
R14L     =   RL(14)
R14H     =   RH(14)
R15L     =   RL(15)
R15H     =   RH(15)

;------------------------------
_SW16                       ;MAIN ENTRYPOINT OF SW16
        JSR SW16_SAVE       ;PRESERVE 6502 REG CONTENTS
;------------------------------
        PLA                 ;AFTER 6502 MODE
        STA  R15L           ;INIT SWEET16 PC
        PLA                 ;FROM RETURN
        STA  R15H           ;ADDRESS
SW16B
        JSR  SW16C          ;INTERPRET AND EXECUTE
        JMP  SW16B          ;ONE SWEET16 INSTR.
SW16C
        INC  R15L
        BNE  SW16D          ;INCR SWEET16 PC FOR FETCH
        INC  R15H
SW16D
        LDY  #$0
        LDA  (R15L),Y       ;FETCH INSTR
        AND  #$F            ;MASK REG SPECIFICATION
        ASL                 ;DOUBLE FOR TWO BYTE REGISTERS
        TAX                 ;TO X REG FOR INDEXING
        LSR
        EOR  (R15L),Y       ;NOW HAVE OPCODE
        BEQ  TOBR           ;IF ZERO THEN NON-REG OP
        STX  R14H           ;INDICATE "PRIOR RESULT REG"
        LSR
        LSR                 ;OPCODE*2 TO LSBS
        LSR
        TAY                 ;TO Y REG FOR INDEXING
        LDA  OPTBH-2,Y      ;HIGH ORDER ADR BYTE
        PHA
        LDA  OPTBL-2,Y      ;LOW ORDER ADR BYTE
        PHA                 ;ONTO STACK
        LDA  #0             ;FORCE BPL TO BE TAKEN ALWAYS
        RTS                 ;GOTO REG-OP ROUTINE
TOBR
        INC  R15L
        BNE  TOBR1          ;INCR PC
        INC  R15H
TOBR1
        LDA  BRTBH,X        ;HIGH ORDER ADR BYTE
        PHA
        LDA  BRTBL,X        ;LOW ORDER ADR BYTE
        PHA                 ;ONTO STACK FOR NON-REG OP
        LDA  R14H           ;"PRIOR RESULT REG" INDEX
        LSR                 ;PREPARE CARRY FOR BC, BNC.
        RTS                 ;GOTO NON-REG OP ROUTINE
RTNZ
        PLA                 ;POP RETURN ADDRESS
        PLA
;------------------------------
        JSR  SW16_RESTORE   ;RESTORE 6502 REG CONTENTS
        JMP  (R15L)         ;RETURN TO 6502 CODE VIA PC

;------------------------------
SETZ
        LDA  (R15L),Y       ;HIGH ORDER BYTE OF CONSTANT
        STA  R0H,X
        DEY
        LDA  (R15L),Y       ;LOW ORDER BYTE OF CONSTANT
        STA  R0L,X
        TYA                 ;Y REG CONTAINS 1
        SEC
        ADC  R15L           ;ADD 2 TO PC
        STA  R15L
        BCC  SET2
        INC  R15H
SET2
        RTS

;------------------------------
SET
        BPL  SETZ           ;ALWAYS TAKEN
LD
        LDA  R0L,X
BK
        STA  R0L
        LDA  R0H,X          ;MOVE RX TO R0
        STA  R0H
        RTS
ST
        LDA  R0L
        STA  R0L,X          ;MOVE R0 TO RX
        LDA  R0H
        STA  R0H,X
        RTS
STAT
        LDA  R0L
STAT2
        STA  (R0L,X)        ;STORE BYTE INDIRECT
        LDY  #$0
STAT3
        STY  R14H           ;INDICATE R0 IS RESULT NEG
INR
        INC  R0L,X
        BNE  INR2           ;INCR RX
        INC  R0H,X
INR2
        RTS
LDAT
        LDA  (R0L,X)        ;LOAD INDIRECT (RX)
        STA  R0L            ;TO R0
        LDY  #$0
        STY  R0H            ;ZERO HIGH ORDER R0 BYTE
        BEQ  STAT3          ;ALWAYS TAKEN
POP
        LDY  #$0            ;HIGH ORDER BYTE = 0
        BEQ  POP2           ;ALWAYS TAKEN
POPD
        JSR  DCR            ;DECR RX
        LDA  (R0L,X)        ;POP HIGH ORDER BYTE @RX
        TAY                 ;SAVE IN Y REG
POP2
        JSR  DCR            ;DECR RX
        LDA  (R0L,X)        ;LOW ORDER BYTE
        STA  R0L            ;TO R0
        STY  R0H
POP3
        LDY  #$0            ;INDICATE R0 AS LAST RESULT REG
        STY  R14H
        RTS
LDDAT
        JSR  LDAT           ;LOW ORDER BYTE TO R0, INCR RX
        LDA  (R0L,X)        ;HIGH ORDER BYTE TO R0
        STA  R0H
        JMP  INR            ;INCR RX
STDAT
        JSR  STAT           ;STORE INDIRECT LOW ORDER
        LDA  R0H            ;BYTE AND INCR RX. THEN
        STA  (R0L,X)        ;STORE HIGH ORDER BYTE.
        JMP  INR            ;INCR RX AND RETURN
STPAT
        JSR  DCR            ;DECR RX
        LDA  R0L
        STA  (R0L,X)        ;STORE R0 LOW BYTE @RX
        JMP  POP3           ;INDICATE R0 AS LAST RESULT REG
DCR
        LDA  R0L,X
        BNE  DCR2           ;DECR RX
        DEC  R0H,X
DCR2
        DEC  R0L,X
        RTS
SUB
        LDY  #$0            ;RESULT TO R0
CPR
        SEC                 ;NOTE Y REG = 13*2 FOR CPR
        LDA  R0L
        SBC  R0L,X
        STA  R0L,Y          ;R0-RX TO RY
        LDA  R0H
        SBC  R0H,X
SUB2
        STA  R0H,Y
        TYA                 ;LAST RESULT REG*2
        ADC  #$0            ;CARRY TO LSB
        STA  R14H
        RTS
ADD
        LDA  R0L
        ADC  R0L,X
        STA  R0L            ;R0+RX TO R0
        LDA  R0H
        ADC  R0H,X
        LDY  #$0            ;R0 FOR RESULT
        BEQ  SUB2           ;FINISH ADD
BS
        LDA  R15L           ;NOTE X REG IS 12*2!
        JSR  STAT2          ;PUSH LOW PC BYTE VIA R12
        LDA  R15H
        JSR  STAT2          ;PUSH HIGH ORDER PC BYTE
BR
        CLC
BNC
        BCS  BR2           ;NO CARRY TEST
BR1
        LDA  (R15L),Y       ;DISPLACEMENT BYTE LOW
        PHA
        INY
        LDA  (R15L),Y       ;DISPLACEMENT BYTE HIGH
        STA  R15H
        PLA
        STA  R15L
        RTS
BR2
        INC  R15L
        BNE  NUL
        INC  R15H
NUL
        RTS
BC
        BCS  BR
        JMP  BR2
BP
        ASL                 ;DOUBLE RESULT-REG INDEX
        TAX                 ;TO X REG FOR INDEXING
        LDA  R0H,X          ;TEST FOR PLUS
        BPL  BR1            ;BRANCH IF SO
        JMP  BR2
BM
        ASL                 ;DOUBLE RESULT-REG INDEX
        TAX
        LDA  R0H,X          ;TEST FOR MINUS
        BMI  BR1
        JMP  BR2
BZ
        ASL                 ;DOUBLE RESULT-REG INDEX
        TAX
        LDA  R0L,X          ;TEST FOR ZERO
        ORA  R0H,X          ;(BOTH BYTES)
        BEQ  BR1            ;BRANCH IF SO
        JMP  BR2
BNZ
        ASL                 ;DOUBLE RESULT-REG INDEX
        TAX
        LDA  R0L,X          ;TEST FOR NON-ZERO
        ORA  R0H,X          ;(BOTH BYTES)
        BNE  BR1            ;BRANCH IF SO
        JMP  BR2
BM1
        ASL                 ;DOUBLE RESULT-REG INDEX
        TAX
        LDA  R0L,X          ;CHECK BOTH BYTES
        AND  R0H,X          ;FOR #$FF (MINUS 1)
        EOR  #$FF
        BEQ  BR1            ;BRANCH IF SO
        JMP  BR2
BNM1
        ASL                 ;DOUBLE RESULT-REG INDEX
        TAX
        LDA  R0L,X
        AND  R0H,X          ;CHECK BOTH BYTES FOR NO #$FF
        EOR  #$FF
        BNE  BR1            ;BRANCH IF NOT MINUS 1
        JMP  BR2
RS
        LDX  #$18           ;12*2 FOR R12 AS STACK POINTER
        JSR  DCR            ;DECR STACK POINTER
        LDA  (R0L,X)        ;POP HIGH RETURN ADDRESS TO PC
        STA  R15H
        JSR  DCR            ;SAME FOR LOW ORDER BYTE
        LDA  (R0L,X)
        STA  R15L
        JMP  BR2
RTN
        JMP  RTNZ

;------------------------------
OPTBL
       .BYTE <(SET-1)        ;1X
BRTBL
       .BYTE <(RTN-1)        ;0
       .BYTE <(LD-1)         ;2X
       .BYTE <(BR-1)         ;1
       .BYTE <(ST-1)         ;3X
       .BYTE <(BNC-1)        ;2
       .BYTE <(LDAT-1)       ;4X
       .BYTE <(BC-1)         ;3
       .BYTE <(STAT-1)       ;5X
       .BYTE <(BP-1)         ;4
       .BYTE <(LDDAT-1)      ;6X
       .BYTE <(BM-1)         ;5
       .BYTE <(STDAT-1)      ;7X
       .BYTE <(BZ-1)         ;6
       .BYTE <(POP-1)        ;8X
       .BYTE <(BNZ-1)        ;7
       .BYTE <(STPAT-1)      ;9X
       .BYTE <(BM1-1)        ;8
       .BYTE <(ADD-1)        ;AX
       .BYTE <(BNM1-1)       ;9
       .BYTE <(SUB-1)        ;BX
       .BYTE <(BK-1-1)       ;A
       .BYTE <(POPD-1)       ;CX
       .BYTE <(RS-1)         ;B
       .BYTE <(CPR-1)        ;DX
       .BYTE <(BS-1)         ;C
       .BYTE <(INR-1)        ;EX
       .BYTE <(NUL-1)        ;D
       .BYTE <(DCR-1)        ;FX
       .BYTE <(NUL-1)        ;E
       .BYTE <(NUL-1)        ;UNUSED
       .BYTE <(NUL-1)        ;F

;------------------------------
OPTBH
       .BYTE >(SET-1)        ;1X
BRTBH
       .BYTE >(RTN-1)        ;0
       .BYTE >(LD-1)         ;2X
       .BYTE >(BR-1)         ;1
       .BYTE >(ST-1)         ;3X
       .BYTE >(BNC-1)        ;2
       .BYTE >(LDAT-1)       ;4X
       .BYTE >(BC-1)         ;3
       .BYTE >(STAT-1)       ;5X
       .BYTE >(BP-1)         ;4
       .BYTE >(LDDAT-1)      ;6X
       .BYTE >(BM-1)         ;5
       .BYTE >(STDAT-1)      ;7X
       .BYTE >(BZ-1)         ;6
       .BYTE >(POP-1)        ;8X
       .BYTE >(BNZ-1)        ;7
       .BYTE >(STPAT-1)      ;9X
       .BYTE >(BM1-1)        ;8
       .BYTE >(ADD-1)        ;AX
       .BYTE >(BNM1-1)       ;9
       .BYTE >(SUB-1)        ;BX
       .BYTE >(BK-1-1)       ;A
       .BYTE >(POPD-1)       ;CX
       .BYTE >(RS-1)         ;B
       .BYTE >(CPR-1)        ;DX
       .BYTE >(BS-1)         ;C
       .BYTE >(INR-1)        ;EX
       .BYTE >(NUL-1)        ;D
       .BYTE >(DCR-1)        ;FX
       .BYTE >(NUL-1)        ;E
       .BYTE >(NUL-1)        ;UNUSED
       .BYTE >(NUL-1)        ;F


;------------------------------
STATUS .BYTE 0
XREG   .BYTE 0
YREG   .BYTE 0
AREG   .BYTE 0
;------------------------------
SW16_SAVE
        PHP
        STA  AREG
        STX  XREG
        STY  YREG
        PLA
        STA  STATUS
        CLD
        RTS

;------------------------------
SW16_RESTORE
        LDA  STATUS
        PHA
        LDX  XREG
        LDY  YREG
        LDA  AREG
        PLP
        RTS

;------------------------------
_SW16_INIT
        LDX  #$00
        TXA
SWI1
        STA  R0,X
        INX
        CPX  #$20
        BNE  SWI1
        RTS

;------------------------------
