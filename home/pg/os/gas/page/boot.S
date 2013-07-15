.code16         // 16-bit mode
.set  BaseOfStack,    0x7c00  // stack base address
.set  BaseOfLoader,   0x9000  // section loading address of "loader.bin"
.set  OffsetOfLoader, 0x0100  // loading address of "loader.bin"
.set  RootDirSectors, 14      // root directory sector count
.set  SecNoOfRootDir, 19      // 1st sector of root directory
.set  SecNoOfFAT1,    1       // 1st sector of FAT1
.set  DeltaSecNo,     17      // BPB_(ResvdSecCnt + NumFATs*FATSz) - 2

.text
/* Floppy header of FAT12 */
  jmp   LABEL_START // Start of boot
  nop               // nop required for `jmp`(?)
BS_OEMName:         .ascii  "Lythesia"    // 8 bytes
BPB_BytesPerSec:    .2byte  512           // byte/sector
BPB_SecPerCluster:  .byte   1             // sector/cluster
BPB_ResvdSecCnt:    .2byte  1             // reserved sector count
BPB_NumFATs:        .byte   2             // number of FATs
BPB_RootEntCnt:     .2byte  224           // root entry count
BPB_TotSec16:       .2byte  2880          // total sector number
BPB_Media:          .byte   0xf0          // device type
BPB_FATSz16:        .2byte  9             // FAT size(in sectors)
BPB_SecPerTrk:      .2byte  18            // sector/track
BPB_NumHeads:       .2byte  2             // number of magnetic heads
BPB_HiddSec:        .4byte  0             // number of hidden sectors
BPB_TotSec32:       .4byte  0             // if `BPB_TotSec16 == 0`, this works
BS_DrvNum:          .byte   0             // driver number of interrupt-13(0 for floppy)
BS_Reserved1:       .byte   0             // reserved
BS_BootSig:         .byte   0x29          // boot signal(indicate follow 3 fields workable)
BS_VolID:           .4byte  0             // volume ID 
BS_VolLab:          .ascii  "NaiveOS 0.1" // volume label, 11 bytes
BS_FileSysType:     .ascii  "FAT12   "    // file system, 8 bytes, whitespace(20h) padding

/* Init regs */
LABEL_START:
  mov   %cs, %ax
  mov   %ax, %ds
  mov   %ax, %es
  mov   %ax, %ss
  mov   $BaseOfStack, %sp

  /* clear screen */
  mov   $0x0600, %ax
  mov   $0x0700, %bx
  mov   $0, %cx
  mov   $0x184f, %dx
  int   $0x10

  /* display "Booting**" */
  mov   $0, %dh
  call  DispStr     // display string[0]

/* ==== Search "loader.bin" ==== */
  /* reset floppy */
  xor   %ah, %ah
  xor   %dl, %dl
  int   $0x13

  /* find "loader.bin" in root directory of driver 0 (floppy) */
  movw  $SecNoOfRootDir, (wSectorNo)

/* Read root dir sector to memory */
LABEL_SEARCH_IN_ROOT_DIR_BEGIN:
  cmpw  $0, (wRootDirSizeForLoop) // if searching in root dir
  jz    LABEL_NO_LOADERBIN        // test found
  decw  (wRootDirSizeForLoop)
  mov   $BaseOfLoader, %ax
  mov   %ax, %es                  // base(%es):
  mov   $OffsetOfLoader, %bx      // :ofs(%bx)
  mov   (wSectorNo), %ax
  mov   $1, %cl
  call  ReadSector                // read 1 sector to %es:%bx
  mov   $LoaderFileName, %si      // %ds:%si = "loader bin"
  mov   $OffsetOfLoader, %di      // BaseOfLoader<<4+100
  cld
  mov   $0x10, %dx                // 512/32 = 0x10, for control read entries

/* Search for "loader bin", FAT12 save filename in 12 bytes = 8-byte name + 3-byte suffix,
 * last byte for '\20', less than 8 bytes using '\20' padding.
 * e.g: "loader bin"(4f4c 4441 5245 2020 4942 294e) */
LABEL_SEARCH_FOR_LOADERBIN:
  cmp   $0, %dx
  jz    LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR
  dec   %dx
  mov   $11, %cx        // 11 bytes read

LABEL_CMP_FILENAME:
  cmp   $0, %cx
  jz    LABEL_FILENAME_FOUND
  dec   %cx
  lodsb                 // read 1 byte from %ds:%si to %al
  cmp   %es:(%di), %al  // cmp by byte (%es:(%di) -- start of filename )
                        // because offset 0 of a directory entry is the filename
  jz    LABEL_GO_ON
  jmp   LABEL_DIFFERENT

LABEL_GO_ON:
  inc   %di
  jmp   LABEL_CMP_FILENAME // continue compare next char..

LABEL_DIFFERENT:
  and   $0xffe0, %di          // go to head of this entry(0xfff0 seems ok too ?)
                              // because entry always @ 0x100+0x20*k, so 0xffe0 surely ok
  add   $0x20, %di            // next entry
  mov   $LoaderFileName, %si  // reload "loader bin" string
  jmp   LABEL_SEARCH_FOR_LOADERBIN

LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR:
  addw  $1, (wSectorNo)
  jmp   LABEL_SEARCH_IN_ROOT_DIR_BEGIN

/* Not found "loader.bin" in root dir */
LABEL_NO_LOADERBIN:
  mov   $2, %dh
  call  DispStr               // display string[2]
  jmp   .

/* Found */
LABEL_FILENAME_FOUND:
  mov   $RootDirSectors, %ax
  and   $0xffe0, %di
  add   $0x1a, %di            // 1st cluster of file
  mov   %es:(%di), %cx
  push  %cx                   // save index
  /* true sec_num = clus_num + root_dir_secs + 17*/
  add   %ax, %cx              // add root_dir_secs
  add   $DeltaSecNo, %cx      // add 17
  mov   $BaseOfLoader, %ax
  mov   %ax, %es
  mov   $OffsetOfLoader, %bx
  mov   %cx, %ax              // now %ax = true_sec
/* ==== END search ==== */ 

/* Load "loader.bin" sector to memory */
LABEL_GOON_LOADING_FILE:
  push  %ax
  push  %bx
  mov   $0x0e, %ah
  mov   $'.', %al   // char to print
  mov   $0x0f, %bl
  int   $0x10
  pop   %bx
  pop   %ax

  mov   $1, %cl
  call  ReadSector
  pop   %ax
  call  GetFATEntry
  cmp   $0x0fff, %ax              // end
  jz    LABEL_FILE_LOADED
  push  %ax
  mov   $RootDirSectors, %dx
  add   %dx, %ax
  add   $DeltaSecNo, %ax
  add   (BPB_BytesPerSec), %bx    // skip readed 512 bytes
  jmp   LABEL_GOON_LOADING_FILE

LABEL_FILE_LOADED:
  mov   $1, %dh
  call  DispStr     // display string[1]

/* ==== Jump to "loader.bin" start address ==== */
  jmp   $BaseOfLoader, $OffsetOfLoader

/*------------------------.
| Variable & String table |
`-----------------------*/
wRootDirSizeForLoop:  .2byte  RootDirSectors
wSectorNo:            .2byte  0               // sector # to read
bOdd:                 .byte   0               // odd or even

LoaderFileName:       .asciz  "LOADER  BIN"   // !! 11 bytes !!
.set  MessageLength, 9
BootMessage:          .ascii  "Booting**"     // index 0
Message1:             .ascii  "Loaded in"     // index 1
Message2:             .ascii  "No LOADER"     // index 2

/*---------------------------------.
| DispStr                          |
|   display a string, index in %dh |
`--------------------------------*/
DispStr:
  mov   $MessageLength, %ax
  mul   %dh
  add   $BootMessage, %ax
  mov   %ax, %bp            // string address
  mov   %ds, %ax
  mov   %ax, %es
  mov   $MessageLength, %cx
  mov   $0x1301, %ax
  mov   $0x07, %bx
  mov   $0, %dl
  int   $0x10
  ret

/*--------------------------------------------------------------.
| ReadSector                                                    |
|   read %cl sectors from %ax sector(floppy) to %es:%bx(memory) |
|   x -- sector #:                                              |
|   y = x/BPB_SecPerTrk                                         |
|     y/BPB_NumHeads(aka y>>1) -- cylinder #                    |
|     y&1 -- magnetic header                                    |
|   z = x%BPB_SecPerTrk                                         |
|     z+1 -- start sector #                                     |
`-------------------------------------------------------------*/
/* ax dx not saved ? */
ReadSector:
  push  %ebp
  mov   %esp, %ebp
  sub   $2, %esp            // reserved for saving %cl
  mov   %cl, -2(%ebp)       // now %cl saved
  push  %bx                 // save %bx
  mov   (BPB_SecPerTrk), %bl// divider
  div   %bl                 // `y` in %al, `z` in %ah
  inc   %ah                 // `z++`
  mov   %ah, %cl            // %cl = start sector #
  mov   %al, %dh            // %dh = `y`
  shr   $1, %al             // `y`/BPB_NumHeads
  mov   %al, %ch            // %ch = cylinder #
  and   $1, %dh             // %dh = magnetic header
  pop   %bx                 // restore %bx
  mov   (BS_DrvNum), %dl
  /* now %ch -- cylinder #
   *     %cl -- start sector # 
   *     %dh -- magnetic header 
   *     %dl -- driver #
   * why these regs? lookup BIOS 13h table ... */
GoOnReading:
  mov   $2, %ah
  mov   -2(%ebp), %al       // read %al(aka moto-%cl) sectors
  int   $0x13
  jc    GoOnReading         // if CF == 1, mean read error, try reread
  add   $2, %esp
  pop   %ebp
  ret

/*------------------------------------------------.
| GetFATEntry                                     |
|   find %ax sector's index in FAT. result in %ax |
`-----------------------------------------------*/
/* In  -- # of sector(aka # of FAT12 entry)
 * Out -- FAT entry value
 * entrySz = 12-bit(3/2 byte), so entry_offset = sec_num * 3 / 2
 * in 2byte/read, need to judge if high/low 12-bit:
 * sec_num*3/2 =  offset ... 0 -- low 12-bit
 *                           1 -- high 12-bit
 */
GetFATEntry:
  push  %es
  push  %bx
  push  %ax
  mov   $BaseOfLoader, %ax
  sub   $0x0100, %ax
  mov   %ax, %es          // left 4k bytes for FAT
  pop   %ax
  mov   $3, %bx
  mul   %bx               // %dx:%ax = %ax*3
  mov   $2, %bx
  div   %bx               // %dx:%ax/2
  movb  %dl, (bOdd)       // remainder %dx -> bOdd

LABEL_EVEN:
  xor   %dx, %dx          // now %ax = offset of FATEntry in FAT
  mov   (BPB_BytesPerSec), %bx
  div   %bx               // %ax = sector_offset, %dx = byte_offset
  push  %dx
  mov   $0, %bx
  add   $SecNoOfFAT1, %ax // %ax = FATEntry's sector #
  mov   $2, %cl           // read 2 secs
  call  ReadSector
  pop   %dx
  add   %dx, %bx          // true byte_offset
  mov   %es:(%bx), %ax    // read by word(2 bytes)
  cmpb  $0, (bOdd)
  jz    LABEL_EVEN_2      // 0 for low 12-bit
  shr   $4, %ax

LABEL_EVEN_2:
  and   $0x0fff, %ax

LABEL_GET_FAT_ENTRY_OK:
  pop   %bx
  pop   %es
  ret

.org  510       // skip to address 0x510
.2byte  0xaa55  // write boot flag
