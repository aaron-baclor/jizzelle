# Aaron Jori Baclor
# Raphael Anton Felix

.data
board:       .word 0,0,0, 0,0,0, 0,0,0
press_count: .word 0
game_over:   .asciz "Game over.\n"
win_msg:     .asciz "Congratulations! You have reached the 512 tile!\n"
inbuf:       .byte 0
newline:     .asciz "\n"
enter_move:  .asciz "Enter a move:\n"

.text
.globl main

.equ KEY_W, 119
.equ KEY_A, 97
.equ KEY_S, 115
.equ KEY_D, 100
.equ KEY_X, 120
.equ KEY_CAPITAL_X, 88
.equ KEY_1, 49
.equ KEY_2, 50

main:
new_game:
    la    t0, press_count
    lw    t1, 0(t0)
    li    t2, 9
    rem   t3, t1, t2
    
    la    t0, board
    slli  t4, t3, 2
    add   t4, t0, t4
    li    t5, 2
    sw    t5, 0(t4)
    
    jal   ra, print_board
    j     game_start
    

read_config_loop:
    li   t5, 0      
    li   a5, 0       

read_number:
    li   a0, 0
    la   a1, inbuf
    li   a2, 1
    li   a7, 63
    ecall

    lb   t6, 0(a1)   

    li   a3, 10    
    beq  t6, a3, maybe_store

    li   a3, 48  
    sub  t6, t6, a3   
    li   a3, 10
    mul  t5, t5, a3
    add  t5, t5, t6
    li   a5, 1      
    j    read_number

maybe_store:
    beq  a5, x0, read_number

store_num:
    slli t3, t1, 2
    add  t3, t0, t3
    sw   t5, 0(t3)

    addi t1, t1, 1
    blt  t1, t2, read_config_loop

    jal  ra, print_board
    j    game_start

game_start:
    la    a0, enter_move
    li    a7, 4
    ecall

main_loop:
    la    t0, press_count
    lw    t1, 0(t0)
    addi  t1, t1, 1
    sw    t1, 0(t0)

    li    a0, 0
    la    a1, inbuf
    li    a2, 1
    li    a7, 63
    ecall
    beq   a0, x0, main_loop

    la    t0, inbuf
    lb    t1, 0(t0)

    li    t2, KEY_W
    beq   t1, t2, handle_w

    li    t2, KEY_A
    beq   t1, t2, handle_a

    li    t2, KEY_S
    beq   t1, t2, handle_s

    li    t2, KEY_D
    beq   t1, t2, handle_d

    li    t2, KEY_X
    beq   t1, t2, handle_exit

    li    t2, KEY_CAPITAL_X        
    beq   t1, t2, handle_exit


    j     main_loop

handle_w:
    jal   ra, resolve_up
    beq   a0, x0, main_loop
    jal   ra, apply_up
    j     after_move

handle_a:
    jal   ra, resolve_left
    beq   a0, x0, main_loop
    jal   ra, apply_left
    j     after_move

handle_s:
    jal   ra, resolve_down
    beq   a0, x0, main_loop
    jal   ra, apply_down
    j     after_move

handle_d:
    jal   ra, resolve_right
    beq   a0, x0, main_loop
    jal   ra, apply_right
    j     after_move

after_move:
    jal   ra, check_win
    bne   a0, x0, handle_win
    
    jal   ra, spawn_tile
    
    jal   ra, print_board
    
    jal   ra, check_game_over
    bne   a0, x0, handle_game_over
    
    j     main_loop

handle_win:
    jal   ra, print_board
    la    a0, win_msg
    li    a7, 4
    ecall
    j     handle_exit

handle_game_over:
    la    a0, game_over
    li    a7, 4
    ecall
    j     handle_exit

handle_exit:
    li    a7, 10
    ecall


# spawn
spawn_tile:
    la    t0, board
    li    t1, 9
    li    t2, 0         

count_empty_loop:
    lw    t3, 0(t0)
    bne   t3, x0, ce_next
    addi  t2, t2, 1
    
ce_next:
    addi  t0, t0, 4
    addi  t1, t1, -1
    bne   t1, x0, count_empty_loop

    beq   t2, x0, spawn_done   

    la    t0, press_count
    lw    t1, 0(t0)
    mv    t3, t1      
    mv    t4, t2          

mod_loop:
    blt   t3, t4, mod_done
    sub   t3, t3, t4
    j     mod_loop

mod_done:
    la    t0, board
    li    t1, 9

spawn_scan:
    lw    t5, 0(t0)
    bne   t5, x0, ss_next

    beq   t3, x0, spawn_here
    addi  t3, t3, -1

ss_next:
    addi  t0, t0, 4
    addi  t1, t1, -1
    bne   t1, x0, spawn_scan
    j     spawn_done

spawn_here:
    li    t5, 2
    sw    t5, 0(t0)

spawn_done:
    jr    ra

# check win
check_win:
    la    t0, board
    li    t1, 0
    li    t2, 9
    li    t3, 512

win_loop:
    slli  t4, t1, 2
    add   t4, t0, t4
    lw    t5, 0(t4)
    beq   t5, t3, win_found
    addi  t1, t1, 1
    blt   t1, t2, win_loop
    li    a0, 0
    jr    ra

win_found:
    li    a0, 1
    jr    ra


# check game over
check_game_over:
    addi  sp, sp, -4
    sw    ra, 0(sp)
    
    la    t0, board
    li    t1, 0
    li    t2, 9

go_empty_loop:
    slli  t3, t1, 2
    add   t3, t0, t3
    lw    t4, 0(t3)
    beq   t4, x0, go_not_over  
    addi  t1, t1, 1
    blt   t1, t2, go_empty_loop

    jal   ra, resolve_left
    bne   a0, x0, go_not_over
    jal   ra, resolve_right
    bne   a0, x0, go_not_over
    jal   ra, resolve_up
    bne   a0, x0, go_not_over
    jal   ra, resolve_down
    bne   a0, x0, go_not_over

    li    a0, 1
    lw    ra, 0(sp)
    addi  sp, sp, 4
    jr    ra

go_not_over:
    li    a0, 0
    lw    ra, 0(sp)
    addi  sp, sp, 4
    jr    ra

# print
print_board:
    addi  sp, sp, -4
    sw    ra, 0(sp)
    
    li    a0, LED_MATRIX_0_BASE
    la    s0, board
    li    s1, 0      

pb_loop:
    slli  t0, s1, 2
    add   t0, s0, t0
    lw    t1, 0(t0)      
    
    li    t2, 3
    div   t3, s1, t2      
    rem   t4, s1, t2      

    slli  t3, t3, 1     
    li    t5, 6
    mul   t3, t3, t5 
    slli  t4, t4, 1    
    add   t3, t3, t4 
    slli  t3, t3, 2    
    add   a1, a0, t3  

    mv    a2, t1      
    jal   ra, draw_tile
    
    addi  s1, s1, 1
    li    t0, 9
    blt   s1, t0, pb_loop

    lw    ra, 0(sp)
    addi  sp, sp, 4
    jr    ra

draw_tile:
    li    t0, 0x000000   
    li    t1, 0xFF0000 
    li    t2, 0x00FF00   
    li    t3, 0xFFFF00 
    
    beq   a2, x0, dt_0
    li    t4, 2
    beq   a2, t4, dt_2
    li    t4, 4
    beq   a2, t4, dt_4
    li    t4, 8
    beq   a2, t4, dt_8
    li    t4, 16
    beq   a2, t4, dt_16
    li    t4, 32
    beq   a2, t4, dt_32
    li    t4, 64
    beq   a2, t4, dt_64
    li    t4, 128
    beq   a2, t4, dt_128
    li    t4, 256
    beq   a2, t4, dt_256
    li    t4, 512
    beq   a2, t4, dt_512
    jr    ra

dt_0:
    sw    t0, 0(a1)     
    sw    t0, 4(a1)
    sw    t0, 24(a1)
    sw    t0, 28(a1)
    jr    ra

dt_2:
    sw    t1, 0(a1)      
    sw    t0, 4(a1)
    sw    t0, 24(a1)
    sw    t0, 28(a1)
    jr    ra

dt_4:
    sw    t1, 0(a1)       
    sw    t0, 4(a1)
    sw    t0, 24(a1)
    sw    t1, 28(a1)   
    jr    ra

dt_8:
    sw    t1, 0(a1)      
    sw    t1, 4(a1)      
    sw    t0, 24(a1)
    sw    t1, 28(a1)     
    jr    ra

dt_16:
    sw    t1, 0(a1)     
    sw    t1, 4(a1)
    sw    t1, 24(a1)
    sw    t1, 28(a1)
    jr    ra

dt_32:
    sw    t2, 0(a1)     
    sw    t0, 4(a1)
    sw    t0, 24(a1)
    sw    t0, 28(a1)
    jr    ra

dt_64:
    sw    t2, 0(a1)    
    sw    t0, 4(a1)
    sw    t0, 24(a1)
    sw    t2, 28(a1)   
    jr    ra

dt_128:
    sw    t2, 0(a1)      
    sw    t2, 4(a1)         
    sw    t0, 24(a1)
    sw    t2, 28(a1)     
    jr    ra

dt_256:
    sw    t2, 0(a1)      
    sw    t2, 4(a1)
    sw    t2, 24(a1)
    sw    t2, 28(a1)
    jr    ra

dt_512:
    sw    t3, 0(a1)       
    sw    t3, 4(a1)
    sw    t3, 24(a1)
    sw    t3, 28(a1)
    jr    ra
    
one_digit:
    li    a0, 32
    li    a7, 11
    ecall
    ecall
    mv    a0, t0
    li    a7, 1
    ecall
    j     print_cell_done

two_digits:
    li    a0, 32
    li    a7, 11
    ecall
    mv    a0, t0
    li    a7, 1
    ecall
    j     print_cell_done

print_cell_blank:
    li    a0, 32
    li    a7, 11
    ecall
    ecall
    ecall

print_cell_done:
    lw    t2, 0(sp)
    lw    t1, 4(sp)
    lw    t0, 8(sp)
    lw    ra, 12(sp)
    addi  sp, sp, 16
    jr    ra

# layer 2
r_valid:
    li   a0, 1
    jr   ra

resolve_left:
    la   t0, board
    li   t6, 3     
    li   t1, 0     

rl_row:
    li   t2, 0      
    li   t3, 0      
    li   t4, 0     

rl_col:
    mul  t5, t1, t6
    add  t5, t5, t4
    slli t5, t5, 2
    add  t5, t5, t0
    lw   t5, 0(t5)

    beq  t5, x0, rl_zero

    bne  t2, x0, r_valid      
    beq  t3, x0, rl_setlast
    beq  t5, t3, r_valid 
    mv   t3, t5
    j    rl_next

rl_setlast:
    mv   t3, t5
    j    rl_next

rl_zero:
    li   t2, 1         

rl_next:
    addi t4, t4, 1
    blt  t4, t6, rl_col

    addi t1, t1, 1
    blt  t1, t6, rl_row

    li   a0, 0
    jr   ra

resolve_right:
    la   t0, board
    li   t6, 3
    li   t1, 0    

rr_row:
    li   t2, 0    
    li   t3, 0    
    li   t4, 2     

rr_col:
    mul  t5, t1, t6
    add  t5, t5, t4
    slli t5, t5, 2
    add  t5, t5, t0
    lw   t5, 0(t5)

    beq  t5, x0, rr_zero

    bne  t2, x0, r_valid      
    beq  t3, x0, rr_setlast
    beq  t5, t3, r_valid  
    mv   t3, t5
    j    rr_next

rr_setlast:
    mv   t3, t5
    j    rr_next

rr_zero:
    li   t2, 1

rr_next:
    addi t4, t4, -1
    bge  t4, x0, rr_col

    addi t1, t1, 1
    blt  t1, t6, rr_row

    li   a0, 0
    jr   ra

resolve_up:
    la   t0, board
    li   t6, 3
    li   t1, 0 

ru_col:
    li   t2, 0   
    li   t3, 0      
    li   t4, 0  

ru_row:
    mul  t5, t4, t6
    add  t5, t5, t1
    slli t5, t5, 2
    add  t5, t5, t0
    lw   t5, 0(t5)

    beq  t5, x0, ru_zero

    bne  t2, x0, r_valid
    beq  t3, x0, ru_setlast
    beq  t5, t3, r_valid
    mv   t3, t5
    j    ru_next

ru_setlast:
    mv   t3, t5
    j    ru_next

ru_zero:
    li   t2, 1

ru_next:
    addi t4, t4, 1
    blt  t4, t6, ru_row

    addi t1, t1, 1
    blt  t1, t6, ru_col

    li   a0, 0
    jr   ra

resolve_down:
    la   t0, board
    li   t6, 3
    li   t1, 0  

rd_col:
    li   t2, 0     
    li   t3, 0    
    li   t4, 2    

rd_row:
    mul  t5, t4, t6
    add  t5, t5, t1
    slli t5, t5, 2
    add  t5, t5, t0
    lw   t5, 0(t5)

    beq  t5, x0, rd_zero

    bne  t2, x0, r_valid
    beq  t3, x0, rd_setlast
    beq  t5, t3, r_valid
    mv   t3, t5
    j    rd_next

rd_setlast:
    mv   t3, t5
    j    rd_next

rd_zero:
    li   t2, 1

rd_next:
    addi t4, t4, -1
    bge  t4, x0, rd_row

    addi t1, t1, 1
    blt  t1, t6, rd_col

    li   a0, 0
    jr   ra

# layer 3
apply_left:
    addi sp, sp, -8
    sw   s0, 4(sp)
    sw   s1, 0(sp)

    la   t0, board
    li   t6, 3
    li   t1, 0

al_row:
    li   t2, 0
    li   t3, 0
    li   t4, 0
    li   s0, 0 
al_read:
    mul  t5, t1, t6
    add  t5, t5, t2
    slli t5, t5, 2
    add  t5, t5, t0
    lw   s1, 0(t5)

    beq  s1, x0, al_next
    beq  t4, x0, al_set
    bne  s0, x0, al_write
    beq  s1, t4, al_merge

al_write:
    mul  t5, t1, t6
    add  t5, t5, t3
    slli t5, t5, 2
    add  t5, t5, t0
    sw   t4, 0(t5)

    addi t3, t3, 1
    mv   t4, s1
    li   s0, 0
    j    al_next

al_set:
    mv   t4, s1
    li   s0, 0
    j    al_next

al_merge:
    slli t4, t4, 1
    mul  t5, t1, t6
    add  t5, t5, t3
    slli t5, t5, 2
    add  t5, t5, t0
    sw   t4, 0(t5)

    addi t3, t3, 1
    li   t4, 0
    li   s0, 1

al_next:
    addi t2, t2, 1
    blt  t2, t6, al_read

    beq  t4, x0, al_zero
    mul  t5, t1, t6
    add  t5, t5, t3
    slli t5, t5, 2
    add  t5, t5, t0
    sw   t4, 0(t5)
    addi t3, t3, 1

al_zero:
    blt  t3, t6, al_fill
    j    al_next_row

al_fill:
    mul  t5, t1, t6
    add  t5, t5, t3
    slli t5, t5, 2
    add  t5, t5, t0
    sw   x0, 0(t5)
    addi t3, t3, 1
    j    al_zero

al_next_row:
    addi t1, t1, 1
    blt  t1, t6, al_row

    lw   s1, 0(sp)
    lw   s0, 4(sp)
    addi sp, sp, 8
    jr   ra


apply_right:
    addi sp, sp, -8
    sw   s0, 4(sp)
    sw   s1, 0(sp)

    la   t0, board
    li   t6, 3
    li   t1, 0

ar_row:
    li   t2, 2
    li   t3, 2
    li   t4, 0
    li   s0, 0

ar_read:
    mul  t5, t1, t6
    add  t5, t5, t2
    slli t5, t5, 2
    add  t5, t5, t0
    lw   s1, 0(t5)

    beq  s1, x0, ar_next
    beq  t4, x0, ar_set
    bne  s0, x0, ar_write
    beq  s1, t4, ar_merge

ar_write:
    mul  t5, t1, t6
    add  t5, t5, t3
    slli t5, t5, 2
    add  t5, t5, t0
    sw   t4, 0(t5)

    addi t3, t3, -1
    mv   t4, s1
    li   s0, 0
    j    ar_next

ar_set:
    mv   t4, s1
    li   s0, 0
    j    ar_next

ar_merge:
    slli t4, t4, 1
    mul  t5, t1, t6
    add  t5, t5, t3
    slli t5, t5, 2
    add  t5, t5, t0
    sw   t4, 0(t5)

    addi t3, t3, -1
    li   t4, 0
    li   s0, 1

ar_next:
    addi t2, t2, -1
    bge  t2, x0, ar_read

    beq  t4, x0, ar_zero
    mul  t5, t1, t6
    add  t5, t5, t3
    slli t5, t5, 2
    add  t5, t5, t0
    sw   t4, 0(t5)
    addi t3, t3, -1

ar_zero:
    bge  t3, x0, ar_fill
    j    ar_next_row

ar_fill:
    mul  t5, t1, t6
    add  t5, t5, t3
    slli t5, t5, 2
    add  t5, t5, t0
    sw   x0, 0(t5)
    addi t3, t3, -1
    j    ar_zero

ar_next_row:
    addi t1, t1, 1
    blt  t1, t6, ar_row

    lw   s1, 0(sp)
    lw   s0, 4(sp)
    addi sp, sp, 8
    jr   ra

apply_up:
    addi sp, sp, -8
    sw   s0, 4(sp)
    sw   s1, 0(sp)

    la   t0, board
    li   t6, 3
    li   t1, 0

au_col:
    li   t2, 0
    li   t3, 0
    li   t4, 0
    li   s0, 0

au_read:
    mul  t5, t2, t6
    add  t5, t5, t1
    slli t5, t5, 2
    add  t5, t5, t0
    lw   s1, 0(t5)

    beq  s1, x0, au_next
    beq  t4, x0, au_set
    bne  s0, x0, au_write
    beq  s1, t4, au_merge

au_write:
    mul  t5, t3, t6
    add  t5, t5, t1
    slli t5, t5, 2
    add  t5, t5, t0
    sw   t4, 0(t5)

    addi t3, t3, 1
    mv   t4, s1
    li   s0, 0
    j    au_next

au_set:
    mv   t4, s1
    li   s0, 0
    j    au_next

au_merge:
    slli t4, t4, 1
    mul  t5, t3, t6
    add  t5, t5, t1
    slli t5, t5, 2
    add  t5, t5, t0
    sw   t4, 0(t5)

    addi t3, t3, 1
    li   t4, 0
    li   s0, 1

au_next:
    addi t2, t2, 1
    blt  t2, t6, au_read

    beq  t4, x0, au_zero
    mul  t5, t3, t6
    add  t5, t5, t1
    slli t5, t5, 2
    add  t5, t5, t0
    sw   t4, 0(t5)
    addi t3, t3, 1

au_zero:
    blt  t3, t6, au_fill
    j    au_next_col

au_fill:
    mul  t5, t3, t6
    add  t5, t5, t1
    slli t5, t5, 2
    add  t5, t5, t0
    sw   x0, 0(t5)
    addi t3, t3, 1
    j    au_zero

au_next_col:
    addi t1, t1, 1
    blt  t1, t6, au_col

    lw   s1, 0(sp)
    lw   s0, 4(sp)
    addi sp, sp, 8
    jr   ra

apply_down:
    addi sp, sp, -8
    sw   s0, 4(sp)
    sw   s1, 0(sp)

    la   t0, board
    li   t6, 3
    li   t1, 0

ad_col:
    li   t2, 2
    li   t3, 2
    li   t4, 0
    li   s0, 0

ad_read:
    mul  t5, t2, t6
    add  t5, t5, t1
    slli t5, t5, 2
    add  t5, t5, t0
    lw   s1, 0(t5)

    beq  s1, x0, ad_next
    beq  t4, x0, ad_set
    bne  s0, x0, ad_write
    beq  s1, t4, ad_merge

ad_write:
    mul  t5, t3, t6
    add  t5, t5, t1
    slli t5, t5, 2
    add  t5, t5, t0
    sw   t4, 0(t5)

    addi t3, t3, -1
    mv   t4, s1
    li   s0, 0
    j    ad_next

ad_set:
    mv   t4, s1
    li   s0, 0
    j    ad_next

ad_merge:
    slli t4, t4, 1
    mul  t5, t3, t6
    add  t5, t5, t1
    slli t5, t5, 2
    add  t5, t5, t0
    sw   t4, 0(t5)

    addi t3, t3, -1
    li   t4, 0
    li   s0, 1

ad_next:
    addi t2, t2, -1
    bge  t2, x0, ad_read

    beq  t4, x0, ad_zero
    mul  t5, t3, t6
    add  t5, t5, t1
    slli t5, t5, 2
    add  t5, t5, t0
    sw   t4, 0(t5)
    addi t3, t3, -1

ad_zero:
    bge  t3, x0, ad_fill
    j    ad_next_col

ad_fill:
    mul  t5, t3, t6
    add  t5, t5, t1
    slli t5, t5, 2
    add  t5, t5, t0
    sw   x0, 0(t5)
    addi t3, t3, -1
    j    ad_zero

ad_next_col:
    addi t1, t1, 1
    blt  t1, t6, ad_col

    lw   s1, 0(sp)
    lw   s0, 4(sp)
    addi sp, sp, 8
    jr   ra
