##############################################################################
# File: sort.s
##############################################################################
    .data
student:
    .asciiz "Aidan Murphy and Eric Buckland\n"    # Place your name in the quotations in place of Student
    .globl  student
nl: .asciiz "\n"
    .globl nl
sort_print:
    .asciiz "[Info] Sorted values\n"
    .globl sort_print
initial_print:
    .asciiz "[Info] Initial values\n"
    .globl initial_print
read_msg: 
    .asciiz "[Info] Reading input data\n"
    .globl read_msg
code_start_msg:
    .asciiz "[Info] Entering your section of code\n"
    .globl code_start_msg

key:    .word 268632064         # Provide the base address of array where input key is stored(Assuming 0x10030000 as base address)
output: .word 268632144         # Provide the base address of array where sorted output will be stored (Assuming 0x10030050 as base address)
numkeys:    .word 6             # Provide the number of inputs
maxnumber:  .word 10            # Provide the maximum key value


## Specify your input data-set in any order you like. I'll change the data set to verify
data1:  .word 9
data2:  .word 6
data3:  .word 4
data4:  .word 1
data5:  .word 3
data6:  .word 2

    .text

    .globl main
main:                   # main has to be a global label
    addi    $sp, $sp, -4        # Move the stack pointer
    sw  $ra, 0($sp)     # save the return address
            
    li  $v0, 4          # print_str (system call 4)
    la  $a0, student        # takes the address of string as an argument 
    syscall 

    jal process_arguments
    jal read_data           # Read the input data

    j   ready

process_arguments:
    
    la  $t0, key
    lw  $a0, 0($t0)
    la  $t0, output
    lw  $a1, 0($t0)
    la  $t0, numkeys
    lw  $a2, 0($t0)
    la  $t0, maxnumber
    lw  $a3, 0($t0)
    jr  $ra 

### This instructions will make sure you read the data correctly
read_data:
    move $t1, $a0
    li $v0, 4
    la $a0, read_msg
    syscall
    move $a0, $t1

    la $t0, data1
    lw $t4, 0($t0)
    sw $t4, 0($a0)
    la $t0, data2
    lw $t4, 0($t0)
    sw $t4, 4($a0)
    la $t0, data3
    lw $t4, 0($t0)
    sw $t4, 8($a0)
    la $t0, data4
    lw $t4, 0($t0)
    sw $t4, 12($a0)
    la $t0, data5
    lw $t4, 0($t0)
    sw $t4, 16($a0)
    la $t0, data6
    lw $t4, 0($t0)
    sw $t4, 20($a0)

    jr  $ra


counting_sort:

    # a0 - key pointer
    # a1 - output pointer
    # a2 - numkeys
    # a3 - maxnumber
    # t0 - iterator (n)
    # t1 - maxnumber + 1
	# t2 - check variable to see when a loop terminates
	# t3 - temp variable
	# t4 - temp address offset
	# t5 - shifted iterator
	# t6 - shifted temp
    # s0 - count array

	addi $t1, $a3, 1 # set t1 to maxnumber + 1
    sll $t1, $t1, 2
    sub $sp, $sp, $t1 # set count pointer to stack pointer - (maxnumber + 1)
    addi $t1, $a3, 1 # set t1 to maxnumber + 1
    addi $s0, $sp, 0
    addi $t0, $0, 0 # set t0 to 0, iterator(n)

    addi $t7, $0, 5
	sw $t7, ($s0)

loop1: # initialize all elements of count to be zero
    slt $t2, $t0, $t1 # set t2 to outcome of counter < maxnumber + 1
    beq $t2, $0, break1 # break out of loop if not less than
	sll $t5, $t0, 2 # shift iterator

	addu $t4, $t5, $s0 # calculate offset
    sw $0, ($t4) # save 0 to count [n]

    addi $t0, $t0, 1 # increase iterator by 1
	j loop1 # loop back

break1:
    addi $t0, $0, 0 # set t0 to 0, iterator
    
loop2: # create a mapping of all values in keys to count
	slt $t2, $t0, $a2 # set t2 to n < numkeys
	beq $t2, $0, break2 # break out of the loop if not less than
	sll $t5, $t0, 2 # shift iterator

	addu $t4, $t5, $a0 # calculate offset
	lw $t2, ($t4) # load keys [n] into temp var 
	sll $t2, $t2, 2 # shift index
	addu $t4, $t2, $s0 # calculate offset
	lw $t3, ($t4) # load count[keys[n]] into temp var
	addi $t3, $t3, 1 # add 1 to temp var
	sw $t3, ($t4) # save temp var to count[keys[n]]

	addi $t0, $t0, 1 # increase iterator by 1
	j loop2 # loop back

break2:
    addi $t0, $0, 1 # set t0 to 1, iterator
    
loop3: # set all elements of count to the sum of themselves and the previous element of count
	slt $t2, $t0, $t1 # set t2 to outcome of counter < maxnumber + 1
    beq $t2, $0, break3 # break out of loop if not less than
	sll $t5, $t0, 2 # shift iterator

	addu $t4, $t5, $s0 # calculate offset
	lw $t2, ($t4) # load count[n] into temp var
	addi $t3, $t0 -1 # set temp var to n - 1
	sll $t3, $t3, 2 # shift index
	addu $t4, $t3, $s0 # calculate offset
	lw $t3, ($t4) # load count[n - 1] into temp var
	add $t3, $t2, $t3 # set temp var to count[n] + count[n - 1]
	addu $t4, $t5, $s0 # calculate offset
	sw $t3, ($t4) # save temp var to count[n]

	addi $t0, $t0, 1 # increase iterator by 1
	j loop3 # loop back

break3:
	addi $t0, $0, 0 # set t0 to 0, iterator
	    
loop4:
	slt $t2, $t0, $a2 # set t2 to n < numkeys
	beq $t2, $0, break4 # break out of the loop if not less than
	sll $t5, $t0, 2 # shift iterator

	addu $t4, $t5, $a0 # calculate offset
	lw $t2, ($t4) # load keys[n] into temp var
	sll $t6, $t2, 2 # shift index
	addu $t4, $t6, $s0 # calculate offset
	lw $t3, ($t4) # load count[keys[n]] into temp var
	addi $t3, $t3, -1 # subtract 1 from count[keys[n]]
	sll $t3, $t3, 2 # shift index
	addu $t4, $t3, $a1 # calculate offset
	sw $t2, ($t4) # output[] = keys[n]

	addu $t4, $t5, $a0 # calculate offset
	lw $t2, ($t4) # load keys [n] into temp var
	sll $t2, $t2, 2 # shift index
	addu $t4, $t2, $s0 # calculate offset
	lw $t3, ($t4) # load count[keys[n]] into temp var
	addi $t3, $t3, -1 # sub 1 from temp var
	sll $t3, $t3, 2 # shift index
	sw $t3, ($t4) # save temp var to count[keys[n]]

	addi $t0, $t0, 1 # increase iterator by 1
	j loop4 # loop back

break4:

	sll $t1, $t1, 2 # shift thing
	add $sp, $sp, $t1 # reset stack pointer

    jr $ra

ready:
    jal initial_values      # print operands to the console
    
    move    $t2, $a0
    li  $v0, 4
    la  $a0, code_start_msg
    syscall
    move    $a0, $t2

    jal counting_sort       # call counting sort algorithm

    jal sorted_list_print


                # Usual stuff at the end of the main
    lw  $ra, 0($sp)     # restore the return address
    addi    $sp, $sp, 4
    jr  $ra         # return to the main program

print_results:
    add $t0, $0, $a2 # No of elements in the list
    add $t1, $0, $a0 # Base address of the array
    move $t2, $a0    # Save a0, which contains base address of the array

loop:   
    beq $t0, $0, end_print
    addi, $t0, $t0, -1
    lw $t3, 0($t1)
    
    li $v0, 1
    move $a0, $t3
    syscall

    li $v0, 4
    la $a0, nl
    syscall

    addi $t1, $t1, 4
    j loop
end_print:
    move $a0, $t2 
    jr $ra  

initial_values: 
    move $t2, $a0
    addi    $sp, $sp, -4        # Move the stack pointer
    sw  $ra, 0($sp)     # save the return address

    li $v0,4
    la $a0,initial_print
    syscall
    
    move $a0, $t2
    jal print_results
    
    lw  $ra, 0($sp)     # restore the return address
    addi    $sp, $sp, 4

    jr $ra

sorted_list_print:
    move $t2, $a0
    addi    $sp, $sp, -4        # Move the stack pointer
    sw  $ra, 0($sp)     # save the return address

    li $v0,4
    la $a0,sort_print
    syscall
    
    move $a0, $t2
    
    #swap a0,a1
    move $t2, $a0
    move $a0, $a1
    move $a1, $t2
    
    jal print_results
    
    #swap back a1,a0
    move $t2, $a0
    move $a0, $a1
    move $a1, $t2
    
    lw  $ra, 0($sp)     # restore the return address
    addi    $sp, $sp, 4 
    jr $ra
