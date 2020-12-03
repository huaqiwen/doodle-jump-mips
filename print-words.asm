.data
	ggColor:		.word 0x2800d9

.text

# prints the letter G where top left corner is at $a0
printLetterG:
	li $t0, 0x2800d9
	sw $t0, 0($a0)



