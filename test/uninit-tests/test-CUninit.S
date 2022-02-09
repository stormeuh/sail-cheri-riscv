#include "test_macros.h"

        RVTEST_RV64U
        RVTEST_CODE_BEGIN
        cspecialrw ct0, pcc, c0

test_prepare:
        cspecialrw cs0, ddc, c0

test_uninit: # test if CUninit sets the uninit bit
        li gp, 1
        cuninit ct0, cs0
        cgetuninit t0, ct0
        beq t0, zero, test_fail

# to enforce throwing of exceptions on each instruction, jump to fail is
# interleaved the exception handler will advance the pc past this jump
#
# test for exception when uninitializing a sealed capability
test_sealed:
        li gp, 2
        csealentry cs0, cs0
        cuninit cs0, cs0
        j test_fail

# test for exception when uninitializing something which is not a capability
test_untagged:
        li gp, 3
        li s0, 0
        cuninit cs0, cs0
        j test_fail

test_success:
        RVTEST_PASS

test_fail:
        RVTEST_FAIL

mtvec_handler: # handle exception thrown by test_s
        csrrc t0, mtval, zero
        li t1, 2
        li t2, 3
        beq gp, t1, handle_seal
        beq gp, t2, handle_untagged
        j test_fail

handle_seal:
        li t1, 0b0100000011  # register cs0, exception code 3 (SealViolation)
        beq t0, t1, mtval_return
        j test_fail

handle_untagged:
        li t1, 0b0100000010 # register cs0, exception code 2 (TagViolation)
        beq t0, t1, mtval_return
        j test_fail

mtval_return:
        csrrc t0, mepc, zero
        addi t0, t0, 8 # advance pc 2 instructions to skip jump to fail
        csrrw zero, mepc, t0
        mret


       .align 5
        .global tohost
tohost: .dword 0
