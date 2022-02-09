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
# test conventional load
test_loaddata:
        li gp, 1
        lb t0, -8(s0)
        j test_fail
        lh t0, -8(s0)
        j test_fail
        lw t0, -8(s0)
        j test_fail
        ld t0, -8(s0)

# test explicit ddc data load
test_loaddata_ddc:
        li gp, 2
        addi s2, s0, -8
        lb.ddc t0, (s2)
        j test_fail
        lh.ddc t0, (s2)
        j test_fail
        lw.ddc t0, (s2)
        j test_fail
        ld.ddc t0, (s2)
        j test_fail

# test explicit ddc cap load
test_loadcap_ddc:
        li gp, 3
        lc.ddc ct0, (s2)
        j test_fail

# test atomic data load
test_loadresdata:
        li gp, 4
        lr.d t0, (s2)
        j test_fail
        lr.w t0, (s2)
        j test_fail

# test atomic ddc data load
test_loadresdata_ddc:
        li gp, 5
        lr.b.ddc t0, (s2)
        j test_fail
        lr.h.ddc t0, (s2)
        j test_fail
        lr.w.ddc t0, (s2)
        j test_fail
        lr.d.ddc t0, (s2)
        j test_fail

# test atomic cap load
test_loadrescap:
        li gp, 6
        lr.c.ddc ct0, (s2)
        j test_fail

test_success:
        cspecialrw c0, ddc, cs11
        RVTEST_PASS

test_fail:
        cspecialrw c0, ddc, cs11
        RVTEST_FAIL

# exception handler
# inspects error code to ensure it is correct
mtvec_handler:
        cspecialrw cs1, ddc, cs11
        csrrc t0, mtval, zero     # load error value

handle_test_ddc:
        li t1, 0b10000111110      # SCR DDC, exception code 30 (UninitLoadViolation)
        beq t0, t1, mtval_return  # jump to return if correct
        j test_fail

mtval_return:
        csrrc t0, mepc, zero
        addi t0, t0, 8            # advance pc 2 instructions to skip jump to fail
        csrrw zero, mepc, t0
        cspecialrw c0, ddc, cs1   # restore testing ddc
        mret

        .align 5
        .global tohost
tohost: .dword 0
