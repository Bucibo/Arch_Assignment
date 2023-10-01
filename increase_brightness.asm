.data 
    original_image: .asciiz "C:\\Users\\User\\Documents\\CSC2002S\\Tester\\house_64_in_ascii_lf.ppm"
    new_image: .asciiz "C:\\Users\\User\\Documents\\CSC2002S\\Tester\\output.ppm"
    header: .asciiz "P3\n# Jet\n64 64\n255\n"
    pixel_buffer: .space 49152
    buffer:     .space  49152
    newline_str: .asciiz "\n"
    file_open_error_msg: .asciiz "Error: Could not open file.\n"
.text
.globl main

main:
    # Open the original image file for reading
    li $v0, 13          # Service code for open file (read mode)
    la $a0, original_image
    li $a1, 0           # File mode (read-only)
    li $a2, 0           # File permission (ignored)
    syscall
    move $t4, $v0

    # Check if file opened successfully
    bltz $v0, file_opened_error

    # Open the new image file for writing
    li $v0, 13          # Service code for open file (write mode)
    la $a0, new_image
    li $a1, 1           # File mode (write-only)
    li $a2, 0           # File permission (ignored)
    syscall
    move $t5, $v0      # Store file descriptor for new image

    la $t6, buffer

read_pixel:
    # Read R, G, and B values for a pixel
    li $v0, 14
    move $a0, $t4          # Service code for read string
    la $a1, pixel_buffer
    li $a2, 49152      # Maximum buffer size (assuming 80 characters max per line)
    syscall

    la $t0, header      # Load the address of the source string
    li $t1, 0           # Line counter

copy_loop:
    lb $t2, ($t0)       # Load a byte from the source string
    beq $t2, 10, line_count
    sb $t2, ($t6)       # Store the byte in the destination string buffer
    addi $t0, $t0, 1    # Increment source string pointer
    addi $t6, $t6, 1    # Increment destination string buffer pointer
    j copy_loop

line_count:
    sb $t2, ($t6)
    addi $t1, $t1, 1
    beq $t1, 4, h
    addi $t0, $t0, 1
    addi $t6, $t6, 1
    j copy_loop

h:
    li $v0, 15           # System call code for "write"
    move $a0, $t5       # File descriptor of the output file
    la $a1, buffer       # Address of the data to write
    li $a2, 19       # Number of bytes read
    syscall    

#header_finished:
    # Parse R, G, and B values (assuming valid format)
#    li $t4, 10           # ASCII value of newline character
#    li $t5, 0            # Value accumulator
#    li $t9, 0            # Value index within buffer

#parse_rgb_values_loop:
#    lb $t3, ($t6)       # Load a character from the buffer
#    beq $t3, $t4, update_pixel_values
#    sub $t3, $t3, '0'   # Convert ASCII character to integer
#    mul $t5, $t5, 10    # Multiply the current value by 10
#    add $t5, $t5, $t3   # Add the new digit to the value
#    addi $t6, $t6, 1    # Increment the index
#    j parse_rgb_values_loop

#update_pixel_values:
    # Ensure RGB values are not greater than 255
#   li $t8, 255         # Maximum RGB value
#   addi $t5, $t5, 10   # Increase R value by 10
#    bgt $t5, $t8, set_max_value

#   j store_new_pixel_values

#set_max_value:
    # Set R value to the maximum allowed value (255)
#    move $t5, $t8
#    j store_new_pixel_values

#store_new_pixel_values:
    # Store the new R, G, and B values in the pixel buffer
#    sb $t5, ($t6)    # Store value
#    lb $t7, newline_str
#    sb $t7, ($t6)
#    addi $t6, $t6, 1
#    j read_pixel


exit:
    # Close the new image file
    li $v0, 16           # Service code for close file
    move $a0, $t5        # File descriptor for new image
    syscall

    li  $v0, 16
    move $a0, $t4
    syscall


    # Exit the program
    li $v0, 10           # Service code for program exit
    syscall

file_opened_error:
    # Error message if file open operation fails
    li $v0, 4            # Service code for printing a string
    la $a0, file_open_error_msg
    syscall




