
.global main
.global gpio_irq_handler

.equ KEY_LEFT, 10
.equ KEY_DOWN, 11
.equ KEY_UP, 12
.equ KEY_RIGHT, 13

.equ DIR_LEFT, 0
.equ DIR_DOWN, 1
.equ DIR_UP, 2
.equ DIR_RIGHT, 3

.equ SNAKE_INITIAL_LENGTH, 3

.thumb_func
main:
    bl      stdio_init_all
    bl      initialize_hardware
    ldr     r5, =snake
    mov     r0, #3
    mov     r1, #1
    bl      coords_to_byte
    strb    r0, [r5]
    mov     r0, #0
    strb    r0, [r5, #1]

    mov     r0, #3
    mov     r1, #2
    bl      coords_to_byte
    strb    r0, [r5, #2]
    mov     r0, #1
    strb    r0, [r5, #3]

    mov     r0, #3
    mov     r1, #3
    bl      coords_to_byte
    strb    r0, [r5, #4]
    mov     r0, #2
    strb    r0, [r5, #5]

    mov     r0, #(SNAKE_INITIAL_LENGTH -1)
    ldr     r6, =head_index
    strb    r0, [r6]

    mov     r7, #SNAKE_INITIAL_LENGTH   @ snake length
    mov     r0, r5
    mov     r1, r7
    bl      update_treat_position


loop:
    ldr     r4, =direction
    ldrb    r4, [r4]

    ldrb    r3, [r6]
    lsl     r3, #1
    ldrb    r0, [r5, r3]          @ head.coords
    bl      byte_to_coords        @ r0: head_x, r1: head_y

@main_switch_statement:
    cmp     r4, #DIR_LEFT
    beq     main_switch_left
    cmp     r4, #DIR_DOWN
    beq     main_switch_down
    cmp     r4, #DIR_UP
    beq     main_switch_up
    cmp     r4, #DIR_RIGHT
    beq     main_switch_right
    b       main_end_switch
main_switch_left:
    sub     r0, #1 
    b       main_end_switch
main_switch_down:
    sub     r1, #1 
    b       main_end_switch
main_switch_up:
    add     r1, #1 
    b       main_end_switch
main_switch_right:
    add     r0, #1 
main_end_switch:
    bl      coords_to_byte        @ r0: (head_x, head_y)

    @ check if new head is a treat or a wall tile.
    mov     r4, r0

    bl      byte_to_coords
    bl      coords_to_tile_id
    bl      is_treat_tile
    cmp     r0, #0          @ if treat tile -> increase length and get new treat pos
    beq     1f
    mov     r0, r5
    mov     r1, r7
    bl      update_treat_position

    @ prepare a new snake node
    lsl     r3, r7, #1
    add     r3, r5
    strb    r4, [r3]       @ write new head coords
    strb    r7, [r3, #1]   @ set new_head.tail_counter

    strb    r7, [r6]       @ point head_index to this new head
    add     r7, #1         @ increase snake length
    b       main_ready_to_show_scene

1:  @ TODO: check if new head is a wall tile

    @ overwrite current tail with new head and update
    @ iterate over the snake array and decrease tail_counter ↓↓
        @ if snake[i].tail_counter == 0
            @ set tail_index = i
            @ set snake[i].tail_counter = snake_length -1
        @ else
            @ snake[i].tail_counter -= 1
    mov     r0, #0          @ i
main_tail_counter_loop:
    lsl     r1, r0, #1
    add     r1, r5, r1      @ &snake[i]
    ldrb    r2, [r1, #1]    @ snake[i].tail_counter
    cmp     r2, #0
    bne     1f
    mov     r3, r0          @ tail_index = i

    sub     r2, r7, #1
    strb    r2, [r1, #1]    @ snake[i].tail_counter = snake_length -1
    b main_tail_counter_loop_condition
1:  
    sub     r2, #1
    strb    r2, [r1, #1] 
main_tail_counter_loop_condition:
    add     r0, #1
    cmp     r0, r7          @ i < snake_length
    blo     main_tail_counter_loop
@ main_tail_counter_loop_end
    @ tail_index: r3
    lsl     r0, r3, #1
    strb    r4, [r5, r0]       @ snake[tail_idx].coords = new_head.coords
    strb    r3, [r6]           @ new head index

main_ready_to_show_scene:
    mov     r0, r5
    mov     r1, r7
    bl      show_scene

    mov     r0, #170
    bl      sleep_ms
    b loop


@ r0: snake 
@ r1: snake_length
show_scene:
    push    {r4, r5, r6, r7, lr}
    mov     r4, #0       @ loop counter
    mov     r5, r0       @ snake
    mov     r6, r1
    mov     r7, #1
show_scene_for_loop:
    cmp     r4, #255     @ repeat for 255+1 = 256 times
    bhi     show_scene_for_loop_end
@show_scene_if_statement:
    mov     r0, r4
    bl      is_wall_tile
    cmp     r0, #0
    beq     show_scene_else_if_1
    ldr     r0, wall_color
    b       show_scene_endif
show_scene_else_if_1:
    mov     r0, r4
    mov     r1, r5
    mov     r2, r6
    bl      is_snake_tile
    cmp     r0, #1
    bne     show_scene_else_if_2
    ldr     r0, snake_color
    b       show_scene_endif
show_scene_else_if_2:
    mov     r0, r4
    bl      is_treat_tile
    cmp     r0, #0
    beq     show_scene_else
    ldr     r0, treat_color
    b       show_scene_endif
show_scene_else:
    mov     r0, #0 
show_scene_endif:
    bl      pio0_sm0_put_blocking
    add     r4, #1
    b       show_scene_for_loop
show_scene_for_loop_end:
    pop     {r4-r7, pc}

.align 4
wall_color: .word (0x000100 << 8)
snake_color: .word (0x010000 << 8)
treat_color: .word (0x010100 << 8)


@ r0: tile_id
is_wall_tile:
    @ if (tile_id % 16) or (tile_id+1 % 16) or (tile_id < 16) or (tile_id >= 240) -> the tile is a wall
    mov     r3, #0x0f
    and     r3, r0
    beq     is_wall_tile_true    @ least significant bits 0000
    cmp     r3, #0xf
    beq     is_wall_tile_true    @ least significant bits 1111
    cmp     r0, #16
    blo     is_wall_tile_true    @ less than 16
    cmp     r0, #240
    bhs     is_wall_tile_true    @ greater or equal to 240 
    @ false
    mov     r0, #0
    bx      lr
is_wall_tile_true: 
    mov     r0, #1
    bx      lr

@ r0, snake
@ r1, snake_length
@ updates treat_postition_x and treat_postition_y
@ no return value
update_treat_position:
    push    {r4-r7, lr}
    mov     r6, r0
    mov     r7, r1
1:  bl      get_random_byte
    bl      byte_to_coords
    mov     r4, r0
    mov     r5, r1
    bl      coords_to_tile_id
    bl      is_wall_tile
    cmp     r0, #0
    bne     1b
    mov     r0, r4
    mov     r1, r5
    bl      coords_to_tile_id
    mov     r1, r6
    mov     r2, r7
    bl      is_snake_tile
    cmp     r0, #0
    bne     1b
    ldr     r2, =treat_postition_x
    strb    r4, [r2]
    ldr     r2, =treat_postition_y
    strb    r5, [r2]
    pop     {r4-r7, pc}

@   r0: x coord
@   r1: y coord
@ returns:
@   r0: led matrix tile id
coords_to_tile_id:
    mov     r2, #1
    tst     r1, r2          @ test if row index is odd...
    beq     1f
    mov     r2, #15
    sub     r0, r2, r0      @ ...and "mirror" the x coord if it is
1:  mov     r2, #16
    mul     r1, r2
    add     r0, r1
    bx      lr



@ r0: tile_id
@ r1: snake
@ r2: snake_length
is_snake_tile:
    push    {r4-r7, lr}
    mov     r4, r0      @ tile_id
    mov     r5, r2
    mov     r6, #0      @ i
    mov     r7, r1
is_snake_tile_for_loop:
    mov     r0, #0      @ not a snake tile -> return 0
    cmp     r6, r5      @ i >= snake_length ?
    bhs     is_snake_tile_for_loop_end
    lsl     r1, r6, #1
    ldrb    r0, [r7, r1]     @ r0 = snake[i].coords
    bl      byte_to_coords   @ r0: x, r1: y
    bl      coords_to_tile_id
    cmp     r4, r0          @ snake_tile_id != tile_id
    bne     2f
@is_snake_tile_true:
    mov     r0, #1
    b       is_snake_tile_for_loop_end
2:  add     r6, #1
    b       is_snake_tile_for_loop
is_snake_tile_for_loop_end:
    pop     {r4-r7, pc}


@ r0: tile_id
is_treat_tile:
    push    {r4-r7, lr}
    mov     r4, r0  @ tile_id

    ldr     r0, =treat_postition_x
    ldrb    r0, [r0]
    ldr     r1, =treat_postition_y
    ldrb    r1, [r1]
    bl      coords_to_tile_id
    cmp     r4, r0
    beq     1f
    mov     r0, #0
    pop     {r4-r7, pc}
1:
    mov     r0, #1
    pop     {r4-r7, pc}

@ r0: pin
@ r1: event
.thumb_func
gpio_irq_handler:
    push    {lr}
@gpio_irq_handler_switch_statement:
    cmp     r0, #KEY_LEFT
    beq     gpio_irq_handler_switch_left
    cmp     r0, #KEY_UP
    beq     gpio_irq_handler_switch_up
    cmp     r0, #KEY_DOWN
    beq     gpio_irq_handler_switch_down
    cmp     r0, #KEY_RIGHT
    beq     gpio_irq_handler_switch_right
    b       gpio_irq_handler_end_switch
gpio_irq_handler_switch_left:
    ldr     r0, =direction
    mov     r1, #DIR_LEFT
    strb    r1, [r0]
    b       gpio_irq_handler_end_switch
gpio_irq_handler_switch_down:
    ldr     r0, =direction
    mov     r1, #DIR_DOWN
    strb    r1, [r0]
    b       gpio_irq_handler_end_switch
gpio_irq_handler_switch_up:
    ldr     r0, =direction
    mov     r1, #DIR_UP
    strb    r1, [r0]
    b       gpio_irq_handler_end_switch
gpio_irq_handler_switch_right:
    ldr     r0, =direction
    mov     r1, #DIR_RIGHT
    strb    r1, [r0]
gpio_irq_handler_end_switch:
    pop     {pc}


.data
@ snake: array of structs { coords: byte (x, y), tail_counter: byte)
snake: .space 400 
head_index: .byte 0
treat_postition_x: .byte 1
treat_postition_y: .byte 1
direction: .byte DIR_UP
print_num: .asciz "%d\n"

