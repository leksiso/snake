.global initialize_hardware
.global pio0_sm0_put_blocking
.global byte_to_coords
.global coords_to_byte
.global get_random_byte

.equ KEY_LEFT, 10
.equ KEY_UP, 11
.equ KEY_DOWN, 12
.equ KEY_RIGHT, 13
.equ PIO_PIN, 15
.equ GPIO_EVENT_RISING_EDGE, 8
.equ TRUE, 1


initialize_hardware:
    push    {lr}
    @ Set the interrupt callback for each arrow key
    mov     r0, #KEY_LEFT
    mov     r1, #GPIO_EVENT_RISING_EDGE
    mov     r2, #TRUE
    ldr     r3, =gpio_irq_handler
    bl      gpio_set_irq_enabled_with_callback

    mov     r0, #KEY_UP
    mov     r1, #GPIO_EVENT_RISING_EDGE
    mov     r2, #TRUE
    ldr     r3, =gpio_irq_handler
    bl      gpio_set_irq_enabled_with_callback

    mov     r0, #KEY_DOWN
    mov     r1, #GPIO_EVENT_RISING_EDGE
    mov     r2, #TRUE
    ldr     r3, =gpio_irq_handler
    bl      gpio_set_irq_enabled_with_callback

    mov     r0, #KEY_RIGHT
    mov     r1, #GPIO_EVENT_RISING_EDGE
    mov     r2, #TRUE
    ldr     r3, =gpio_irq_handler
    bl      gpio_set_irq_enabled_with_callback

    @ Initialize the PIO program for controlling the led matrix
    ldr     r0, pio0_base
    mov     r1, #PIO_PIN
    bl      pio_init_ledmatrix
    pop     {pc}


@ r0: data
@ puts r0 to pio state machine 0 and blocks if the fifo is full
pio0_sm0_put_blocking:
    @ if (pio->fstat & (1u << (PIO_FSTAT_TXFULL_LSB + sm))) != 0
    ldr     r2, pio0_base
    ldr     r2, [r2, #0x004]         @ pio0 fifo status register
    mov     r1, #1
    lsl     r1, #16                  @ TXFULL
    and     r2, r1
    bne     pio0_sm0_put_blocking    @ loop while fifo full
    @ pio->txf[sm] = data;
    ldr     r2, pio0_base
    str     r0, [r2, #0x010]         @ TXF0
    bx      lr


@ params:
@   r0: encoded coords (byte)
@ returns:
@   r0: x coord
@   r1: y coord
byte_to_coords:
    lsr     r1, r0, #4      @ y coord
    mov     r3, #0x0f
    and     r0, r3          @ x coord
    bx      lr


@ params:
@   r0: x coord
@   r1: y coord
@ returns:
@   r0: encoded coords (byte)
coords_to_byte:
    lsl     r1, #4
    orr     r0, r1
    bx      lr


get_random_byte:
    push    { r4 }
    mov     r4, #8
    mov     r0, #0
1:
    lsl     r0, #1
    ldr     r3, rosc_base
    ldr     r2, [r3, #0x1c]
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    mov     r1, #1
    and     r2, r1
    orr     r0, r2
    sub     r4, #1
    bne     1b
    pop     { r4 }
    bx      lr


.align 4
rosc_base: .word 0x40060000
pio0_base: .word 0x50200000
