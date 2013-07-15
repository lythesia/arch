;
; protect mode swith(large adressing space > 5MB)
;

%include "pm.inc"

  org 0100h
  jmp LABEL_BEGIN

[SECTION .gdt]
; GDT
;
LABEL_GDT:          Descriptor        0,                 0,               0 ; empty
LABEL_DESC_NORMAL:  Descriptor        0,            0ffffh,          DA_DRW ; normal
LABEL_DESC_CODE32:  Descriptor        0,  SegCode32Len - 1,    DA_C + DA_32 ; non-confirming
LABEL_DESC_CODE16:  Descriptor        0,            0ffffh,            DA_C ; non-confirming
LABEL_DESC_DATA:    Descriptor        0,       DataLen - 1,          DA_DRW ; data
LABEL_DESC_STACK:   Descriptor        0,        TopOfStack, DA_DRWA + DA_32 ; stack32
LABEL_DESC_TEST:    Descriptor 0500000h,            0ffffh,          DA_DRW ; 
LABEL_DESC_VIDEO:   Descriptor  0b8000h,            0ffffh,          DA_DRW ; video mem addr
; end GDT

GdtLen  equ $ - LABEL_GDT ; GDT length
GdtPtr  dw  GdtLen - 1    ; GDT limit
        dd  0             ; GDT base

; GDT selector(offset in GDT)
SelectorNormal  equ LABEL_DESC_NORMAL - LABEL_GDT
SelectorCode32  equ LABEL_DESC_CODE32 - LABEL_GDT
SelectorCode16  equ LABEL_DESC_CODE16 - LABEL_GDT
SelectorData    equ LABEL_DESC_DATA   - LABEL_GDT
SelectorStack   equ LABEL_DESC_STACK  - LABEL_GDT
SelectorTest    equ LABEL_DESC_TEST   - LABEL_GDT
SelectorVideo   equ LABEL_DESC_VIDEO  - LABEL_GDT
; end [SECTION .gdt]

[SECTION .data1]  ; data-seg
ALIGN 32
[BITS 32]
LABEL_DATA:
SPValueInRealMode dw  0
; strings
PMMessage:        db  "In Protect Mode now. 0.0", 0
OffsetPMMessage   equ PMMessage - $$ ; offset from LABEL_DATA
StrTest:          db  "ABCDEFGHIJKLMNOPQRSTUVWXYZ", 0
OffsetStrTest     equ StrTest - $$ ; offset from LABEL_DATA
DataLen           equ $ - LABEL_DATA
; end [SECTION .data1]

; global stack seg
[SECTION .gs]
ALIGN 32
[BITS 32]
LABEL_STACK:
  times 512 db  0

TopOfStack  equ $ - LABEL_STACK - 1
; end [SECTION .gs]

; start from 16-bit code
[SECTION .s16]
[BITS	16]
LABEL_BEGIN:
	mov	  ax, cs
	mov	  ds, ax
	mov	  es, ax
	mov	  ss, ax
	mov	  sp, 0100h

	mov	  [LABEL_GO_BACK_TO_REAL+3], ax 
                                                 |  4  |  3  |  2  |  1  |  0  |
        ; "jmp 0:LABEL_GO_BACK_TO_REAL" struct-> |  segment  |   offset  | 0eah|
        ; so ax(hold cs) fill to "segment"______/
	mov	  [SPValueInRealMode], sp

  ; init code16-seg-desc
	mov	  ax, cs
	movzx	eax, ax
	shl	  eax, 4
	add	  eax, LABEL_SEG_CODE16
	mov	  word [LABEL_DESC_CODE16 + 2], ax
	shr	  eax, 16
	mov	  byte [LABEL_DESC_CODE16 + 4], al
	mov	  byte [LABEL_DESC_CODE16 + 7], ah

  ; init code32-seg-desc
	xor	  eax, eax
	mov	  ax, cs
	shl	  eax, 4
	add	  eax, LABEL_SEG_CODE32
	mov	  word [LABEL_DESC_CODE32 + 2], ax
	shr	  eax, 16
	mov	  byte [LABEL_DESC_CODE32 + 4], al
	mov	  byte [LABEL_DESC_CODE32 + 7], ah

  ; init data-seg-desc
	xor 	eax, eax
	mov 	ax, ds
	shl 	eax, 4
	add 	eax, LABEL_DATA
	mov 	word [LABEL_DESC_DATA + 2], ax
	shr 	eax, 16
	mov 	byte [LABEL_DESC_DATA + 4], al
	mov 	byte [LABEL_DESC_DATA + 7], ah

  ; init stack-seg-desc
	xor 	eax, eax
	mov 	ax, ds
	shl 	eax, 4
	add 	eax, LABEL_STACK
	mov 	word [LABEL_DESC_STACK + 2], ax
	shr 	eax, 16
	mov 	byte [LABEL_DESC_STACK + 4], al
	mov 	byte [LABEL_DESC_STACK + 7], ah

  ; prepare load GDTR
	xor 	eax, eax
	mov 	ax, ds
	shl 	eax, 4
	add 	eax, LABEL_GDT		      ; eax <- gdt base addr
	mov 	dword [GdtPtr + 2], eax	; [GdtPtr + 2] <- gdt base addr

	; load GDTR
	lgdt	[GdtPtr]

	; int off
	cli

	; open A20
	in	al, 92h
	or	al, 00000010b
	out	92h, al

	; prepare switch to protect mode
	mov	eax, cr0
	or	eax, 1
	mov	cr0, eax

	; enter protect mode
	jmp	dword SelectorCode32:0	; cs <- SelectorCode32, jump to SelectorCode32:0

;;;; back from 32-bit code

LABEL_REAL_ENTRY:
  mov   ax, cs
  mov   ds, ax
  mov   es, ax
  mov   ss, ax

  mov   sp, [SPValueInRealMode]

  ; close A20
  in    al, 92h
  and   al, 11111101b
  out   92h, al

  ; int on
  sti

  ; main return to DOS
  mov   ax, 4c00h
  int   21h
; end [SECTION .s16]

; 32-bit code seg(jumpped from real mode)
[SECTION .s32]
[BITS 32]

LABEL_SEG_CODE32:
  mov   ax, SelectorData
  mov   ds, ax
  mov   ax, SelectorTest
  mov   es, ax
  mov   ax, SelectorVideo
  mov   gs, ax

  mov   ax, SelectorStack
  mov   ss, ax

  mov   esp, TopOfStack

  ; display a string
  mov   ah, 0ch
  xor   esi, esi
  xor   edi, edi
  mov   esi, OffsetPMMessage    ; src offset
  mov   edi, (80 * 10 + 0) * 2  ; dst offset
  cld   ; inc si/di
.1:
  lodsb ; ds:esi->al per byte, si++
  test  al, al
  jz    .2
  mov   [gs:edi], ax
  add   edi, 2  ; 2 because ax(2 bytes)
  jmp   .1
.2: ; display over
  call DispReturn

  call  TestRead
  call  TestWrite
  call  TestRead

  ; stop
  jmp SelectorCode16:0

; begin TestRead ---------------------------
TestRead:
  xor   esi, esi
  mov   ecx, 8        ; loop 8 times
.loop:
  mov   al, [es:esi]  ; read byte from 5MB position space
  call  DispAL
  inc   esi
  loop  .loop

  call  DispReturn
  ret
; end TestRead -----------------------------

; begin TestWrite --------------------------
TestWrite:
  push  esi
  push  edi
  xor   esi, esi
  xor   edi, edi
  mov   esi, OffsetStrTest
  cld
.1:
  lodsb
  test  al, al
  jz    .2
  mov   [es:edi], al  ; write byte to 5MB position space
  inc   edi
  jmp   .1
.2:
  pop   edi
  pop   esi

  ret
; end TestWrite ----------------------------

; ------------------------------------------
; Display value in al
; edi - position of next char to display
; ------------------------------------------
DispAL:
  push  ecx
  push  edx

  mov   ah, 0ch
  mov   dl, al        ; save in dl
  shr   al, 4
  mov   ecx, 2        ; loop 2 times because 2-bit hex number('A'<=>'41')
.begin:
  and   al, 01111b    ; high 4 bits -> 0
  cmp   al, 9
  ja    .1
  add   al, '0'
  jmp   .2
.1:
  sub   al, 0ah
  add   al, 'A'
.2:
  mov   [gs:edi], ax  ; write to video mem
  add   edi, 2

  mov   al, dl        ; restore al
  loop  .begin
  add   edi, 2        ; a white space

  pop   edx
  pop   ecx
  ret
; end DispAL -------------------------------

; begin DispReturn -------------------------
DispReturn:
  push  eax
  push  ebx
  mov   eax, edi
  mov   bl, 160
  div   bl  ; ax/bl->al...ah
  and   eax, 0ffh
  inc   eax ; eax<-00ax+1
  mov   bl, 160
  mul   bl  ; al*bl->ax
  mov   edi, eax
  pop   ebx
  pop   eax

  ret
; end DispReturn ---------------------------

SegCode32Len  equ $ - LABEL_SEG_CODE32
; end [SECTION .s32]

; 16-bit code(jumpped from 32-bit code, then jump to real mode)
[SECTION .s16code]
ALIGN 32
[BITS 16]
LABEL_SEG_CODE16:
  mov   ax, SelectorNormal
  mov   ds, ax
  mov   es, ax
  mov   fs, ax
  mov   gs, ax
  mov   ss, ax

  mov   eax, cr0
  and   al, 11111110b
  mov   cr0, eax

LABEL_GO_BACK_TO_REAL:
  jmp   0:LABEL_REAL_ENTRY  ; in actual "jmp cs:LABEL_REAL_ENTRY"

; end [SECTIOIN .s16code]
