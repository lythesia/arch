#include "pm.h"
.code16
.text
  jmp   LABEL_BEGIN // jump over data section

/* Global Descriptor Table */
LABEL_GDT:          Descriptor       0,                   0,  0
LABEL_DESC_CODE32:  Descriptor       0,  (SegCode32Len - 1),  (DA_C + DA_32)
LABEL_DESC_VIDEO:   Descriptor 0xb8000,              0xffff,  DA_DRW

.set GdtLen, (. - LABEL_GDT)

GdtPtr: .2byte  (GdtLen - 1)  // GDT limit
        .4byte  0             // GDT base, need to be filled at run-time

/* actually selector is 16-bit struct:
 * |7 6 5 4 3 2 1 0|7 6 5 4 3 2 1 0|
 * |    descriptor index     |T| R |  T=TI: 0-GDT, 1-LDT; R=RPL: privilege, 00(high)~11(low)
 * since descriptor's size is 8-byte, so offset-diff in GDT always make lowest 3bit as 000,
 * thus we can use it as selector directly
 */
.set SelectorCode32,  (LABEL_DESC_CODE32 - LABEL_GDT)
.set SelectorVideo,   (LABEL_DESC_VIDEO  - LABEL_GDT)

LABEL_BEGIN:
  /* use CS init DS, ES and SS, because we have embedded .data section into .code section
   * though it's not allowd in normal app, but for OS that is OK here.
   */
  mov   %cs, %ax
  mov   %ax, %ds
  mov   %ax, %es
  mov   %ax, %ss

  mov   $0x100, %sp

  /* init 32-bit code segment descriptor */
  xor   %eax, %eax
  mov   %cs, %ax
  shl   $4, %eax
  addl  $(LABEL_SEG_CODE32), %eax
  movw  %ax, (LABEL_DESC_CODE32 + 2)
  shr   $16, %eax
  movb  %al, (LABEL_DESC_CODE32 + 4)
  movb  %ah, (LABEL_DESC_CODE32 + 7)

  /* prepare loading GDTR */
  xor   %eax, %eax
  mov   %ds, %ax
  shl   $4, %eax
  add   $(LABEL_GDT), %eax // %eax = GDT base address
  movl  %eax, (GdtPtr + 2)

  /* load */
  lgdtw GdtPtr

  /* interrupt off */
  cli

  /* open A20 line */
  inb   $0x92, %al
  orb   $0b00000010, %al
  outb  %al, $0x92

  /* enable protect mode */
  movl  %cr0, %eax
  orl   $1, %eax
  movl  %eax, %cr0

  /* mixed-size jump */
  ljmpl $SelectorCode32, $0

LABEL_SEG_CODE32:
.code32
  mov   $(SelectorVideo), %ax
  mov   %ax, %gs

  movl  $((80 * 10 + 0) * 2), %edi
  movb  $0xc, %ah
  movb  $'P', %al

  mov   %ax, %gs:(%edi) // write to video mem(this address is 32bit long)

  jmp   .

/* get length of 32-bit segment code */
.set  SegCode32Len, . - LABEL_SEG_CODE32
