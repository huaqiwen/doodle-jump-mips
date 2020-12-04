.data
	displayAddr:	.word 0x10008000
	skyColor:		.word 0xfcfcde	# light yellow
	charColor:		.word 0xd9a121	# orange
	platformColor:  .word 0x2f912f	# dark green
	gameOverColor:  .word 0xff0000  # red
	ggColor:		.word 0x2800d9	# dark blue
	score: 			.word 0x0		# game score counter 

.text
	#############################
	##       GAME SETUP        ## 
	#############################
INIT:	
	lw	 $s0, displayAddr				# $s0 stores the base addr for display
	addi $s1, $s0, 3388					# set initial character position
	li 	 $s2, 1							# move flag; 1: moving up, 0: moving down
	li	 $s3, 0							# move step count: count how many steps char has move up/down
	addi $s4, $s0, 3772					# set initial lowest platform location	(y = 29)
	
	jal generatePlatformX				# generate random x val for middle platform
	addi $s5, $v0, 2560					# set initial middle platform location (y = 20, x = rand)
	add  $s5, $s5, $s0					# add base dp addr
	jal generatePlatformX				# generate random x val for highest platform
	addi $s6, $v0, 1408					# set initial middle platform location (y = 11, x = rand)
	add  $s6, $s6, $s0					# add base dp addr
	jal generatePlatformX				# generate random x val for highest platform
	addi $s7, $v0, 256					# set initial middle platform location (y = 2, x = rand)
	add  $s7, $s7, $s0					# add base dp addr
	
	li $t0, 0							# store 0 into $t0
	sw $t0, score						# store 0 into score memory
	
	# draw entire board with skyBGColor
	lw  $a0, skyColor
	jal paintBoard

	# === Reserved Saved Temporaries  ===
	# s0 (base dp addr)
	# s1 (current char location, denotes the very top pixel of char)
	# s2 (move flag)
	# s3 (move step count)
	# s4 (lowest  platform (p0) location, denotes the center pixel of the 5 pixel platform)
	# s5 (lower  platform  (p1) location)
	# s6 (higher platform  (p2) location)
	# s7 (highest platform (p2) location)
	
	#############################
	##     MAIN GAME LOOP      ## 
	#############################
							
	main_game_loop:
		# DEBUG
		lw $a0, score					# load score into $a0
		li $v0, 1						# service 1, print
		syscall

		lw $t0, score					# load score into $t0
		li $t1, 10
		div $t0, $t1					# calculate score / 10
		mfhi $t0						# store second digit of score's decimal representation into $t0
		mflo $t1						# store first digit of score's decimal representation into $t1
		beq $t1, 0, single_digit_score	# if only single digit, jump to single_digit_score
		
		addi $a0, $s0, 132				# store left digit position into $a0
		beq $t1, 1, print_one_left
		beq $t1, 2, print_two_left
		beq $t1, 3, print_three_left
		beq $t1, 4, print_four_left
		beq $t1, 5, print_five_left
		beq $t1, 6, print_six_left
		beq $t1, 7, print_seven_left
		beq $t1, 8, print_eight_left
		beq $t1, 9, print_nine_left
		
		single_digit_score:
			addi $a0, $s0, 132				# store score display position into $a0
		print_right_digit:
			mfhi $t0						# store second digit of score's decimal representation into $t0
			beq $t0, 0, print_zero
			beq $t0, 1, print_one
			beq $t0, 2, print_two
			beq $t0, 3, print_three
			beq $t0, 4, print_four
			beq $t0, 5, print_five
			beq $t0, 6, print_six
			beq $t0, 7, print_seven
			beq $t0, 8, print_eight
			beq $t0, 9, print_nine
		
		print_zero:
			jal printZero
			j finish_printing_score
		print_one:
			jal printOne
			j finish_printing_score
		print_two:
			jal printTwo
			j finish_printing_score
		print_three:
			jal printThree
			j finish_printing_score
		print_four:
			jal printFour
			j finish_printing_score
		print_five:
			jal printFive
			j finish_printing_score
		print_six:
			jal printSix
			j finish_printing_score
		print_seven:
			jal printSeven
			j finish_printing_score
		print_eight:
			jal printEight
			j finish_printing_score
		print_nine:
			jal printNine
			j finish_printing_score
			
		# TODO: this is a bad implementation, clean this up later if I have time
		print_one_left:
			jal printOne
			addi $a0, $s0, 148
			j print_right_digit
		print_two_left:
			jal printTwo
			addi $a0, $s0, 148
			j print_right_digit
		print_three_left:
			jal printThree
			addi $a0, $s0, 148
			j print_right_digit
		print_four_left:
			jal printFour
			addi $a0, $s0, 148
			j print_right_digit
		print_five_left:
			jal printFive
			addi $a0, $s0, 148
			j print_right_digit
		print_six_left:
			jal printSix
			addi $a0, $s0, 148
			j print_right_digit
		print_seven_left:
			jal printSeven
			addi $a0, $s0, 148
			j print_right_digit
		print_eight_left:
			jal printEight
			addi $a0, $s0, 148
			j print_right_digit
		print_nine_left:
			jal printNine
			addi $a0, $s0, 148
			j print_right_digit
		
		finish_printing_score:
		
		# check for game over
		addi $t0, $s0, 4096
		bge  $s1, $t0, gameOver
		
		# check if lowest platform (p0) is out of screen
		ble $s4, $t0, lowest_plat_not_out
		add $s4, $s5, $zero				# move value from p1 to p0
		add $s5, $s6, $zero				# move value from p2 to p1
		add $s6, $s7, $zero				# move value from p3 to p2
		# generate new position for the highest platform (p3)
		jal generatePlatformX			# generate random x val for p3
		addi $s7, $v0, -640				# move p3.y up by 5 rows, out of screen for now
		add  $s7, $s7, $s0				# add base dp addr
		
		lowest_plat_not_out:			# placeholder label if the condition above fails
		
		lw  $a1, charColor				# set character color
		# draw char at current character position ($s1)
		add $a0, $s1, $zero
		jal drawCharacter
		
		lw  $a1, platformColor			# set platform color
		# draw lowest platform at current p0 ($s4)
		add $a0, $s4, $zero
		jal drawPlatform
		# draw lower platform at current p1 ($s5)
		add $a0, $s5, $zero
		jal drawPlatform
		# draw higher platform at current p2 ($s6)
		add $a0, $s6, $zero
		jal drawPlatform
		# draw highest platform at current p3 ($s6)
		add $a0, $s7, $zero
		jal drawPlatform
	
		addi $t9, $zero, 128			# load 128 (board width) into $t9
		div $s1, $t9					# divide current char addr by $t9 (128)
		mfhi $t9						# load remainder into $t9, will be to check if at edges
		
		# sleep for 70 ms between each frames
		li $v0, 32						# service 32 for sleep
		li $a0, 70						# sleep for 70 ms
		syscall
		
		# erase current position
		add $a0, $s1, $zero				# set current char pos to arg 0
		lw $a1, skyColor				# set bg color to arg 1
		jal drawCharacter				# erase current char pos drawing
		
		# update char's y position
		beq $s2, 1, move_up_char		# if move flag is 1, move up
		beq $s2, 0, move_down_char		# if move flag is 0, move down
		
		move_up_char:
			addi $t0, $s0, 1664			# load $t0 with approximately x = 0, y = 13
			ble  $s1, $t0, move_down_platforms	# if char pos.y <= 13, move down plats instead of char
			
			addi $s1, $s1, -128			# move char pos up 1 row
			j finish_up_move			# finish and clean up move up
			
		move_down_platforms:
			# erase all current platforms
			lw   $a1, skyColor			# load $a1 with bg color
			addi $a0, $s4, 0			# load $a0 with p1 position
			jal drawPlatform			# draw p1 with bg color, i.e., erase
			addi $a0, $s5, 0			# load $a0 with p2 position
			jal drawPlatform			# draw p1 with bg color, i.e., erase
			addi $a0, $s6, 0			# load $a0 with p3 position
			jal drawPlatform			# draw p1 with bg color, i.e., erase
			addi $a0, $s7, 0			# load $a0 with p4 position
			jal drawPlatform			# draw p1 with bg color, i.e., erase
			
			# move all platform positions down by 1 row
			addi $s4, $s4, 128
			addi $s5, $s5, 128
			addi $s6, $s6, 128
			addi $s7, $s7, 128
			
			j finish_up_move			# finish and clean up move up
			
		move_down_char:
			addi $s1, $s1, 128			# move char pos down 1 row
			addi $t0, $s1, 384			# save the address of the pixel 3 rows beneath curr char pos
			lw   $t0, 0($t0)			# save the color of the pixel calculated from above
			lw   $t1, platformColor		# save platform color HEX into $t1
			beq  $t0, $t1, change_to_up_direction  # handle colliding with a platform
			# similarly check for one pixel left
			addi $t0, $s1, 380			
			lw   $t0, 0($t0)			
			lw   $t1, platformColor		
			beq  $t0, $t1, change_to_up_direction
			# similarly check for one pixel right
			addi $t0, $s1, 388			
			lw   $t0, 0($t0)			
			lw   $t1, platformColor		
			beq  $t0, $t1, change_to_up_direction
			
			j listen_for_input			# no platform below, continue
			
		finish_up_move:
			addi $s3, $s3, 1			# increment move counter by 1
			beq $s3, 12, change_to_down_direction	# if move counter == 12, change direction to down
			j listen_for_input			# listen_for_input is the next step after updaing char's y position
			
		change_to_down_direction:		# this happens iff char ascended for 12 pixels
			li $s3, 0					# reset move counter
			li $s2, 0					# set move flag to 0 (down)
			j listen_for_input			# listen_for_input is the next step after updaing char's y position
			
		change_to_up_direction:			# this happens iff char hit platform
			addi $t0, $s0, 3072
			bge $s1, $t0, old_platform_hit
			jal incrementScore
			
			old_platform_hit:
			li $s3, 0					# reset move counter
			li $s2, 1					# set move flag to 1 (up)
			j listen_for_input			# listen_for_input is the next step after updaing char's y position
			
	listen_for_input:
		addi $a0, $s0, 132				# clear the number (2 digit)
		jal clearNumber
		# handle keyboard input (j,k)
		lw $t8, 0xffff0000				# read if input exists
		bne $t8, 1, main_game_loop		# input DNE => loop again
		lw $t8, 0xffff0004				# read input char
		beq $t8, 0x6a, j_on_press		# input char is j 
		beq $t8, 0x6b, k_on_press		# input char is k
		j main_game_loop				# input is neither j nor k, loop again
	
	# move Doodler left after j is pressed
	j_on_press:
		addi $s1, $s1, -8				# move dp addr left by one pixel (4)
		j main_game_loop				# loop game again
	# move Doodler right after k is pressed
	k_on_press:
		addi $s1, $s1, 8				# move dp addr right by one pixel (4)
		j main_game_loop				# loop game again
		
	j Exit								# exit the program so the functions below don't run unexpectedly
		
		
	############################
	##      FUNCTIONS         ## 
	############################
	
	# draw the character at $a0 with color at $a1
	drawCharacter:
		sw $a1,   0($a0)				# draw dot at $a0
		sw $a1, 124($a0)				# draw dot at bottom-left of $a0
		sw $a1, 132($a0)				# draw dot at bottom-right of $a0
		sw $a1, 256($a0)				# draw dot two rows below $a0
		jr $ra							# return 
		
	# draw the platform at $a0 with color at $a1
	drawPlatform:
		sw $a1, -12($a0)					# draw dot 3 pixels left at $a0
		sw $a1,  -8($a0)					# draw dot 2 pixels left at $a0
		sw $a1,  -4($a0)					# draw dot 1 pixels left at $a0
		sw $a1,   0($a0)					# draw dot at $a0
		sw $a1,   4($a0)					# draw dot 1 pixels right at $a0
		sw $a1,   8($a0)					# draw dot 2 pixels right at $a0
		sw $a1,  12($a0)					# draw dot 3 pixels right at $a0
		jr $ra							# return
		
	# re-paint the entire board to color stored in $a0
	paintBoard:
		addi $t2, $s0, 16384			# finish condition of loop, size of board
		draw_bg_loop:
			sw $a0, 0($s0)					# paint $t8 (sky color) to current dp addr
			addi $s0, $s0, 4				# add 4 to current dp addr
			beq $s0, $t2, end_draw_bg		# curr dp addr == size of board, end loop
			j draw_bg_loop					# loop again
		end_draw_bg:
			lw $s0, displayAddr 			# reset $s0 to start position
		jr $ra
		
	# returns ($v0) a valid random x value for a possible platform
	generatePlatformX:
		li $v0, 42						# service 42 for random int within range
		li $a0, 0						# ID of the RNG
		li $a1, 26						# range of RNG: [0, 25]
		syscall
		addi $a0, $a0, 3				# add random int by 3 (center of a block, new range: [3, 28])
		mul $t0, $a0, 4					# multiply the random int by 4, new range: [8, 116]
		add $v0, $t0, $zero				# save the prev result to $v0
		jr $ra							# return
		
	# increment the score counter by 1
	incrementScore:
		lw $t0, score				 	# load current score counter into $t0
		addi $t0, $t0, 1			 	# increment score
		sw $t0, score				 	# save incremented score into memory
		jr $ra							# return
		
	# game over handling: render game over screen & listen for retry (press SPACE)
	gameOver:
		lw $a0, skyColor				# set a0 to be the background color
		jal paintBoard					# clear the board (erase platforms)
		addi $a0, $s0, 1320				# set the position for the 1st G
		jal printLetterG
		addi $a0, $s0, 1340				# set the position for the 2nd G
		jal printLetterG
		addi $a0, $s0, 1360				# set the position for the exclamation mark
		jal printExclamationMark
		
		# press SPACE to restart game
		listen_for_retry:
			lw $t8, 0xffff0000				# read if input exists
			bne $t8, 1, listen_for_retry	# input DNE => listen again
			lw $t8, 0xffff0004				# read input char
			beq $t8, 0x20, INIT				# input char is SPACE, jump to INIT
			j listen_for_retry				# input is not SPACE, loop again
		
		j Exit
		
	# prints the letter G where top left corner is at $a0
	printLetterG:
		lw $t0, ggColor
		sw $t0, 0($a0)
		sw $t0, 4($a0)
		sw $t0, 8($a0)
		sw $t0, 12($a0)
		sw $t0, 128($a0)
		sw $t0, 256($a0)
		sw $t0, 268($a0)
		sw $t0, 384($a0)
		sw $t0, 388($a0)
		sw $t0, 392($a0)
		sw $t0, 396($a0)
		jr $ra
		
	# prints ! where top pixel is at $a0
	printExclamationMark:
		lw $t0, ggColor
		sw $t0, 0($a0)
		sw $t0, 128($a0)
		sw $t0, 384($a0)
		jr $ra
		
	printZero:
		lw $t0, ggColor
		sw $t0, 0($a0)
		sw $t0, 4($a0)
		sw $t0, 8($a0)
		sw $t0, 128($a0)
		sw $t0, 136($a0)
		sw $t0, 256($a0)
		sw $t0, 264($a0)
		sw $t0, 384($a0)
		sw $t0, 392($a0)
		sw $t0, 512($a0)
		sw $t0, 516($a0)
		sw $t0, 520($a0)
		jr $ra
		
	printOne:
		lw $t0, ggColor
		sw $t0, 8($a0)
		sw $t0, 136($a0)
		sw $t0, 264($a0)
		sw $t0, 392($a0)
		sw $t0, 520($a0)
		jr $ra
		
	printTwo:
		lw $t0, ggColor
		sw $t0, 0($a0)
		sw $t0, 4($a0)
		sw $t0, 8($a0)
		sw $t0, 136($a0)
		sw $t0, 256($a0)
		sw $t0, 260($a0)
		sw $t0, 264($a0)
		sw $t0, 384($a0)
		sw $t0, 512($a0)
		sw $t0, 516($a0)
		sw $t0, 520($a0)
		jr $ra

	printThree:
		lw $t0, ggColor
		sw $t0, 0($a0)
		sw $t0, 4($a0)
		sw $t0, 8($a0)
		sw $t0, 136($a0)
		sw $t0, 256($a0)
		sw $t0, 260($a0)
		sw $t0, 264($a0)
		sw $t0, 392($a0)
		sw $t0, 512($a0)
		sw $t0, 516($a0)
		sw $t0, 520($a0)
		jr $ra
		
	printFour:
		lw $t0, ggColor
		sw $t0, 0($a0)
		sw $t0, 8($a0)
		sw $t0, 128($a0)
		sw $t0, 136($a0)
		sw $t0, 256($a0)
		sw $t0, 260($a0)
		sw $t0, 264($a0)
		sw $t0, 392($a0)
		sw $t0, 520($a0)
		jr $ra

	printFive:
		lw $t0, ggColor
		sw $t0, 0($a0)
		sw $t0, 4($a0)
		sw $t0, 8($a0)
		sw $t0, 128($a0)
		sw $t0, 256($a0)
		sw $t0, 260($a0)
		sw $t0, 264($a0)
		sw $t0, 392($a0)
		sw $t0, 512($a0)
		sw $t0, 516($a0)
		sw $t0, 520($a0)
		jr $ra

	printSix:
		lw $t0, ggColor
		sw $t0, 0($a0)
		sw $t0, 4($a0)
		sw $t0, 8($a0)
		sw $t0, 128($a0)
		sw $t0, 256($a0)
		sw $t0, 260($a0)
		sw $t0, 264($a0)
		sw $t0, 384($a0)
		sw $t0, 392($a0)
		sw $t0, 512($a0)
		sw $t0, 516($a0)
		sw $t0, 520($a0)
		jr $ra
		
	printSeven:
		lw $t0, ggColor
		sw $t0, 0($a0)
		sw $t0, 4($a0)
		sw $t0, 8($a0)
		sw $t0, 136($a0)
		sw $t0, 264($a0)
		sw $t0, 392($a0)
		sw $t0, 520($a0)
		jr $ra

	printEight:
		lw $t0, ggColor
		sw $t0, 0($a0)
		sw $t0, 4($a0)
		sw $t0, 8($a0)
		sw $t0, 128($a0)
		sw $t0, 136($a0)
		sw $t0, 256($a0)
		sw $t0, 260($a0)
		sw $t0, 264($a0)
		sw $t0, 384($a0)
		sw $t0, 392($a0)
		sw $t0, 512($a0)
		sw $t0, 516($a0)
		sw $t0, 520($a0)
		jr $ra

	printNine:
		lw $t0, ggColor
		sw $t0, 0($a0)
		sw $t0, 4($a0)
		sw $t0, 8($a0)
		sw $t0, 128($a0)
		sw $t0, 136($a0)
		sw $t0, 256($a0)
		sw $t0, 260($a0)
		sw $t0, 264($a0)
		sw $t0, 392($a0)
		sw $t0, 512($a0)
		sw $t0, 516($a0)
		sw $t0, 520($a0)
		jr $ra
	
	# clear a number (i.e., two 5x3 rectangle) at position $a0	
	clearNumber:
		lw $t0, skyColor
		sw $t0, 0($a0)
		sw $t0, 4($a0)
		sw $t0, 8($a0)
		sw $t0, 128($a0)
		sw $t0, 132($a0)
		sw $t0, 136($a0)
		sw $t0, 256($a0)
		sw $t0, 260($a0)
		sw $t0, 264($a0)
		sw $t0, 384($a0)
		sw $t0, 388($a0)
		sw $t0, 392($a0)
		sw $t0, 512($a0)
		sw $t0, 516($a0)
		sw $t0, 520($a0)
		
		sw $t0, 16($a0)
		sw $t0, 20($a0)
		sw $t0, 24($a0)
		sw $t0, 144($a0)
		sw $t0, 148($a0)
		sw $t0, 152($a0)
		sw $t0, 272($a0)
		sw $t0, 276($a0)
		sw $t0, 280($a0)
		sw $t0, 400($a0)
		sw $t0, 404($a0)
		sw $t0, 408($a0)
		sw $t0, 528($a0)
		sw $t0, 532($a0)
		sw $t0, 536($a0)
		jr $ra
		
		
Exit:
	li $v0, 10
	syscall
		
		
		
	
	
	
	
	
	
