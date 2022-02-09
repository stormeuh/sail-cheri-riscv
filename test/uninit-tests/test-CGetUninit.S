#include "test_macros.h"

# clear registers and ininialize test infrastructure
        RVTEST_RV64M
        RVTEST_CODE_BEGIN

test_prepare:
        cspecialrw cs0, ddc, c0
        cmove cs1, cs0
        cuninit cs1, cs1

# tests to see if uninit bit is read correctly
# test register is populated with incorrect value to ensure default is not
# interpreted as correct
test_not_uninit:
        li gp, 1
        li t0, 1
        cgetuninit t0, cs0
        bnez t0, test_fail

test_uninit:
        li gp, 2
        li t0, 0
        cgetuninit t0, cs1
        beqz t0, test_fail

# to enforce throwing of exceptions on each instruction, jump to fail is
# interleaved the exception handler will advance the pc past this jump
#
# test if exception is thrown when reading uninit bit from something that is not
# a capability
test_untagged:
        li gp, 3
        cgetuninit t0, ct0
        j test_fail

test_success:
        RVTEST_PASS

test_fail:
        RVTEST_FAIL

# exception handler
# inspects error code to ensure it is correct
mtvec_handler:
        csrrc t0, mtval, zero
        li t1, 3
        beq gp, t1, handle_untagged
        j test_fail

handle_untagged:
        li t1, 0b0010100010 # register ct0, exception code 2 (TagViolation)
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
