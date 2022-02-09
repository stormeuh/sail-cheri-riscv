#include "test_macros.h"

# clear registers and ininialize test infrastructure
        RVTEST_RV64M
        RVTEST_CODE_BEGIN

# Construct a capabality of format:
#           |            |
# 0x1020    |------------| <- top
#           |            |
# 0x1010    |------------| <- cursor
#           |            |
# 0x1000    |------------| <- base (start of writable memory on sail)
#           |            |
# Install cap as ddc, preserve original ddc to restore upon error.
test_prepare:
        cspecialrw cs0, ddc, c0
        li t1, 0x1000
        csetaddr cs0, cs0, t1
        csetboundsimm cs0, cs0, 32
        addi t1, t1, 16
        csetaddr cs0, cs0, t1
        cuninit cs0, cs0
        cspecialrw cs11, ddc, cs0

# to enforce throwing of exceptions on each instruction, jump to fail is interleaved
#   the exception handler will advance the pc past this jump
#
# series of tests to ensure the memory reading part of atomic instructions
# comply with restrictions of uninitialized capabilities
test_swap:
        li gp, 1
        addi s2, s0, -16
        amoswap.w t0, s2, (s2)
        j test_fail
        amoswap.d t0, s2, (s2)
        j test_fail
        amoswap.c ct0, cs0, (s2)
        j test_fail

test_add:
        li gp, 2
        amoadd.w t0, s2, (s2)
        j test_fail
        amoadd.d t0, s2, (s2)
        j test_fail

test_and:
        li gp, 3
        amoand.w t0, s2, (s2)
        j test_fail
        amoand.d t0, s2, (s2)
        j test_fail

test_or:
        li gp, 4
        amoor.w t0, s2, (s2)
        j test_fail
        amoor.d t0, s2, (s2)
        j test_fail

test_xor:
        li gp, 5
        amoxor.w t0, s2, (s2)
        j test_fail
        amoxor.d t0, s2, (s2)
        j test_fail

test_max:
        li gp, 6
        amomax.w t0, s2, (s2)
        j test_fail
        amomax.d t0, s2, (s2)
        j test_fail

test_min:
        li gp, 7
        amomin.w t0, s2, (s2)
        j test_fail
        amomin.d t0, s2, (s2)
        j test_fail

test_success:
        cspecialrw c0, ddc, cs11
        RVTEST_PASS

test_fail:
        cspecialrw c0, ddc, cs11
        RVTEST_FAIL

# exception handler instructions
# inspects error code to ensure it is correct
mtvec_handler:
        cspecialrw cs1, ddc, cs11
        csrrc t0, mtval, zero  # load error value

handle_test_ddc:
        li t1, 0b10000111110      # SCR DDC, exception code 30 (UninitLoadViolation)
        beq t0, t1, mtval_return  # jump to return if correct
        j test_fail

mtval_return:
        csrrc t0, mepc, zero
        addi t0, t0, 8 # advance pc 2 instructions to skip jump to fail
        csrrw zero, mepc, t0
        cspecialrw c0, ddc, cs1
        mret


.align 5
.global tohost
tohost: .dword 0
