#include "test_macros.h"

# clear registers, ininialize test infrastructure and retrieve pcc
        RVTEST_RV64U
        RVTEST_CODE_BEGIN

# Construct a capabality of format:
#           |            |
# 0x1010    |------------| <- cursor, top
#           |            |
# 0x1000    |------------| <- base (start of writable memory on sail)
#           |            |
test_prepare:
        cspecialrw ca0, ddc, c0
        li t1, 0x1000
        csetaddr ca0, ca0, t1
        csetboundsimm ca0, ca0, 16
        addi t1, t1, 16
        csetaddr ca0, ca0, t1
        cuninit ca0, ca0

# First 5 tests store data/a capability
# Each test checks if the cursor is moved correctly
test_store_byte:
        li gp, 1
        sb gp, 0(a0)
        usb ca1, gp, ca0
        lb.cap t0, (ca1)
        bne gp, t0, test_fail
        li a2, 1
        jal cursor_move_correct

test_store_halfword:
        li gp, 2
        sh gp, 0(a0)
        ush ca1, gp, ca0
        lh.cap t0, (ca1)
        bne gp, t0, test_fail
        li a2, 2
        jal cursor_move_correct

test_store_word:
        li gp, 3
        sw gp, 0(a0)
        usw ca1, gp, ca0
        lw.cap t0, (ca1)
        bne gp, t0, test_fail
        li a2, 4
        jal cursor_move_correct

test_store_doubleword:
        li gp, 4
        sd gp, 0(a0)
        usd ca1, gp, ca0
        ld.cap t0, (ca1)
        bne gp, t0, test_fail
        li a2, 8
        jal cursor_move_correct

test_store_cap:
        li gp, 5
        sc ca0, 0(a0)
        usc ca1, ca0, ca0
        li a2, 16
        jal cursor_move_correct

# Tests if exception is thrown when using uninit store on not uninit cap
# j test_fail is interleaved to ensure instruction must throw (see exception handler)
test_store_not_uninit:
        li gp, 6
        cspecialrw cs0, ddc, c0
        usb cs0, zero, cs0
        j test_fail
        ush cs0, zero, cs0
        j test_fail
        usw cs0, zero, cs0
        j test_fail
        usd cs0, zero, cs0
        j test_fail
        usc cs0, c0, cs0
        j test_fail
        RVTEST_PASS

mtvec_handler: # handle exceptions thrown by tests
        csrrc s0, mtval, zero
        # only test 6 should throw an error
        li t0, 6
        beq gp, t0, handle_test6
        RVTEST_FAIL

handle_test6:
        li t1, 0b0100011101  # register cs0, exception code 29 (UninitViolation)
        beq s0, t1, mtval_return
        RVTEST_FAIL

mtval_return:
        # when returning, advance the program counter past the "j test_fail" instruction
        csrrc t0, mepc, zero
        addi t0, t0, 8
        csrrw zero, mepc, t0
        mret

test_fail:
        RVTEST_FAIL

# Check if the capability cursor moved the correct amount on write
# arguments:
# ca0 initial cap
# ca1 current cap
# a2 intended write
cursor_move_correct:
        cgetaddr t0, ca0
        cgetaddr t1, ca1
        sub t0, t0, t1
        bne t0, a2, test_fail
        ret

        .align 5
        .global tohost
tohost: .dword 0
