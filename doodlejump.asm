.data
	displayAddr:	.word 0x10008000
	skyColor:		.word 0xe8fafa	# light blue
	charColor:		.word 0xd9a121	# orange
	platformColor:  .word 0x875703	# brown

.text
	#############################
	##       GAME SETUP        ## 
	#############################
	
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
	
	# draw entire board with skyBGColor
	jal paintBoard

	# === Reserved Saved Temporaries  ===
	# s0 (base dp addr)
	# s1 (current char location, denotes the very top pixel of char)
	# s2 (move flag)
	# s3 (move step count)
	# s4 (lowest  platform (lp) location, denotes the center pixel of the 5 pixel platform)
	# s5 (middle  platform (mp) location)
	# s6 (highest platform (hp) location)
	
	#############################
	##     MAIN GAME LOOP      ## 
	#############################
							
	main_game_loop:
		lw  $a1, charColor				# set character color
		# draw char at current character position ($s1)
		add $a0, $s1, $zero
		jal drawCharacter
		
		lw  $a1, platformColor			# set platform color
		# draw lowest platform at current lp ($s4)
		add $a0, $s4, $zero
		jal drawPlatform
		# draw middle platform at current mp ($s5)
		add $a0, $s5, $zero
		jal drawPlatform
		# draw highest platform at current hp ($s6)
		add $a0, $s6, $zero
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
		beq $s2, 1, move_up				# if move flag is 1, move up
		beq $s2, 0, move_down			# if move flag is 0, move down
		move_up:
			addi $s1, $s1, -128			# move char pos up 1 row
			j finish_up_move			# finish and clean up move up
		move_down:
			addi $s1, $s1, 128			# move char pos down 1 row
			j finish_down_move			# finish and clean up move down
		finish_up_move:
			addi $s3, $s3, 1			# increment move counter by 1
			beq $s3, 11, change_to_down_direction	# if move counter == 8, change direction to down
			j listen_for_input			# listen_for_input is the next step after updaing char's y position
		finish_down_move:
			addi $s3, $s3, 1			# increment move counter by 1
			beq $s3, 11, change_to_up_direction		# if move counter == 8, change direction to up
			j listen_for_input			# listen_for_input is the next step after updaing char's y position
		change_to_down_direction:
			li $s3, 0					# reset move counter
			li $s2, 0					# set move flag to 0 (down)
			j listen_for_input			# listen_for_input is the next step after updaing char's y position
		change_to_up_direction:
			li $s3, 0					# reset move counter
			li $s2, 1					# set move flag to 1 (up)
			j listen_for_input			# listen_for_input is the next step after updaing char's y position
			
	listen_for_input:	
		# handle keyboard input (j,k)
		lw $t8, 0xffff0000				# read if input exists
		bne $t8, 1, main_game_loop		# input DNE => loop again
		lw $t8, 0xffff0004				# read input char
		beq $t8, 0x6a, j_on_press		# input char is j 
		beq $t8, 0x6b, k_on_press		# input char is k
		j main_game_loop				# input is neither j nor k, loop again
	
	# move Doodler left after j is pressed
	j_on_press:
		addi $t9, $t9, -4
		beq $t9, $zero, main_game_loop	# $t9 == 0, on the left edge, loop again
		addi $s1, $s1, -4				# move dp addr left by one pixel (4)
		j main_game_loop				# loop game again
	# move Doodler right after k is pressed
	k_on_press:
		addi $t9, $t9, -120				# $t9 -= 124, used in the following line to check $t9 == 124
		beq $t9, $zero, main_game_loop	# $t9 == 0, on the right edge, loop again
		addi $s1, $s1, 4				# move dp addr right by one pixel (4)
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
		sw $a1, -8($a0)					# draw dot two pixels left at $a0
		sw $a1, -4($a0)					# draw dot one pixels left at $a0
		sw $a1,  0($a0)					# draw dot at $a0
		sw $a1,  4($a0)					# draw dot one pixels right at $a0
		sw $a1,  8($a0)					# draw dot two pixels right at $a0
		jr $ra							# return
		
	# re-paint the entire board to bg color
	paintBoard:
		lw $t0, skyColor
		addi $t2, $s0, 16384			# finish condition of loop, size of board
		draw_bg_loop:
			sw $t0, 0($s0)					# paint $t8 (sky color) to current dp addr
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
		li $a1, 28						# range of RNG: [0, 27]
		syscall
		addi $a0, $a0, 2				# add random int by 2 (center of a block, new range: [2, 29])
		mul $t0, $a0, 4					# multiply the random int by 4, new range: [8, 116]
		add $v0, $t0, $zero				# save the prev result to $v0
		jr $ra							# return
		
Exit:
	li $v0, 10
	syscall
		
		
		
	
	
	
	
	
	
