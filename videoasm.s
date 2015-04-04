
	.equ	ROWS, 		25		# number of rows
	.equ	COLS, 		80		# number of columns

	.equ	CHARBYTES,	2		# total #bytes per char
	.equ	ROWBYTES,	COLS*CHARBYTES	# total #bytes per row
	.equ	SCREENBYTES,	ROWS*ROWBYTES	# total #bytes per screen

	.equ	SPACE,		32		# blank space
	.equ	NEWLINE,	'\n'		# newline character

	.equ	DEFAULT_ATTR, 	0x2e		# PSU Green

	.data

        # Reserve space for a video ram frame buffer with
        # 25 rows; 80 columns; and one code and one attribute
        # byte per character.
	.globl  video
	.align	4
video:	.space	SCREENBYTES

        # Some variables to hold the current row, column, and
	# video attribute:
	.align	4
row:	.long	0		# we will only use the least significant
col:	.long	0		# bytes of these variables
attr:	.long	0

	.text

	# Clear the screen, setting all characters to SPACE
        # using the DEFAULT_ATTR attribute.
	.globl	cls
cls:	pushl	%ebp
		movl	%esp, %ebp
		# Fill me in!
	   	# reset all values to SPACE (char, ie byte 0)
	    # then set to DEFAULT_ATTR  (attr/color, ie byte 1)
		# byte 0 == character, byte 1 == attribute

	    # example 
	    #movl $video, %eax
	    #movb $65,(%eax)
	    #movb $60,1(%eax)

   		# write 4 bytes at a time (more efficient)
	    # DEF CHAR DEF CHAR (backwards because of little endianess)
	    movl $DEFAULT_ATTR, %eax	# set def attr in eax
	    shl $8, %eax				# shift left to make space
	    orl $SPACE, %eax			# or in the SPACE
	    movl %eax, %ecx				# copy into ecx
	    shl  $16, %eax				# shift even further
									# now eax has DEF CHAR 0 0 
									# and ecx has 0 0 DEF CHAR
	    orl  %ecx, %eax				# or them together. 32 bits of value we want

	    # different approach to the above code:
		#.equ	LOW, 	(DEFAULT_ATTR<<8) | SPACE
	    #.equ	INITWORD, (LOW<<8) | LOW
	    #movl 	$INITWORD, %eax

		movl $video, %edx
    	movl $SCREENBYTES, %ecx
loop: 	movl %eax, (%edx)
    	addl $4, %edx
    	subl $4, %ecx
    	jnz loop

    	movl $0, row
    	movl $0, col

		movl	%ebp, %esp
		popl	%ebp

		ret

	# Set the video attribute for characters output using outc.
	.globl	setAttr
setAttr:pushl	%ebp
	movl	%esp, %ebp
	# Fill me in!
	movl	%ebp, %esp
	popl	%ebp
	ret

	# Output a single character at the current row and col position
	# on screen, advancing the cursor coordinates and scrolling the
	# screen as appropriate.  Special treatment is provided for
    # NEWLINE characters, moving the "cursor" to the start of the
	# "next line".
	.globl	outc
outc:	pushl	%ebp
		movl	%esp, %ebp

		# Fill me in!
        # arg  == 8(%ebp)
        movl $video, %edx	# put cursor in edx
		movl 8(%ebp), %eax	# put arg (8 in from bp) into eax
        movl %eax, (%edx)
        #addl $4, %edx
        addl $1, row

		movl	%ebp, %esp
		popl	%ebp
		ret

	# Output an unsigned numeric value as a sequence of 8 hex digits.
	.globl	outhex
outhex:	pushl	%ebp
	movl	%esp, %ebp
	# Fill me in!
	movl	%ebp, %esp
	popl	%ebp
	ret

