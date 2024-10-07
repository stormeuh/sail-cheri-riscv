#include "test_macros.h"

# clear registers and ininialize test infrastructure
        RVTEST_RV64M
        RVTEST_CODE_BEGIN

# Construct a capabality of format:
#         |            |
# 0x20    |------------| <- top
#         |            |
# 0x10    |------------| <- cursor
#         |            |
# 0x00    |------------| <- base
#         |            |
test_prepare:
        cspecialrw cs0, ddc, c0
        li t0, 0x4000
        csetbounds cs0, cs0, t0

test_setbounds_inexact:
        cincoffset cs0, cs0, 15
        addi t0, t0, -15
        cuninit cs0, cs0
        csetbounds cs0, cs0, t0
        cgetuninit t1, cs0
        bgtz t1, test_fail

test_success:
        RVTEST_PASS

test_fail:
        RVTEST_FAIL

# exception handler instructions
# inspects error code to ensure it is correct
mtvec_handler:
        csrrc t0, mtval, zero # load error value
        li t1, 3
        li t2, 4
        li t3, 5
        beq gp, t1, handle_sealed
        beq gp, t2, handle_length
        beq gp, t3, handle_tag
        j test_fail

handle_sealed:
        li t1, 0b0100100011    # register cs1, exception code 3 (SealViolation)
        bne t0, t1, test_fail
        j mtval_return

handle_length:
        li t1, 0b0100000001    # register cs0, exception code 1 (LengthViolation)
        bne t0, t1, test_fail
        j mtval_return

handle_tag:
        li t1, 0b0001100010    # register cgp, exception code 2 (TagViolation)
        bne t0, t1, test_fail

mtval_return:
        csrrc t0, mepc, zero
        addi t0, t0, 8         # advance pc 2 instructions to skip jump to fail
        csrrw zero, mepc, t0
        mret

# ca0 shrunk capabality
# a1  expected base
# a2  expected cursor
# a3  expected length
# indicates error code via gp, with codes 1x, 2x, 3x for base, cursor and length
# respectively
check_shrink:
        addi gp, gp, 10
        cgetbase t0, ca0
        bne t0, a1, test_fail
        addi gp, gp, 10
        cgetaddr t1, ca0
        bne t1, a2, test_fail
        addi gp, gp, 10
        cgetlen t2, ca0
        bne t2, a3, test_fail
        addi gp, gp, -30
        ret

.align 5
.global tohost
tohost: .dword 0
