
	.equ	ROWS, 		25		# number of rows
	.equ	COLS, 		80		# number of columns

	.equ	CHARBYTES,	2		# total #bytes per char
	.equ	ROWBYTES,	COLS*CHARBYTES	# total #bytes per row
	.equ	SCREENBYTES,	ROWS*ROWBYTES	# total #bytes per screen

	.equ	SPACE,		32		# blank space
	.equ	NEWLINE,	'\n'		# newline character

	.equ	DEFAULT_ATTR, 	0x2e		# PSU Green
    .equ    DEFAULT_WORD,   32
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
cls:    pushl	%ebp
        movl	%esp, %ebp
       	# reset all values to SPACE (char, ie byte 0)
        # then set to DEFAULT_ATTR  (attr/color, ie byte 1)
    	# byte 0 == character, byte 1 == attribute

        # example of updating values of a video location/char
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

        movl $video, %edx			# put start of vram in edx
        movl $SCREENBYTES, %ecx		# put max bytes in ecx
loop:   movl %eax, (%edx)			# put the value in edx
        addl $4, %edx				# move to next part of video array 
        subl $4, %ecx				# sub 4 from max bytes 
        jnz loop					# if max bytes > 0, keep looping

        movl $0, row				# return cursor to origin (0,0)
        movl $0, col	

        movl	%ebp, %esp			# epilogue
        popl	%ebp
        ret

    # Set the video attribute for characters output using outc.
    .globl  setAttr

setAttr:movl    4(%esp), %eax           # Read parameter, beyond return addr.
        movl    %eax, attr              # And save in the attr global variable
        ret


    # Output a single character at the current row and col position
    # on screen, advancing the cursor coordinates and scrolling the
    # screen as appropriate.  Special treatment is provided for
    # NEWLINE characters, moving the "cursor" to the start of the
    # "next line".
    .globl  outc

outc:   pushl   %ebp            # Standard prologue
        movl    %esp, %ebp
        movl    8(%ebp), %eax   # Get parameter (character to output)
        cmpl    $NEWLINE, %eax  # Check for a newline
        jz      outnl

        movb    attr, %ah       # Add attribute byte to char code
        movl    $video, %edx    # Find start of video buffer
        movl    row, %ecx       # Find row number
        imull   $ROWBYTES, %ecx # Skip ROWBYTES for every row
        addl    %ecx, %edx
        movl    col, %ecx       # Skip two bytes for preceding column
        leal    (%edx,%ecx,2), %edx
        movw    %ax, (%edx)     # Save character and attribute
        incl    %ecx            # Advance column ...
        cmpl    $COLS, %ecx     # ... and check to see if we have reached

        jnl     outnl           #     the right edge of the screen
        movl    %ecx, col       # Save new column position
        jmp     done

        # Output a new line 
outnl:  movl    $0, col         # Reset column
        movl    row, %eax       # Are we on the bottom row?
        cmpl    $(ROWS-1), %eax
        jnl     scroll          # If so, then we need to scroll
        incl    %eax            # Otherwise just increment row number
        movl    %eax, row       # ... and save it 
        jmp     done

scroll: pushl   %esi            # esi and edi are callee saves registers
        pushl   %edi

        # Overwrite the data in rows 0-23 with the contents of rows 1-24:
        movl    $ROWBYTES, %esi # Copy from second row ...
        movl    $video, %edi    # ... to start of first row ... and so on
        addl    %edi, %esi
        movl    $(SCREENBYTES - ROWBYTES), %ecx # Number of bytes to copy
1:      movl    (%esi), %eax
        movl    %eax, (%edi)
        addl    $4, %edi        # Advance source and destination pointers
        addl    $4, %esi
        subl    $4, %ecx        # Reduce number of bytes copied
        jnz     1b

        # Clear the "newly revealed" row 24:
        movl    $(ROWBYTES/4), %ecx

1:      movl    $DEFAULT_WORD, (%edi)
        addl    $4, %edi
        decl    %ecx
        jnz     1b
        popl    %edi            # Restore callee saves
        popl    %esi

done:   movl    %ebp, %esp      # Standard epilogue
        popl    %ebp
        ret

		movl	%ebp, %esp
		popl	%ebp
		ret

    # Output an unsigned numeric value as a sequence of 8 hex digits.
    .globl  outhex

outhex: pushl   %ebp            # Standard prolog
        movl    %esp, %ebp
        movl    8(%esp), %eax   # Find the number to display
        movl    $8, %ecx        # We want to display 8 nibbles in total

1:      rol     $4, %eax        # Rotate top nibble in to least sig. pos.
        movl    %eax, %edx      # Make a copy that we can modify
        andl    $15, %edx       # Mask out the least significant nibble
        cmpl    $10, %edx       # And determine how digit should be displayed:
        jl      2f
        addl    $('A'-10), %edx # As a hex digit in the range A-F ...
        jmp     3f

2:      addl    $'0', %edx      # Or as a decimal digit in the range 0-9 ...

3:      pushl   %eax            # Save caller saves registers ...
        pushl   %ecx
        pushl   %edx            # ... including the character to be output
        call    outc
        popl    %edx            # Restore save registers
        popl    %ecx
        popl    %eax
        decl    %ecx            # And loop until we're done
        jnz     1b

        movl    %ebp, %esp      # Standard epilogue
        popl    %ebp
        ret
