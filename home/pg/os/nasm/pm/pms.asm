;
; protect mode swith(small adressing space < 1MB)
;

%include "pm.inc"

org   07c00h
jmp   LABEL_BEGIN ; start from 16-bit code

[SECTION .gdt]
; GDT
; defined as struct(Descriptor) array
;                       seg-base         seg-limit            attr
LABEL_GDT:          Descriptor       0,                 0,            0 ; empty desc
LABEL_DESC_CODE32:  Descriptor       0,  SegCode32Len - 1, DA_C + DA_32 ; 32x code
LABEL_DESC_VIDEO:   Descriptor 0b8000h,            0ffffh,       DA_DRW ; rw data
; end GDT

; GDT length
GdtLen  equ   $ - LABEL_GDT
; 6-byte size struct: |      GDT base(4byte)      | limit(2byte) | (hight -> low)
GdtPtr  dw    GdtLen - 1 ; limit
        dd    0          ; base

; GDT selector
SelectorCode32    equ   LABEL_DESC_CODE32 - LABEL_GDT
SelectorVideo     equ   LABEL_DESC_VIDEO  - LABEL_GDT
; end [SECTION .gdt]

[SECTION .s16]
[BITS 16]
LABEL_BEGIN:
  mov   ax, cs
  mov   ds, ax
  mov   es, ax
  mov   ss, ax
  mov   sp, 0100h

  ; init code32-seg-desc(in actual fill seg-base part only)
  xor   eax, eax
  mov   ax, cs
  shl   eax, 4
  add   eax, LABEL_SEG_CODE32
  mov   word [LABEL_DESC_CODE32 + 2], ax
  shr   eax, 16
  mov   byte [LABEL_DESC_CODE32 + 4], al
  mov   byte [LABEL_DESC_CODE32 + 7], ah

  ; preprare load GDTR
  xor   eax, eax
  mov   ax, ds
  shl   eax, 4
  add   eax, LABEL_GDT
  mov   dword [GdtPtr + 2], eax ; load PA of GDT to GdtPtr

  ; load GDTR
  lgdt  [GdtPtr] ; load content of GdtPtr(aka PA of GDT) to gdtr register

  ; int off
  cli

  ; open A20
  in    al, 92h
  or    al, 00000010b
  out   92h, al

  ; prepare swith to protect mode
  mov   eax, cr0
  or    eax, 1
  mov   cr0, eax

  ; enter protect mode
  jmp   dword SelectorCode32:0
; end [SECTION .s16]

[SECTION .s32]
[BITS 32]

; write red 'P' to video
LABEL_SEG_CODE32:
  mov   ax, SelectorVideo
  mov   gs, ax

  mov   edi, (80 * 11 + 79) * 2 ; row[11], col[79] on screen
  mov   ah, 0ch                 ; 0000b: black bg; 0011b: red fg
  mov   al, 'P'
  mov   [gs:edi], ax

  ; stop
  jmp   $

SegCode32Len  equ   $ - LABEL_SEG_CODE32
; end [SECTION .s32]
