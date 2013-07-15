#include "pm.h"
.code16
.text
  jmp   LABEL_BEGIN // jump over data section

/* Global Descriptor Table */
LABEL_GDT:          Descriptor       0,                   0,  0
LABEL_DESC_CODE32:  Descriptor       0,  (SegCode32Len - 1),  (DA_C + DA_32)
LABEL_DESC_DATA:    Descriptor       0,       (DataLen - 1),  DA_DRW
LABEL_DESC_STACK:   Descriptor       0,          TopOfStack,  (DA_DRWA + DA_32)
LABEL_DESC_VIDEO:   Descriptor 0xb8000,              0xffff,  DA_DRW
LABEL_DESC_LDT:     Descriptor       0,        (LDTLen - 1),  DA_LDT

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
.set SelectorData,    (LABEL_DESC_DATA   - LABEL_GDT)
.set SelectorStack,   (LABEL_DESC_STACK  - LABEL_GDT)
.set SelectorVideo,   (LABEL_DESC_VIDEO  - LABEL_GDT)
.set SelectorLDT,     (LABEL_DESC_LDT    - LABEL_GDT) // points to a LDT

/* LDT segment */
LABEL_LDT:
LABEL_LDT_DESC_CODEA: Descriptor  0,  (CodeALen - 1), (DA_C + DA_32)

.set  LDTLen, (. - LABEL_LDT)
/* LDT Selector (TI flag set) */
.set  SelectorLDTCodeA, (LABEL_LDT_DESC_CODEA - LABEL_LDT + SA_TIL)

/* 32-bit global data segment */
LABEL_DATA:
PMMessage:    .ascii  "Welcome to protect mode!\0"
LDTMessage:   .ascii  "You jump into a LDT segment!\0"
.set  OffsetPMMessage,  (PMMessage  - LABEL_DATA)
.set  OffsetLDTMessage, (LDTMessage - LABEL_DATA)
.set  DataLen,          (.          - LABEL_DATA)

/* 32-bit global stack segment */
LABEL_STACK:
.space  512, 0
.set    TopOfStack, (. - LABEL_STACK - 1)

/* start */
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
  InitDesc LABEL_SEG_CODE32, LABEL_DESC_CODE32
  /* init data code segment descriptor */
  InitDesc LABEL_DATA, LABEL_DESC_DATA
  /* init stack code segment descriptor */
  InitDesc LABEL_STACK, LABEL_DESC_STACK
  /* init LDT code segment descriptor */
  InitDesc LABEL_LDT, LABEL_DESC_LDT
  /* init code A descriptor in !LDT! */
  InitDesc LABEL_CODEA, LABEL_LDT_DESC_CODEA

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

/* 32-bit code segment for LDT */
LABEL_CODEA:
.code32
  mov   $(SelectorVideo), %ax
  mov   %ax, %gs

  movb  $0xc, %ah
  xor   %esi, %esi
  xor   %edi, %edi
  movl  $(OffsetLDTMessage), %esi
  movl  $((80 * 12 + 0) * 2), %edi // 12 - next line
  cld   // clear DF flag

CODEA.1:
  lodsb
  test  %al, %al  // check if %al==0, 0 means string over
  jz    CODEA.2
  mov   %ax, %gs:(%edi)
  add   $2, %edi  // because we write 2byte each time
  jmp   CODEA.1
CODEA.2:
  jmp   .
.set  CodeALen, (. - LABEL_CODEA)

/* 32-bit code segment for GDT */
LABEL_SEG_CODE32:
  mov   $(SelectorData), %ax
  mov   %ax, %ds
  mov   $(SelectorStack), %ax
  mov   %ax, %ss
  mov   $(SelectorVideo), %ax
  mov   %ax, %gs

  mov   $(TopOfStack), %esp

  movb  $0xc, %ah
  xor   %esi, %esi
  xor   %edi, %edi
  movl  $(OffsetPMMessage), %esi
  movl  $((80 * 10 + 0) * 2), %edi
  cld

/* display string from %esi to %edi */
CODE32.1:
  lodsb
  test  %al, %al  // check if %al==0, 0 means string over
  jz    CODE32.2
  mov   %ax, %gs:(%edi)
  add   $2, %edi  // because we write 2byte each time
  jmp   CODE32.1
CODE32.2:
  mov   $(SelectorLDT), %ax
  lldt  %ax
  ljmp  $(SelectorLDTCodeA), $0

/* get length of 32-bit segment code */
.set  SegCode32Len, . - LABEL_SEG_CODE32
