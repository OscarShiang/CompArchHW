main:
    addi $a0, $zero, 10 # n = 10
    jal fib          # call fib(10)
    j exit

fib:
    addi $sp, $sp, -12
    sw $ra, 0x0($sp)    # Save $ra register into stack

    #--------------------------------------#
    #  \^o^/   Write your code here~  \^o^/#
    #--------------------------------------#
    
    # branch for arg to 0 or 1
    beq $a0, $zero, Back
    beq $a0, 1, Back
    j Else
    
    Back:
    add $v0, $a0, $zero
    j Return

    Else:
    # call fib(n - 1)
    sw $a0, 8($sp)
    addi $a0, $a0, -1
    jal fib
    sw $v0, 4($sp)
    
    # call fib(n - 2)
    lw $t0, 8($sp)
    addi $a0, $t0, -2
    jal fib
    
    lw $t2, 4($sp)
    add $v0, $v0, $t2
    
    Return:
    lw $ra, 0x0($sp)    # Load $ra register from stack
    addi $sp, $sp, 12
    jr $ra

exit:
