/* Display utils */
/* display %al in formate xx with CursorPos updated */
DispAL:
  push  %ecx
  push  %edx
  push  %edi
  mov   (CursorPos), %edi
  mov   $0xf, %ah
  mov   %al, %dl
  shr   $4, %al
  mov   $2, %ecx
DispAL.begin:
  and   $0xf, %al
  cmp   $9, %al
  ja    DispAL.1
  add   $'0', %al
  jmp   DispAL.2
DispAL.1:
  sub   $0xa, %al
  add   $'A', %al
DispAL.2:
  mov   %ax, %gs:(%edi)
  add   $2, %edi
  mov   %dl, %al
  loop  DispAL.begin
  mov   %edi, (CursorPos)
  pop   %edi
  pop   %edx
  pop   %ecx
  ret

DispInt:
  mov   4(%esp), %eax
  shr   $24, %eax
  call  DispAL
  mov   4(%esp), %eax
  shr   $16, %eax
  call  DispAL
  mov   4(%esp), %eax
  shr   $8, %eax
  call  DispAL
  mov   4(%esp), %eax
  call  DispAL
  mov   $0x7, %ah
  mov   $'h', %al
  push  %edi
  mov   (CursorPos), %edi
  mov   %ax, %gs:(%edi)
  add   $4, %edi          // 2+2(whitespace)
  mov   %edi, (CursorPos)
  pop   %edi
  ret

DispStr:
  push  %ebp              // cause here %esp will be used
  mov   %esp, %ebp
  push  %ebx
  push  %esi
  push  %edi
  mov   8(%ebp), %esi     // why +8 ? cause we have `push %ebp` at start, so str_ptr @ -4, eip @ -8, ebp @ -12, here -12+8 we get the str_ptr
  mov   (CursorPos), %edi
  mov   $0xf, %ah
DispStr.1:
  lodsb
  test  %al, %al
  jz    DispStr.2       // string over
  cmp   $0xa, %al       // check if '\n'
  jnz   DispStr.3
  push  %eax
  mov   %edi, %eax
  mov   $160, %bl
  div   %bl
  and   $0xff, %eax
  inc   %eax
  mov   $160, %bl
  mul   %bl
  mov   %eax, %edi
  pop   %eax
  jmp   DispStr.1
DispStr.3:              // normal char
  mov   %ax, %gs:(%edi)
  add   $2, %edi
  jmp   DispStr.1
DispStr.2:
  mov   %edi, (CursorPos)
  pop   %edi
  pop   %esi
  pop   %ebx
  pop   %ebp
  ret

DispLF:
  pushl $(LFMes)
  call  DispStr
  add   $4, %esp
  ret

/* copy from %ds:%esi to %es:%edi */
MemCpy:
  push  %ebp
  mov   %esp, %ebp

  push  %esi
  push  %edi
  push  %ecx

  mov   8(%ebp), %edi // destination
  mov   12(%ebp), %esi// source
  mov   16(%ebp), %ecx// counter
MemCpy.1:
  cmp   $0, %ecx
  jz    MemCpy.2
  mov   %ds:(%esi), %al
  inc   %esi
  mov   %al, %es:(%edi)
  inc   %edi
  dec   %ecx
  jmp   MemCpy.1
MemCpy.2:
  mov   8(%ebp), %eax // return value
  pop   %ecx
  pop   %edi
  pop   %esi
  mov   %ebp, %esp
  pop   %ebp
  ret
