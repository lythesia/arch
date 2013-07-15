#include "pm.h"
.code16
.text
  jmp   LABEL_BEGIN // jump over data section

/* Global Descriptor Table */
LABEL_GDT:          Descriptor       0,                   0,  0
LABEL_DESC_CODE32:  Descriptor       0,  (SegCode32Len - 1),  (DA_C + DA_32)
LABEL_DESC_DATA:    Descriptor       0,       (DataLen - 1),  DA_DRW
LABEL_DESC_STACK:   Descriptor       0,          TopOfStack,  (DA_DRWA + DA_32)
LABEL_DESC_VIDEO:   Descriptor 0xb8000,              0xffff,  (DA_DRW + DA_DPL3)
LABEL_DESC_LDT:     Descriptor       0,        (LDTLen - 1),  DA_LDT
LABEL_DESC_CODECG:  Descriptor       0,  (SegCodeCGLen - 1),  (DA_C + DA_32)
/* for ring 3 */
LABEL_DESC_CODER3:  Descriptor       0,  (SegCodeR3Len - 1),  (DA_C + DA_32 + DA_DPL3)
LABEL_DESC_STACKR3: Descriptor       0,        TopOfStackR3,  (DA_DRWA + DA_32 + DA_DPL3)
LABEL_DESC_TSS:     Descriptor       0,        (TSSLen - 1),  DA_386TSS
/* Gates Descriptor */
LABEL_CG_TEST:  Gate  SelectorCodeCG, 0,  0,  (DA_386CGATE + DA_DPL3) // NOT DA_DPL0 because call gate need CPL(3)<=DPL
// below is WRONG! because 'DA_386CGate' is NOT 'DA_386CGATE! However GAS not give error
// detail about this except only "invalid operands (*und* and *abs* sections) for xxx"!
//LABEL_CG_TEST:      Gate    SelectorCodeCG, 0, 0, (DA_386CGate + DA_DPL0)

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
.set SelectorCodeCG,  (LABEL_DESC_CODECG - LABEL_GDT)
.set SelectorCGTest,  (LABEL_CG_TEST     - LABEL_GDT)
.set SelectorCodeR3,  (LABEL_DESC_CODER3 - LABEL_GDT + SA_RPL3)
.set SelectorStackR3, (LABEL_DESC_STACKR3- LABEL_GDT + SA_RPL3)
.set SelectorTSS,     (LABEL_DESC_TSS    - LABEL_GDT)

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
.align 4
LABEL_STACK:
.space  512, 0
.set    TopOfStack, (. - LABEL_STACK)

/* 32-bit ring 3 stack segment */
LABEL_STACKR3:
.space  512, 0
.set    TopOfStackR3, (. - LABEL_STACKR3)

/* TSS struct */
LABEL_TSS:
  .4byte  0             // back link
  .4byte  TopOfStack    // ESP0
  .4byte  SelectorStack // SS0
  .4byte  0             // ESP1
  .4byte  0             // SS1
  .4byte  0             // ESP2
  .4byte  0             // SS2
  .4byte  0             // CR3
  .4byte  0             // EIP
  .4byte  0             // EFLAGS
  .4byte  0             // EAX
  .4byte  0             // ECX
  .4byte  0             // EDX
  .4byte  0             // EBX
  .4byte  0             // ESP
  .4byte  0             // EBP
  .4byte  0             // ESI
  .4byte  0             // EDI
  .4byte  0             // ES
  .4byte  0             // CS
  .4byte  0             // SS
  .4byte  0             // DS
  .4byte  0             // FS
  .4byte  0             // GS
  .4byte  0             // LDT Segment Selector
  .2byte  0             // Trap Flag: 1-bit
  .2byte  (. - LABEL_TSS + 2) // I/O Map Base Address
  .byte   0xff          // End
.set  TSSLen, (. - LABEL_TSS)

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
  /* Initialize call gate dest code segment descriptor. */
  InitDesc LABEL_SEG_CODECG, LABEL_DESC_CODECG
  /* Init R3 stuffs */
  InitDesc LABEL_STACKR3, LABEL_DESC_STACKR3
  InitDesc LABEL_SEG_CODER3, LABEL_DESC_CODER3
  /* Init TSS segment descriptor */
  InitDesc LABEL_TSS, LABEL_DESC_TSS

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
  mov   $(SelectorTSS), %ax
  ltr   %ax   /* load TSS to TR register */

  /* fake call procedure */
  pushl $(SelectorStackR3)  // == push SS
  pushl $(TopOfStackR3)     // == push ESP
  pushl $(SelectorCodeR3)   // == push CS
  pushl $0                  // == push EIP
  lret                      /* lret to LABEL_SEG_CODER3 and execute */

CODE32.3:
  mov   $(SelectorLDT), %ax
  lldt  %ax
  ljmp  $(SelectorLDTCodeA), $0
/* get length of 32-bit segment code */
.set  SegCode32Len, . - LABEL_SEG_CODE32

/* 32-bit code segment for call gate destination segment */
LABEL_SEG_CODECG:
  mov   $(SelectorVideo), %ax
  mov   %ax, %gs

  movl  $((80 * 11 + 0) * 2), %edi  /* line 11, column 0 */
  movb  $0xc, %ah               /* 0000: Black Back 1100: Red Front */
  movb  $'C', %al               /* Print a 'C' */
  mov   %ax, %gs:(%edi)
  lret
/* Get the length of 32-bit call gate destination segment code. */
.set  SegCodeCGLen, . - LABEL_SEG_CODECG

/* 32-bit code segment for running in ring 3 */
LABEL_SEG_CODER3:
  mov   $(SelectorVideo), %ax
  mov   %ax, %gs

  movl  $((80 * 11 + 1) * 2), %edi  /* line 11, column 1 */
  movb  $0xc, %ah
  movb  $'3', %al
  mov   %ax, %gs:(%edi)
  
  lcall $(SelectorCGTest), $0       /* call CODECG through call gate(ring3 -> ring0) */
  jmp   .
/* get length ... */
.set  SegCodeR3Len, . - LABEL_SEG_CODER3
