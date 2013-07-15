.code16         # 16-bit mode
.text
  mov   %cs, %ax
  mov   %ax, %ds
  mov   %ax, %es
  call  DispStr 
  jmp   .       # forever loop
DispStr:
  mov   $BootMessage, %ax
  mov   %ax, %bp
  mov   $16, %cx
  mov   $0x1301, %ax
  mov   $0x00c, %bx
  mov   $0, %dl
  int   $0x10
  ret
BootMessage: .ascii "Hello, OS!"
.org 510        # fill 0 until address of "510" bytes position
.word 0xaa55    # last 2 bytes of total 512B image
