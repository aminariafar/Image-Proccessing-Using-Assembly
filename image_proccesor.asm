    sys_read     equ     0
    sys_write    equ     1
    sys_open     equ     2
    sys_close    equ     3
    
    sys_lseek    equ     8
    sys_create   equ     85
    sys_unlink   equ     87
      

    sys_mkdir       equ 83
    sys_makenewdir  equ 0q777


    sys_mmap     equ     9
    sys_mumap    equ     11
    sys_brk      equ     12
    
     
    sys_exit     equ     60
    
    stdin        equ     0
    stdout       equ     1
    stderr       equ     3

 
	PROT_NONE	  equ   0x0
    PROT_READ     equ   0x1
    PROT_WRITE    equ   0x2
    MAP_PRIVATE   equ   0x2
    MAP_ANONYMOUS equ   0x20
    
    ;access mode
    O_DIRECTORY equ     0q0200000
    O_RDONLY    equ     0q000000
    O_WRONLY    equ     0q000001
    O_RDWR      equ     0q000002
    O_CREAT     equ     0q000100
    O_APPEND    equ     0q002000


    BEG_FILE_POS    equ     0
    CURR_POS        equ     1
    END_FILE_POS    equ     2
    
; create permission mode
    sys_IRUSR     equ     0q400      ; user read permission
    sys_IWUSR     equ     0q200      ; user write permission

    NL            equ   0xA
    Space         equ   0x20


section .data
   A: dq 0
   opt1: db 'Read matrix from .txt file(1)', 0
   opt2: db 'Reshaping(2)', 0
   opt3: db 'Resizing(3)', 0
   opt4: db 'Convolution Filters(4)', 0
   opt5: db 'Pooling(5)', 0
   opt6: db 'Noise(6)', 0
   opt7: db 'Save output in .txt file and Exit(-1)', 0
   invalid_opt: db 'Invalid input. Try again!', 0
   operation_done: db 'Operation successfully done! Choose your next operation.', 0
   output_saved: db 'The final output is saved in .txt file.', 0

   file_name: db 'unnamed.txt', 0
   file_open_error: db 'Error opening file', 10, 0
   read_error: db 'Error reading file', 10, 0
   len2read: dq 200000
   len2write: dq 0
   output_name: db 'output.txt', 0

   reshape_msg: db 'Enter the new number of dimensions:', 0
   invalid_shape: db 'The given shape was invalid!', 0

   resize_msg: db 'Enter the new size:', 0

   pool_msg: db 'Enter pooling mode:', 0
   pool1: db 'Max pool(1)', 0
   pool2: db 'Mean pool(2)', 0
   pool_size: db 'Enter pool size:', 0

   convol_msg: db 'Choose kernel filter:', 0
   convol1: db 'Sharpening kernel(1)', 0
   convol2: db 'Emboss kernel(2)', 0
   
   row: dq 0
   col: dq 0
   dim: dq 3
   grey_flag: dq 0

section .bss
   arr: resq 9
   buffer: resb 200000 ; Buffer to hold file contents
   fd: resd 1  ; File descriptor for the opened file
   tmp: resq 100000
   kernel: resq 9
   matrix: resq 100000

section .text
	global _start
;----------------------------------------------------
newLine:
   push   rax
   mov    rax, NL
   call   putc
   pop    rax
   ret
;---------------------------------------------------------
OneSpace:
   push   rax
   mov    rax, Space
   call   putc
   pop    rax
   ret
;---------------------------------------------------------
putc:	

   push   rcx
   push   rdx
   push   rsi
   push   rdi 
   push   r11 

   push   ax
   mov    rsi, rsp    ; points to our char
   mov    rdx, 1      ; how many characters to print
   mov    rax, sys_write
   mov    rdi, stdout 
   syscall
   pop    ax

   pop    r11
   pop    rdi
   pop    rsi
   pop    rdx
   pop    rcx
   ret
;---------------------------------------------------------
writeNum:
   push   rax
   push   rbx
   push   rcx
   push   rdx

   sub    rdx, rdx
   mov    rbx, 10 
   sub    rcx, rcx
   cmp    rax, 0
   jge    wAgain
   push   rax 
   mov    al, '-'
   call   putc
   pop    rax
   neg    rax  

wAgain:
   cmp    rax, 9	
   jle    cEnd
   div    rbx
   push   rdx
   inc    rcx
   sub    rdx, rdx
   jmp    wAgain

cEnd:
   add    al, 0x30
   call   putc
   dec    rcx
   jl     wEnd
   pop    rax
   jmp    cEnd
wEnd:
   pop    rdx
   pop    rcx
   pop    rbx
   pop    rax
   ret

;---------------------------------------------------------
getc:
   push   rcx
   push   rdx
   push   rsi
   push   rdi 
   push   r11 

 
   sub    rsp, 1
   mov    rsi, rsp
   mov    rdx, 1
   mov    rax, sys_read
   mov    rdi, stdin
   syscall
   mov    al, [rsi]
   add    rsp, 1

   pop    r11
   pop    rdi
   pop    rsi
   pop    rdx
   pop    rcx

   ret
;---------------------------------------------------------

readNum:
   push   rcx
   push   rbx
   push   rdx

   mov    bl,0
   mov    rdx, 0
rAgain:
   xor    rax, rax
   call   getc
   cmp    al, '-'
   jne    sAgain
   mov    bl,1  
   jmp    rAgain
sAgain:
   cmp    al, NL
   je     rEnd
   cmp    al, ' ' ;Space
   je     rEnd
   sub    rax, 0x30
   imul   rdx, 10
   add    rdx,  rax
   xor    rax, rax
   call   getc
   jmp    sAgain
rEnd:
   mov    rax, rdx 
   cmp    bl, 0
   je     sEnd
   neg    rax 
sEnd:  
   pop    rdx
   pop    rbx
   pop    rcx
   ret

;-------------------------------------------
printString:
   push    rax
   push    rcx
   push    rsi
   push    rdx
   push    rdi

   mov     rdi, rsi
   call    GetStrlen
   mov     rax, sys_write  
   mov     rdi, stdout
   syscall 
   
   pop     rdi
   pop     rdx
   pop     rsi
   pop     rcx
   pop     rax
   ret
;-------------------------------------------

GetStrlen: ; rdi : zero terminated string start 
   push    rbx
   push    rcx
   push    rax  

   xor     rcx, rcx
   not     rcx
   xor     rax, rax
   cld
         repne   scasb
   not     rcx
   lea     rdx, [rcx -1]  ; length in rdx

   pop     rax
   pop     rcx
   pop     rbx
   ret

print_string: ; print str located at rsi
   mov rcx, 0
   print_str:
      cmp byte [rsi + rcx], 0
      jz print_out
      mov al, [rsi + rcx]
      call putc
      inc rcx
      jmp print_str
   
   print_out:
      ret
;-------------------------------------------

open_file:
   push rdi
   push rsi
   push rdx

   mov rax, 2          ; Syscall number for open()
   mov rdi, file_name   ; Filename
   mov rsi, 2          ; Flags: O_RDWR (read/write mode)
   mov rdx, 0666   ; Mode: 0666 (rw-rw-rw-)
   syscall
   mov [fd], rax    ; Store file descriptor

   pop rdx
   pop rsi
   pop rdi

   ret

open_file2:
   push rdi
   push rsi
   push rdx

   mov rax, 2          ; Syscall number for open()
   mov rdi, output_name  ; Filename
   mov rsi, 2          ; Flags: O_RDWR (read/write mode)
   mov rdx, 0666   ; Mode: 0666 (rw-rw-rw-)
   syscall
   mov [fd], rax    ; Store file descriptor

   pop rdx
   pop rsi
   pop rdi

   ret

close_file:

   push rdi
   push rcx
   push rbx
   push rax

   mov rdi, qword [fd]   ; File descriptor
   mov rax, 3              ; Syscall number for close (3 on x86_64)
   syscall                 ; Call syscall

   pop rax
   pop rbx
   pop rcx
   pop rdi

   ret

read_file:

   push rdi
   push rsi
   push rdx
   push rcx
   push rbx
   push rax

   mov rax, 0          ; Syscall number for read()
   mov rdi, [fd]    ; File descriptor
   lea rsi, [buffer]   ; Buffer address
   mov rdx, [len2read]     ; Number of bytes to read
   syscall

   pop rax
   pop rbx
   pop rcx
   pop rdx
   pop rsi
   pop rdi

   ret

read_txt:
   call open_file
   call read_file
   call close_file
   ret

write_file:

   push rdx
   push rcx
   push rbx
   push rax

   mov rax, 1          ; Syscall number for write()
   mov rdi, [fd]       ; File descriptor
   lea rsi, [buffer]   ; Buffer address
   mov rdx, [len2write]       ; Number of bytes to write (use rax as it holds the bytes read)
   syscall

   pop rax
   pop rbx
   pop rcx
   pop rdx

   ret

;-------------------------------------------
    
print_menu:
   mov rsi, opt1
   call printString
   call newLine
   mov rsi, opt2
   call printString
   call newLine
   mov rsi, opt3
   call printString
   call newLine
   mov rsi, opt4
   call printString
   call newLine
   mov rsi, opt5
   call printString
   call newLine
   mov rsi, opt6
   call printString
   call newLine
   mov rsi, opt7
   call printString
   call newLine

   call readNum
   ret

get_num:
    xor rax, rax
    xor rbx, rbx
    mov r8, 10
    mov bl, [buffer + rcx]
    sub bl, 48
    add rax, rbx
    inc rcx

    add_dig:
        cmp byte [buffer + rcx], Space
        je add_out
        cmp byte [buffer + rcx], NL
        je add_out

        mul r8
        xor rbx, rbx
        mov bl, [buffer + rcx]
        sub bl, 48
        add rax, rbx

        inc rcx
        jmp add_dig
    
    add_out:
    ret

txt_to_matrix:
    xor rcx, rcx
    xor r9, r9
    call get_num
    mov [row], rax
    inc rcx
    call get_num
    mov [col], rax
    inc rcx
    call get_num
    mov [dim], rax
    inc rcx
    call get_num
    mov [grey_flag], rax
    inc rcx

    mov rax, [row]
    mov r10, [col]
    mul r10
    mov r10, [dim]
    mul r10
    mov r10, rax

    get_nums:
        cmp r9, r10
        je get_out

        call get_num
        mov [matrix + r9*8], rax
        inc r9
        inc rcx
        jmp get_nums
    
    get_out:
        ret

reshape: ; remove from the last colors
    mov rsi, reshape_msg
    call print_string
    call readNum

    cmp rax, [dim]
    jg invalid

    cmp rax, [dim]
    je reshape_out

    mov r8, rax
    mov r9, r8 
    dec r9 ; new_dim - 1
    mov r10, 3

    xor rcx, rcx ; index for matrix
    xor r11, r11 ; index for tmp
    mov rax, [row]
    mov rbx, [col]
    mul rbx
    mov rbx, [dim]
    mul rbx
    mov rbx, rax

    to_tmp:
        cmp rcx, rbx
        je from_tmp

        xor rdx, rdx
        mov rax, rcx
        div r10
        cmp rdx, r8
        jge skip

        mov rax, [matrix + rcx*8]
        mov [tmp + r11*8], rax
        inc rcx
        inc r11
        jmp to_tmp

        skip:
            inc rcx
            jmp to_tmp
    
    from_tmp:
        xor rcx, rcx

        change_dim:
            cmp rcx, r11
            je reshape_out

            mov rax, [tmp + rcx*8]
            mov [matrix + rcx*8], rax

            inc rcx
            jmp change_dim

    invalid:
        mov rsi, invalid_shape
        call print_string
        ret
    
    reshape_out:
        mov [dim], r8
        ret

resize:
    mov rsi, resize_msg
    call print_string
    call readNum
    mov r8, rax ; new no. of rows
    call readNum
    mov r9, rax ; new no. of columns

    xor rdx, rdx
    mov rax, [row]
    div r8
    mov r10, rax ; x_scale
    xor rdx, rdx
    mov rax, [col]
    div r9
    mov r11, rax ; y_scale

    xor rcx, rcx
    mov rax, r8
    mul r9
    mov rbx, rax

    resize_to_tmp:
        cmp rcx, rbx
        je rest_resize

        call nni
        inc rcx
        jmp resize_to_tmp
    
    rest_resize:
        xor rcx, rcx
        mov rax, r8
        mul r9
        mov rbx, rax
        resize_from_tmp:
            cmp rcx, rbx
            je resize_out

            mov rax, [tmp + rcx*8]
            mov [matrix + rcx*8], rax

            inc rcx
            jmp resize_from_tmp

    resize_out:
        mov [row], r8
        mov [col], r9
        ret

nni:
    xor rdx, rdx
    mov rax, rcx
    div r9
    mov r12, rax ; i
    mov r13, rdx ; j

    mov rax, r12
    mul r10
    mov r14, rax ; i in org
    mov rax, r13
    mul r11
    mov r15, rax ; j in org

    xor rdx, rdx
    mov rax, r14
    mov rdx, [col]
    mul rdx
    add rax, r15 ; index in org

    mov r12, [matrix + rax*8]
    mov [tmp + rcx*8], r12

    ret

pooling:
   mov rsi, pool_msg
   call print_string
   call newLine
   mov rsi, pool1
   call print_string
   call newLine
   mov rsi, pool2
   call print_string
   call newLine

   call readNum
   mov r15, rax ; pool_mode

   mov rsi, pool_size
   call print_string
   call newLine
   call readNum
   mov r8, rax ; pool size

   cmp r15, 1
   je maxp

   cmp r15, 2
   je meanp

   ret_pool:
      mov rax, [row]
      xor rdx, rdx
      div r8
      mov [row], rax ; update row
      mov rax, [col]
      xor rdx, rdx
      div r8
      mov [col], rax
      ret
   
   meanp:
      call mean_pool
      jmp from_tmp_pool
   
   maxp:
      call max_pool
      jmp from_tmp_pool
   
   from_tmp_pool:
      xor rcx, rcx
      looop:
         cmp rcx, r15
         je ret_pool

         mov rax, [tmp + rcx*8]
         mov [matrix + rcx*8], rax
         inc rcx
         jmp looop

mean_pool:
   xor r15, r15 ; index for tmp
   xor r9, r9 ; i1

   loop1:
      cmp r9, [row]
      jge meanp_out

      xor r10, r10 ; j1
      loop2:
         cmp r10, [col]
         jge mep_l2_out

         xor rbx, rbx ; sum in rbx
         
         xor r11, r11 ; i2
         loop3:
            cmp r11, r8
            je compute_mean

            xor r12, r12 ; j2
            loop4:
               cmp r12, r8
               je mep_l4_out

               push r11
               push r12

               add r11, r9
               add r12, r10
               call compute_idx2

               pop r12
               pop r11

               add rbx, [matrix + rax*8]
               inc r12
               jmp loop4

               mep_l4_out:
                  inc r11
                  jmp loop3

            compute_mean:
               mov rax, r8
               mul r8
               mov rcx, rax
               mov rax, rbx
               xor rdx, rdx
               div rcx
               mov rbx, rax

               mov [tmp + r15*8], rbx
               inc r15
               add r10, r8
               jmp loop2
               

         mep_l2_out:
            add r9, r8
            jmp loop1
         
   meanp_out:
      ret

max_pool:
   xor r15, r15 ; index for tmp
   xor r9, r9 ; i1

   loop11:
      cmp r9, [row]
      jge maxp_out

      xor r10, r10 ; j1
      loop21:
         cmp r10, [col]
         jge mep_l2_out1

         xor rbx, rbx ; max in rbx
         
         xor r11, r11 ; i2
         loop31:
            cmp r11, r8
            je put_max

            xor r12, r12 ; j2
            loop41:
               cmp r12, r8
               je mep_l4_out1

               push r11
               push r12

               add r11, r9
               add r12, r10
               call compute_idx2

               pop r12
               pop r11
               
               cmp [matrix + rax*8], rbx
               jg update_max

               inc r12
               jmp loop41

               mep_l4_out1:
                  inc r11
                  jmp loop31

               update_max:
                  mov rbx, [matrix + rax*8]
                  inc r12
                  jmp loop41

            put_max:
               mov [tmp + r15*8], rbx
               inc r15
               add r10, r8
               jmp loop21
               
         mep_l2_out1:
            add r9, r8
            jmp loop11
         
   maxp_out:
      ret
    
compute_idx2:
   mov rax, r11

   push rbx
   mov rbx, [col]
   mul rbx
   pop rbx

   add rax, r12
   ret

compute_idx1:
   mov rax, r9
   
   push rbx
   mov rbx, [col]
   mul rbx
   pop rbx
   
   add rax, r10
   ret

compute_idx3:
   push r8
   mov r8, 3
   mov rax, r11
   mul r8
   add rax, r12
   pop r8
   ret

noise:
   mov rbx, 20 ; set % of salt and pepper to 5
   mov rax, [row]
   
   push rbx
   mov rbx, [col]
   mul rbx
   pop rbx
   
   xor rdx, rdx
   div rbx
   mov r8, rax ; no. of salt and pepper
   
   mov r11, [row] ; scaling factor
   mov r12, [col]

   xor rcx, rcx
   add_sp:
      cmp rcx, r8
      je noise_out

      rdrand rax
      xor rdx, rdx
      div r11
      mov r9, rdx ; random i

      rdrand rax
      xor rdx, rdx
      div r12
      mov r10, rdx ; random j

      call compute_idx1

      mov qword [matrix + rax*8], 0 ; salt

      rdrand rax
      xor rdx, rdx
      div r11
      mov r9, rdx

      rdrand rax
      xor rdx, rdx
      div r12
      mov r10, rdx

      call compute_idx1

      mov qword [matrix + rax*8], 255 ; pepper

      inc rcx
      jmp add_sp

   noise_out:
      ret

convol_filters:
   mov rsi, convol_msg
   call print_string
   call newLine
   mov rsi, convol1
   call print_string
   call newLine
   mov rsi, convol2
   call print_string
   call newLine

   call readNum
   cmp rax, 1
   je sharp
   cmp rax, 2
   je emboss

   rest:
      call convol2d
      ret

   sharp:
      mov qword [kernel + 0], 0
      mov qword [kernel + 1*8], -1
      mov qword [kernel + 2*8], 0
      mov qword [kernel + 3*8], -1
      mov qword [kernel + 4*8], 5
      mov qword [kernel + 5*8], -1
      mov qword [kernel + 6*8], 0
      mov qword [kernel + 7*8], -1
      mov qword [kernel + 8*8], 0
      jmp rest

   emboss:
      mov qword [kernel + 0], -2
      mov qword [kernel + 1*8], -1
      mov qword [kernel + 2*8], 0
      mov qword [kernel + 3*8], -1
      mov qword [kernel + 4*8], 1
      mov qword [kernel + 5*8], 1
      mov qword [kernel + 6*8], 0
      mov qword [kernel + 7*8], 1
      mov qword [kernel + 8*8], 2
      jmp rest
      
convol2d:
   xor rcx, rcx ; idx for tmp
   mov r13, [row]
   sub r13, 2 ; i bound
   mov r14, [col]
   sub r14, 2 ; j bound
   
   xor r9, r9 ; i
   looop1:
      cmp r9, r13
      je looop1_out

      xor r10, r10 ; j
      looop2:
         cmp r10, r14
         je looop2_out

         xor rbx, rbx ; sum in rbx
         xor r11, r11 ; i'
         looop3:
            cmp r11, 3
            je looop3_out

            xor r12, r12 ; j'
            looop4:
               cmp r12, 3
               je looop4_out

               push r9
               push r10

               add r9, r11
               add r10, r12
               call compute_idx1
               mov r8, rax
               call compute_idx3

               mov r15, [kernel + rax*8]
               mov rax, r15
               mov r15, [matrix + r8*8]
               mul r15
               add rbx, rax

               pop r10
               pop r9

               inc r12
               jmp looop4
            
            looop4_out:
               inc r11
               jmp looop3
         
         looop3_out:
            mov [tmp + rcx*8], rbx
            inc rcx
            inc r10
            jmp looop2

      looop2_out:
         inc r9
         jmp looop1
   
   looop1_out:
      xor rbx, rbx ; idx

      from_tmp_convol:
         cmp rbx, rcx
         je from_tmp_convol_out

         mov rax, [tmp + rbx*8]
         mov [matrix + rbx*8], rax

         inc rbx
         jmp from_tmp_convol

      from_tmp_convol_out:
         mov rax, [row]
         sub rax, 2
         mov [row], rax

         mov rax, [col]
         sub rax, 2
         mov [col], rax
         ret

save_to_txt:
   xor rcx, rcx ; index for buffer
   mov rax, [row]
   call add_num_txt
   mov byte [buffer + rcx], Space
   inc rcx

   mov rax, [col]
   call add_num_txt
   mov byte [buffer + rcx], Space
   inc rcx

   mov rax, [dim]
   call add_num_txt
   mov byte [buffer + rcx], Space
   inc rcx

   mov rax, [grey_flag]
   call add_num_txt
   mov byte [buffer + rcx], NL
   inc rcx

   xor r8, r8 ; index for matrix
   mov rax, [row]
   mov rbx, [col]
   mul rbx
   mov rbx, [dim]
   mul rbx
   mov r9, rax
   move_matrix:
      cmp r8, r9
      je move_end

      mov rax, [matrix + r8*8]
      call add_num_txt
      mov byte [buffer + rcx], Space
      inc rcx
      inc r8
      jmp move_matrix
   
   move_end:
      mov [len2write], rcx
      call open_file2
      call write_file
      call close_file

      ret

add_num_txt:
   cmp rax, 0
   je zero_case

   mov r10, 10
   mov rbx, -1
   push rbx
   
   push_digs:
      cmp rax, 0
      je pop_digs

      xor rdx, rdx
      div r10
      push rdx
      jmp push_digs
   
   pop_digs:
      xor rbx, rbx
      pop rbx
      cmp rbx, -1
      je add_num_out

      add bl, 48
      mov [buffer + rcx], bl
      inc rcx
      jmp pop_digs

   zero_case:
      mov byte [buffer + rcx], 48
      inc rcx
      ret

   add_num_out:
      ret

_start:

   call print_menu
   input_loop:
      cmp rax, 1
      je option1
      
      cmp rax, 2
      je option2

      cmp rax, 3
      je option3

      cmp rax, 4
      je option4

      cmp rax, 5
      je option5

      cmp rax, 6
      je option6

      cmp rax, -1
      je option_minus

      mov rsi, invalid_opt
      call print_string
      call newLine
      call print_menu
      jmp input_loop

   option1:
      call read_txt
      call txt_to_matrix
      mov rsi, operation_done
      call print_string
      call newLine
      call print_menu
      jmp input_loop

   option2:
      call reshape
      mov rsi, operation_done
      call print_string
      call newLine
      call print_menu
      jmp input_loop
   
   option3:
      call resize
      mov rsi, operation_done
      call print_string
      call newLine
      call print_menu
      jmp input_loop

   option4:
      call convol_filters
      mov rsi, operation_done
      call print_string
      call newLine
      call print_menu
      jmp input_loop

   option5:
      call pooling
      mov rsi, operation_done
      call print_string
      call newLine
      call print_menu
      jmp input_loop

   option6:
      call noise
      mov rsi, operation_done
      call print_string
      call newLine
      call print_menu
      jmp input_loop

   option_minus:
      call save_to_txt
      mov rsi, output_saved
      call print_string
      call newLine

   Exit:
      mov     rax, sys_exit
      xor     rdi, rdi
      syscall