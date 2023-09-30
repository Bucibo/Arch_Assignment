.data
    original_image: .asciiz "C:\Users\User\Documents\CSC2002S\code\house_64_in_ascii_lf.ppm"   # Name of the original input file
    new_image: .asciiz "C:\Users\User\Documents\CSC2002S\code\output.ppm"        # Name of the output file
    buffer:   .space    80
.text
.globl    main
    main:
        # Open the original image file for reading
        li $v0, 13          # Service code for open file (read mode)
        la $a0, original_image
        li $a1, 0           # File mode (read-only)
        li $a2, 0           # File permission (ignored)
        syscall

        # Check if file opened successfully
        #bnez $v0, file_opened_error

        # Open the new image file for writing
        li $v0, 13          # Service code for open file (write mode)
        la $a0, new_image
        li $a1, 1           # File mode (write-only)
        li $a2, 0           # File permission (ignored)
        syscall

        # Check if file opened successfully
        #bnez $v0, file_opened_error

        # Initialize sum variables for average calculation
        li $t0, 0           # Sum of original image RGB values
        li $t1, 0           # Sum of new image RGB values

        # Read and process the header (first 4 lines)
        li $t2, 0           # Line counter
    read_header_loop:
        beq $t2, 4, read_pixels
        li $v0, 14          # Service code for read string
        la $a0, buffer
        li $a1, 80          # Maximum buffer size (assuming 80 characters max per line)
        syscall

        # Check if it's a comment line (starts with '#')
        lb $t3, buffer
        beq $t3, '#', skip_comment
        addi $t2, $t2, 1    # Increment line counter

        # Process the header line (first 4 lines)
        beqz $t2, read_header_loop

        # Parse the header values (assuming valid format)
        li $t4, 10           # ASCII value of newline character
        li $t5, 0            # Value accumulator
        li $t6, 0            # Digit multiplier
        li $t7, 0            # Index within buffer
    parse_header_loop:
        lb $t3, buffer($t7)  # Load a character from the buffer
        beq $t3, $t4, update_header_value  # Check for newline
        sub $t3, $t3, '0'   # Convert ASCII character to integer
        mul $t5, $t5, 10     # Multiply the current value by 10
        add $t5, $t5, $t3    # Add the new digit to the value
        addi $t7, $t7, 1     # Increment the index
        j parse_header_loop

    update_header_value:
        # Determine which header field we are updating
        beq $t2, 1, set_rows
        beq $t2, 2, set_columns
        beq $t2, 3, set_max_value
        j read_header_loop

    set_rows:
        # Set the number of rows
        move $s0, $t5
        j read_header_loop

    set_columns:
        # Set the number of columns
        move $s1, $t5
        j read_header_loop

    set_max_value:
        # Set the maximum pixel value
        move $s2, $t5
        j read_header_loop

    skip_comment:
        j read_header_loop

    read_pixels:
        # Calculate the total number of pixels
        mul $s3, $s0, $s1

        # Initialize the loop counter and loop start address
        li $t8, 0                # Loop counter
        la $t9, pixel_buffer     # Address to store processed pixel values

    read_pixel_loop:
        # Check if we have processed all pixels
        beq $t8, $s3, calculate_average

        # Read R, G, and B values for a pixel
        li $v0, 14          # Service code for read string
        la $a0, buffer
        li $a1, 80          # Maximum buffer size (assuming 80 characters max per line)
        syscall

        # Parse R, G, and B values (assuming valid format)
        li $t4, 10           # ASCII value of newline character
        li $t5, 0            # R value accumulator
        li $t6, 0            # G value accumulator
        li $t7, 0            # B value accumulator
        li $t9, 0            # Value index within buffer
    parse_rgb_values_loop:
        lb $t3, buffer($t9)  # Load a character from the buffer
        beq $t3, $t4, update_pixel_values  # Check for newline
        sub $t3, $t3, '0'   # Convert ASCII character to integer
        mul $t5, $t5, 10     # Multiply the current value by 10
        add $t5, $t5, $t3    # Add the new digit to the value
        addi $t9, $t9, 1     # Increment the index
        j parse_rgb_values_loop

    update_pixel_values:
        # Ensure RGB values are not greater than 255
        li $t8, 255         # Maximum RGB value

        # Calculate new RGB values
        addi $t5, $t5, 10   # Increase R value by 10
        addi $t6, $t6, 10   # Increase G value by 10
        addi $t7, $t7, 10   # Increase B value by 10

        # Check if new values exceed the maximum
        bgt $t5, $t8, set_max_r_value
        bgt $t6, $t8, set_max_g_value
        bgt $t7, $t8, set_max_b_value

        j store_new_pixel_values

    set_max_r_value:
        # Set R value to the maximum allowed value (255)
        move $t5, $t8
        j store_new_pixel_values

    set_max_g_value:
        # Set G value to the maximum allowed value (255)
        move $t6, $t8
        j store_new_pixel_values

    set_max_b_value:
        # Set B value to the maximum allowed value (255)
        move $t7, $t8

    store_new_pixel_values:
        # Store the new R, G, and B values in the pixel buffer
        sb $t5, 0($t9)    # Store R value
        sb $t6, 1($t9)    # Store G value
        sb $t7, 2($t9)    # Store B value

        # Update the loop counter and buffer address
        addi $t8, $t8, 1
        addi $t9, $t9, 3

        j read_pixel_loop

    calculate_average:
        # Calculate the average RGB values of the original image
        li $t0, 0           # Reset sum for original image
        la $t9, pixel_buffer     # Address of the pixel buffer
    calculate_original_average_loop:
        beq $t8, $s3, calculate_new_average
        lb $t3, 0($t9)     # Load R value
        add $t0, $t0, $t3  # Add R value to sum
        addi $t9, $t9, 3   # Move to the next pixel
        addi $t8, $t8, 1   # Increment loop counter
        j calculate_original_average_loop

    calculate_new_average:
        # Calculate the average RGB values of the new image
        li $t1, 0           # Reset sum for new image
        la $t9, pixel_buffer     # Address of the pixel buffer
        li $t8, 0                # Reset loop counter
    calculate_new_average_loop:
        beq $t8, $s3, display_averages
        lb $t3, 0($t9)     # Load R value
        add $t1, $t1, $t3  # Add R value to sum
        addi $t9, $t9, 3   # Move to the next pixel
        addi $t8, $t8, 1   # Increment loop counter
        j calculate_new_average_loop

    display_averages:
        # Calculate the average RGB values
        divu $t0, $t0, $s3  # Divide sum of original image by the number of pixels
        divu $t1, $t1, $s3  # Divide sum of new image by the number of pixels

        # Convert averages to floating-point representation
        mtc1 $t0, $f0        # Load original image average to $f0
        mtc1 $t1, $f2        # Load new image average to $f2
        cvt.d.s $f0, $f0     # Convert original image average to double
        cvt.d.s $f2, $f2     # Convert new image average to double

        # Display the average RGB values on the console
        li $v0, 3            # Service code for printing a double (double precision)
        mov.d $f12, $f0      # Load original image average to $f12
        syscall

        li $v0, 4            # Service code for printing a string
        la $a0, newline_str
        syscall

        li $v0, 3            # Service code for printing a double (double precision)
        mov.d $f12, $f2      # Load new image average to $f12
        syscall

        # Close the original and new image files
        li $v0, 16           # Service code for close file
        syscall

        # Exit the program
        li $v0, 10           # Service code for program exit
        syscall

    file_opened_error:
        # Error message if file open operation fails
        li $v0, 4            # Service code for printing a string
        la $a0, file_open_error_msg
        syscall

        # Exit the program
        li $v0, 10           # Service code for program exit
        syscall

.data
    buffer: .space 80          # Buffer for reading lines from the file
    pixel_buffer: .space 4096  # Buffer for storing processed pixel values (4096 pixels)
    newline_str: .asciiz "\n"
    file_open_error_msg: .asciiz "Error: Could not open file.\n"









