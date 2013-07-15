;---------------------------------;
; DA_${..} : Descriptor Attribute ;
;    D     : data seg             ;
;    C     : code seg             ;
;    S     : sys  seg             ;
;    R     : read only            ;
;    RW    : read & write         ;
;    A     : accessed             ;
;    others as name semantic      ;
;---------------------------------;
; Descriptor Attribute

DA_32   equ   4000h ; 32bit segment attr

; DPL
DA_DPL0 equ   00h   ; DPL = 0
DA_DPL1 equ   20h   ; DPL = 1
DA_DPL2 equ   40h   ; DPL = 2
DA_DPL3 equ   60h   ; DPL = 3

; Store Seg(rwx like)
DA_DR   equ   90h   ; r data-seg
DA_DRW  equ   92h   ; rw data-seg
DA_DRWA equ   93h   ; accessed rw data-seg
DA_C    equ   98h   ; x code-seg
DA_CR   equ   9ah   ; rx code-seg
DA_CCO  equ   9ch   ; confirming x code-seg
DA_CCOR equ   9eh   ; confirming rx code-seg

; System Seg
DA_LDT    equ   82h   ; local descriptor table
DA_TG     equ   85h   ; task gate
DA_386TSS equ   89h   ; 386 task status seg
DA_386CG  equ   8ch   ; 386 call gate
DA_386IG  equ   8eh   ; 386 interrupt gate
DA_386TG  equ   8fh   ; 386 trap gate

; Descriptor
; Usage: Descriptor base, limit, attr
;        base:  dd
;        limit: dd(low 20 bits available)
;        attr:  dw(low 4 bits of higher byte always 0)
;
; Descriptor struct
; |76543210|76543210|76543210|76543210|76543210|76543210|76543210|76543210| bit
; |    7   |    6   |    5   |    4   |    3   |    2   |    1   |    0   | byte
; |  base2 |       attr      |           base1          |      limit1     | content
;          |                  \_____________________
;          |                                        \______________________
;          |                                                               \
;          | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 | bit
;          | G | D | 0 |AVL|     limit2    | P |  DPL  | S |      TYPE     | attr
%macro  Descriptor 3
        dw  %2 & 0ffffh ; 1-0 = limit[15:0]
        dw  %1 & 0ffffh ; 3-2 = base[15:0]
        db  (%1 >> 16) & 0ffh ; 4 = base[23:16]
        dw  ((%2 >> 8) & 0f00h | (%3 & 0f0ffh)) ; 6[3:0] = limit[19:16]
                                                ; 6[7:4] = attr[15:12], 5 = attr[7:0]
        db  (%1 >> 24) & 0ffh ; 7 = base[31:24]
%endmacro ; 8 bytes in total
