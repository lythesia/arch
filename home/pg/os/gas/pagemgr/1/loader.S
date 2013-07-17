#include "pm.h"

.set PageDirBase, 0x200000 /* 2MB, base address of page directory */
.set PageTblBase, 0x201000 /* 2MB+4KB, base address of page table */

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
/* for paging */
LABEL_DESC_PAGEDIR: Descriptor PageDirBase,            4095,  DA_DRW
LABEL_DESC_PAGETBL: Descriptor PageTblBase,        4096*8-1,  DA_DRW // 32M we only need 8 page-table, so limit of page-table is 4k*8-1
/* Gates Descriptor */
LABEL_CG_TEST:  Gate  SelectorCodeCG, 0,  0,  (DA_386CGATE + DA_DPL3) // NOT DA_DPL0 because call gate need CPL(3)<=DPL

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
.set SelectorPageDir, (LABEL_DESC_PAGEDIR- LABEL_GDT)
.set SelectorPageTbl, (LABEL_DESC_PAGETBL- LABEL_GDT)

/* LDT segment */
LABEL_LDT:
LABEL_LDT_DESC_CODEA: Descriptor  0,  (CodeALen - 1), (DA_C + DA_32)

.set  LDTLen, (. - LABEL_LDT)
/* LDT Selector (TI flag set) */
.set  SelectorLDTCodeA, (LABEL_LDT_DESC_CODEA - LABEL_LDT + SA_TIL)

/* 32-bit global data segment */
LABEL_DATA:
/* _xx for real mode, none for protect mode */
_PMMessage:     .ascii  "Welcome to protect mode!\0"
_LDTMessage:    .ascii  "You jump into a LDT segment!\0"
_ARDSTitle:     .ascii  "BaseAddrL BaseAddrH LengthLo  LengthHi  Type\n\0"
_RAMSizeMes:    .ascii  "RAM Size:\0"
_LFMes:         .ascii  "\n\0" // line feed
_AMECount:      .4byte  0      // address map entry counter
_CursorPos:     .4byte  (80*2+0)*2
_MemSize:       .4byte  0
_ARDStruct:
  _BaseAddrLow: .4byte  0
  _BaseAddrHigh:.4byte  0
  _LengthLow:   .4byte  0
  _LengthHigh:  .4byte  0
  _Type:        .4byte  0
_AddrMapBuf:  .space 256, 0 // it is a attempt value, cover 12 times of ARDStruct(in actual we uses 6 ARDStruct)

.set  PMMessage,  (_PMMessage  - LABEL_DATA)
.set  LDTMessage, (_LDTMessage - LABEL_DATA)
.set  ARDSTitle,  (_ARDSTitle  - LABEL_DATA)
.set  RAMSizeMes, (_RAMSizeMes - LABEL_DATA)
.set  LFMes,      (_LFMes      - LABEL_DATA)
.set  AMECount,   (_AMECount   - LABEL_DATA)
.set  CursorPos,  (_CursorPos  - LABEL_DATA)
.set  MemSize,    (_MemSize    - LABEL_DATA)
.set  ARDStruct,  (_ARDStruct  - LABEL_DATA)
  .set  BaseAddrLow,  (_BaseAddrLow  - LABEL_DATA)
  .set  BaseAddrHigh, (_BaseAddrHigh - LABEL_DATA)
  .set  LengthLow,    (_LengthLow    - LABEL_DATA)
  .set  LengthHigh,   (_LengthHigh   - LABEL_DATA)
  .set  Type,         (_Type         - LABEL_DATA)
.set  AddrMapBuf, (_AddrMapBuf - LABEL_DATA)
.set  DataLen,    (.           - LABEL_DATA)

/* 32-bit global stack segment */
.align 4
LABEL_STACK:
.space  512, 0
.set    TopOfStack, (. - LABEL_STACK - 1)

/* 32-bit ring 3 stack segment */
LABEL_STACKR3:
.space  512, 0
.set    TopOfStackR3, (. - LABEL_STACKR3 - 1)

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

  /* Get System Address Map */
  xor   %ebx, %ebx      // 1st-time must be 0
  mov   $(_AddrMapBuf), %di
BEGIN.loop:
  mov   $0xe820, %eax       // function code of int15h
  mov   $20, %ecx           // buffer size
  mov   $0x534d4150, %edx   // signature, ascii of 'SMAP'
  int   $0x15
  jc    BEGIN.getAMfail
  add   $20, %di            // inc buffer ptr
  incl  (_AMECount)
  cmp   $0, %ebx            // check if end of Address Map
  jne   BEGIN.loop
  jmp   BEGIN.getAMok
BEGIN.getAMfail:
  movl  $0, (_AMECount)
BEGIN.getAMok:
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
  mov   %cr0, %eax
  or    $1, %eax
  mov   %eax, %cr0

  /* mixed-size jump */
  ljmpl $SelectorCode32, $0

/* 32-bit code segment for LDT */
LABEL_CODEA:
.code32
  mov   $(SelectorVideo), %ax
  mov   %ax, %gs

  mov   $0xc, %ah
  xor   %esi, %esi
  xor   %edi, %edi
  mov   $(LDTMessage), %esi
  mov   $((80 * 12 + 0) * 2), %edi // 12 - next line
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
  mov   $(SelectorData), %ax
  mov   %ax, %es                /* this affect stosl(es:edi), i made a mistake at start*/
  mov   $(SelectorStack), %ax
  mov   %ax, %ss
  mov   $(SelectorVideo), %ax
  mov   %ax, %gs

  mov   $(TopOfStack), %esp

  /* display addr range descriptor struct title */
  push  $(ARDSTitle)
  call  DispStr
  add   $4, %esp
  call  DispAddrMap
  call  SetupPaging   

  push  $(PMMessage)
  call  DispStr
  add   $4, %esp

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

SetupPaging:
  /* get usable PDE number */
  xor   %edx, %edx
  mov   (MemSize), %eax
  mov   $0x400000, %ebx   // page table size = 1024*1024*4 = 4M
  div   %ebx
  mov   %eax, %ecx
  test  %edx, %edx
  jz    SP.no_rem
  inc   %ecx
SP.no_rem:
  push  %ecx              // # of PDE = ceil(Memsize/4M)

  /* init page table directories, %ecx in total */
  mov   $(SelectorPageDir), %ax
  mov   %ax, %es
  xor   %edi, %edi
  xor   %eax, %eax
  mov   $(PageTblBase | PG_P | PG_USU | PG_RWW), %eax
SP.1:
  stosl               // store %eax to %es:%edi
  add   $4096, %eax   // because of direct mapping, we just add 4096 sequently(4K-align!)
                      // so dir-table like:
                      // |    ....    | attrs |
                      // | base + 0x2 | attrs |
                      // | base + 0x1 | attrs |
                      // | base + 0x0 | attrs |
  loop  SP.1

  /* init page tables, %ecx*1024 in total */
  mov   $(SelectorPageTbl), %ax
  mov   %ax, %es
  pop   %eax
  shl   $10, %eax     // 1024*%ecx
  mov   %eax, %ecx
  xor   %edi, %edi
  xor   %eax, %eax
  mov   $(PG_P | PG_USU | PG_RWW), %eax
SP.2:
  stosl
  add   $4096, %eax   // similar as above, address page_base_addr 4K-align
  loop  SP.2

  mov   $(PageDirBase), %eax
  mov   %eax, %cr3    // store base of page table dir in cr3(基址寄存器)
  mov   %cr0, %eax
  or    $0x80000000, %eax
  mov   %eax, %cr0    // enable paging bit in cr0
  ret

/* display system address map */
DispAddrMap:
  push  %esi
  push  %edi
  push  %ecx

  mov   $(AddrMapBuf), %esi //  int* p = AddrMapBuf;
  mov   (AMECount), %ecx    //  for(int i=0; i<AMECount; i++) {
DMS.loop:
  mov   $5, %edx            //    int j = 5;
  mov   $(ARDStruct), %edi  //    int* q = (int*)ARDStruct;
DMS.1:                      //    do {
  pushl (%esi)              //
  call  DispInt             //      printf("%xh", *p);  // *p ok, %eax ok
  pop   %eax
  stosl                     //      *q++ = *p;
  add   $4, %esi            //      p++;
  dec   %edx                //      j--;
  cmp   $0, %edx            //
  jnz   DMS.1               //    } while(j != 0);
  call  DispLF              //    printf("\n");
  cmpl  $1, (Type)          //    if(Type == AddressRangeMemory) {
  jne   DMS.2               //
  mov   (BaseAddrLow), %eax //      if(ARDStruct.BaseAddrLow
  add   (LengthLow), %eax   //         + ARDStruct.LengthLow
  cmp   (MemSize), %eax     //         > MemSize) {
  jb    DMS.2               //        
  mov   %eax, (MemSize)     //        MemSize = BaseAddrLow + LengthLow;
                            //      }
DMS.2:                      //    } // if %eax < MemSize
  //call  DispLF
  loop  DMS.loop            //  }

  call  DispLF              //  printf("\n");
  push  $(RAMSizeMes)       //
  call  DispStr             //  printf("%s", RAMSizeMes);
  add   $4, %esp

  pushl (MemSize)
  call  DispInt             //  printf("%xh", MemSize);
  add   $4, %esp
  call  DispLF              //  printf("\n");

  pop   %ecx
  pop   %edi
  pop   %esi
  ret
#include "lib.h"
/* get length of 32-bit segment code */
.set  SegCode32Len, . - LABEL_SEG_CODE32

/* 32-bit code segment for call gate destination segment */
LABEL_SEG_CODECG:
  mov   $(SelectorVideo), %ax
  mov   %ax, %gs

  mov   $((80 * 12 + 0) * 2), %edi  /* line 12, column 0 */
  mov   $0xc, %ah               /* 0000: Black Back 1100: Red Front */
  mov   $'C', %al               /* Print a 'C' */
  mov   %ax, %gs:(%edi)
  lret
/* Get the length of 32-bit call gate destination segment code. */
.set  SegCodeCGLen, . - LABEL_SEG_CODECG

/* 32-bit code segment for running in ring 3 */
LABEL_SEG_CODER3:
  mov   $(SelectorVideo), %ax
  mov   %ax, %gs

  mov   $((80 * 12 + 1) * 2), %edi  /* line 12, column 1 */
  mov   $0xc, %ah
  mov   $'3', %al
  mov   %ax, %gs:(%edi)
  
  lcall $(SelectorCGTest), $0       /* call CODECG through call gate(ring3 -> ring0) */
  jmp   .
/* get length ... */
.set  SegCodeR3Len, . - LABEL_SEG_CODER3

