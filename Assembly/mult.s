##############################################################################
# File: mult.s
##############################################################################

	.data
student:
	.asciiz "EricBuckland" 	# Place your name in the quotations in place of Student
	.globl	student
nl:	.asciiz "\n"
	.globl nl

op1:	.word 7				# change the multiplication operands
op2:	.word 19			# for testing.

	.text

	.globl main
main:					# main has to be a global label
	addi	$sp, $sp, -4		# Move the stack pointer
	sw 	$ra, 0($sp)		# save the return address

	move	$t0, $a0		# Store argc
	move	$t1, $a1		# Store argv
				
	li	$v0, 4			# print_str (system call 4)
	la	$a0, student		# takes the address of string as an argument 
	syscall	

	slti	$t2, $t0, 2		# check number of arguments
	bne     $t2, $zero, operands
	j	ready

operands:
	la	$t0, op1
	lw	$a0, 0($t0)
	la	$t0, op2
	lw	$a1, 0($t0)
		

ready:
	jal	multiply		# go to multiply code

	jal	print_result		# print operands to the console

					# Usual stuff at the end of the main
	lw	$ra, 0($sp)		# restore the return address
	addi	$sp, $sp, 4
	jr	$ra			# return to the main program


multiply:
	# temp vars
	addi $t7, $0, 1 # set a counter to 1
	addi $t6, $0, 0 # set the sum to 0
	addi $t4, $0, 128 # counter highest number
	addi $t3, $a0, 0 # set add value
	
loop:
	and $t5, $t7, $a1 # check if counter matches with a1 slot
	bne $t5, $t7, check # skip past add if not match
		
	add $t6, $t6, $t3 # counter matched, add value to main
	
check:
	# check if counter is at last position
	beq $t7, $t4, end # check if counter in last position
	
	sll $t7, $t7, 1 # shift counter by 1
	sll $t3, $t3, 1 # shift add value by 1
	j loop # loop back
	
end:
	move $a2, $t6 # save to a2, end
	
	jr	$ra
	
print_result:
	move	$t0, $a0
	li	$v0, 4
	la	$a0, nl
	syscall

	move	$a0, $t0
	li	$v0, 1
	syscall
	li	$v0, 4
	la	$a0, nl
	syscall

	li	$v0, 1
	move	$a0, $a1
	syscall
	li	$v0, 4
	la	$a0, nl
	syscall

	li	$v0, 1
	move	$a0, $a2
	syscall
	li	$v0, 4
	la	$a0, nl
	syscall

	jr $ra
