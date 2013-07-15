/* GDT Descriptor Attributes */
.set  DA_32,  0x4000  // 32-bit segment

/* privilege level */
.set  DA_DPL0, 0x00
.set  DA_DPL1, 0x20
.set  DA_DPL2, 0x40
.set  DA_DPL3, 0x60

/* GDT Code- and Data-Segment Type */
.set  DA_DR,   0x90
.set  DA_DRW,  0x92
.set  DA_DRWA, 0x93
.set  DA_C,    0x98
.set  DA_CR,   0x9a
.set  DA_CCO,  0x9c
.set  DA_CCOR, 0x9e

/* GDT System-Segment and Gate-Descriptor Type */
.set  DA_LDT,      0x82
.set  DA_TaskGate, 0x85
.set  DA_386TSS,   0x89
.set  DA_386CGATE, 0x8c
.set  DA_386IGATE, 0x8e
.set  DA_386TGATE, 0x8f

/* Selector Attributes */
.set  SA_PRL0, 0
.set  SA_PRL1, 1
.set  SA_PRL2, 2
.set  SA_PRL3, 3
.set  SA_TIG,  0
.set  SA_TIL,  4

/* Segment Descriptor struct
 * Usage: Descriptor Base, Limit, Attr
 *  Base:  4 byte
 *  Limit: 4 byte
 *  Attr:  2 byte
 */
.macro Descriptor Base, Limit, Attr // bit define: low -> high
  .2byte  \Limit & 0xffff
  .2byte  \Base & 0xffff
  .byte   (\Base >> 16) & 0xff
  .2byte  ((\Limit >> 8) & 0xf00) | (\Attr & 0xf0ff)
  .byte   (\Base >> 24) & 0xff
.endm
