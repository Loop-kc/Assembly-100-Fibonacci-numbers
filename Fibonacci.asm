assume cs:codes, ds:datasg1

; 数据段1，包含num、extra、ans等变量
datasg1 segment
    num    dw 8 dup(0)
    extra  dw 8 dup(0)
    ans    db 32 dup(0)
    str2   db 'The fibonacci number is:','$' 
    wrongstr db 'Wrong input!',13,10,'$'
datasg1 ends

; 数据段2，包含dw和string等变量
datasg2 segment
    dw 1600 dup(0)
    str1 db 'Please input a number(1-100):N=','$' 
datasg2 ends

; 代码段开始
codes segment
; 程序入口
start:
    mov ax, datasg2    ; 设置数据段2的地址到ax
    mov ds, ax         ; 数据段2的地址加载到ds寄存器
    mov si, 0
    mov di, 16
    mov word ptr [si], 0 ; 初始化num数组的低位为0
    mov word ptr [di], 1 ; 初始化num数组的高位为1
    call fib           ; 调用fib过程计算斐波那契数列
    mov dx, offset str1 ; 设置dx为字符串的偏移地址
    mov ah, 09h         ; 调用dos中断21h，显示字符串 9h
    int 21h
 
    mov bx, 10  ;寄存器 bx 在后续的代码中被用作乘法的操作数
    mov cx, 0   ;循环计数器
    ; 计算斐波那契数列的前两个数字，并显示一个字符串
    call getUserInput

    ; 斐波那契数列计算正确，显示结果
    call displayResult

    mov ax, 4c00h      ; 设置dos功能号为4c（退出程序）
    int 21h            ; 调用dos中断21h

; 获取用户输入
getUserInput:
    mov ah, 01h        ; 中断调用，单字符输入
    int 21h            ; 输入符号的ASCII码在al寄存器中
    cmp al, 0dh        ; 检查输入的字符是否是换行符（ASCII码为0DH）
    jz  userInputOver  ; 如果是，跳转到userInputOver标签
    sub al, 30h        ; 将AL寄存器中的值减去30h，将字符转换成相应的数字
    add al, cl         ; CL寄存器中存储的是乘法的第二个操作数
    mov ah, 0          
    mul bx             ;执行乘法操作
    mov cx, ax         ;将乘法结果的低16位（存储在 ax 中）赋值给 cx 寄存器
    jmp getUserInput   ; 继续循环

; 用户输入结束
userInputOver:
    push cx ;保存cx的值
    mov ax, cx
    mov cl, 10
    div cl

    ; 检查输入范围，如果不在1到99之间，跳转到wrong标签
    cmp al, 1
    jb wrong
    cmp al, 99
    ja wrong
    pop cx

    ; 计算结果
    mov ax, cx  ;ax 包含用户输入数字的整数部分。
    div bx  ;
    mov cx, 16  ;即要复制的字节数。
    mul cx;将商乘以 16，得到移动的偏移量。
    mov si, ax
;?????????????
    mov ax, datasg1
    mov es, ax         ; 将es寄存器设置为datasg1段地址
    mov di, 0
    mov cx, 16;确保复制整个长整数所需的字节数,16 个字节
    rep movsb          ; 将datasg2段的前16字节复制到datasg1段
    ret

; 处理输入范围错误的情况
wrong:
    mov ax, seg wrongstr; wrongstr 字符串的段地址到 ax 寄存器
    mov ds, ax;将 ds 寄存器设置为 wrongstr 字符串的段地址
    lea dx, wrongstr   ; 将错误信息的地址赋给dx
    mov ah, 9          ; 调用显示字符串的DOS中断
    int 21h
    jmp start

; 计算斐波那契数列
fib:
    mov cx, 100   ; 为了计算斐波那契数列的第100项
calculateFibonacci:
    call add_128 ; 调用128位加法过程
    add si, 16
    add di, 16;向后移动
    loop calculateFibonacci;根据 cx 寄存器的值来判断是否执行下一次循环。如果 cx 不为零，则减一
    ret

; 执行128位加法
add_128:
    push ax
    push cx
    push si
    push di;入栈
    mov cx, 8   ; 由于128位整数有16个字节，所以需要执行8次加法操作。
    sub ax, ax;将 ax 寄存器清零，准备进行累加。
calculateSum:
    mov ax, [si] ; 从内存中读取16个字节，将这些字节加载到ax寄存器中
    adc ax, [di] ; 将ax寄存器的值与内存中的另一个128位整数值相加
    mov [di+16], ax ; 将ax寄存器的值存储到内存中di寄存器位置之后的16个字节处
    
    inc si
    inc si
    inc di
    inc di
    ;分别将 si 和 di 寄存器向后移动两个字节，准备加载下一组数据。
    loop calculateSum

    pop di
    pop si
    pop cx
    pop ax
    ret

; 显示结果
displayResult:
    mov ax, datasg1
    mov ds, ax       ; 将ds寄存器设置为datasg1段地址
    add ax, 1
    mov es, ax       ; 将es寄存器设置为datasg1段地址
    mov bx, 21

    mov dx, offset str2 ; 设置dx为字符串的偏移地址
    mov ah, 9h         ; 调用dos中断21h，显示字符串 9h
    int 21h

    mov byte ptr ans[bx], '$'
    ;ans数组被假定是一个包含字符串的缓冲区。
    dec bx

; 显示结果循环
displayLoop:
    mov si, 14
    mov di, 14

    call divideLong   ; 调用长除法过程
    add cl, 30h
    mov ans[bx], cl;将cl寄存器的值加上30h，将其转换为ASCII字符。
    dec bx
    mov si, 0
    mov cx, [si]
    jcxz displayOk     ; 如果cx为零，跳转到displayOk
    call clearExtra
    jmp displayLoop

; 显示结果完成
displayOk:
    mov dx, bx
    add dx, 32+1   ;三位是空格
    ; add dx, 30

    mov ah, 9
    int 21h
    ret

; 清除额外存储
clearExtra:
    push si
    push cx
    mov si, 0
    mov cx, 8

; 清除额外存储循环
clearLoop:
    mov word ptr extra[si], 0
    add si, 2
    loop clearLoop
    pop cx
    pop si
    ret

; 长除法过程，计算dxax/cx，商dxax，余cx
divideLong:
    mov cx, 7;将 cx 寄存器设置为 7。这个值用于控制循环次数。

; 长除法循环
divideLoop:
    push cx
    mov ax, [si-2];将内存中 si-2 处的16位值加载到 ax 寄存器，这是128位整数的高位
    mov dx, [si];将内存中 si 处的16位值加载到 dx 寄存器，这是128位整数的低位
    mov cx, 10;将 cx 寄存器设置为 10，因为要将128位整数除以一个10位整数
    call divideShort   ; 调用短除法过程,计算 dx:ax（128位整数）除以 cx，并得到商和余数。
    add es:[di], dx;将余数部分加到目标位置的高位
    add es:[di-2], ax;将商部分加到目标位置的低位
    mov [si-2], cx;将短除法过程中计算得到的余数存储到原始128位整数的高位
    mov word ptr [si], 0;清零原始128位整数的低位，为下一轮除法做准备。
    sub si, 2;移动源指针 si 到原始128位整数的下一个字
    sub di, 2
    pop cx
    loop divideLoop;循环，直到 cx 寄存器为零
    mov cx, [si];将原始128位整数的高位存储到 cx 寄存器，为下面的循环做准备。
    push cx
    mov cx, 16
    mov si, 0
    mov di, 0
; 长除法复制循环
divideCopyLoop:
    mov al, es:[di]
    mov [si], al
    inc si
    inc di
    loop divideCopyLoop
    pop cx
    ret

; 短除法过程，计算dxax/cx，商dxax，余cx
divideShort:
    push bx
    push ax
    mov ax, dx;将 dx 寄存器中的高32位部分加载到 ax 寄存器。
    mov dx, 0;将 dx 寄存器清零，准备进行除法操作
    div cx  ; 执行除法操作，将 dx:ax 除以 cx，结果的商存储在 ax，余数存储在 dx
    mov bx, ax  ; 将商存储到 bx 寄存器中
    pop ax
    div cx;将 dx:ax 除以 cx，结果的余数存储在 cx 寄存器中
    mov cx, dx
    mov dx, bx;将之前保存的商值（在 bx 中）存储到 dx 寄存器中
    pop bx
    ret

mov ah, 4Ch        ; 将4CH（DOS退出调用号）放入ah寄存器
int 21H            ; 调用DOS中断21H
codes ends
end start

