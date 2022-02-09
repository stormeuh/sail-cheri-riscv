#include "test_macros.h"

# clear registers, ininialize test infrastructure and retrieve pcc
        RVTEST_RV64U
        RVTEST_CODE_BEGIN

# test if cdropuninit correctly clears uninit bit
test_drop:
        li gp, 1
        cspecialrw cs0, ddc, c0
        cuninit cs0, cs0
        cdropuninit cs0, cs0
        cgetuninit t0, cs0
        bnez t0, test_fail

# to enforce throwing of exceptions on each instruction, jump to fail is interleaved
#   the exception handler will advance the pc past this jump
#
# test exception is thrown when operand capability is not uninitialized
test_not_uninit:
        li gp, 2
        cdropuninit cs0, cs0
        j test_fail

# test exception is thrown when cap is sealed
test_sealed:
        li gp, 3
        cuninit cs0, cs0
        csealentry cs0, cs0
        cdropuninit cs0, cs0
        j test_fail

# test exception is thrown when tag does not indicate a capability is present
test_untagged:
        li gp, 4
        li s0, 0
        cdropuninit cs0, cs0
        j test_fail

test_success:
        RVTEST_PASS

test_fail:
        RVTEST_FAIL

# exception handler
# inspects error code to ensure it is correct
mtvec_handler:
        csrrc t0, mtval, zero
        li t1, 2
        li t2, 3
        li t3, 4
        beq gp, t1, handle_not_uninit
        beq gp, t2, handle_seal
        beq gp, t3, handle_untagged
        j test_fail

handle_not_uninit:
        li t1, 0b0100011101  # register cs0, exception code 29 (UninitLoadViolation)
        beq t0, t1, mtval_return
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
