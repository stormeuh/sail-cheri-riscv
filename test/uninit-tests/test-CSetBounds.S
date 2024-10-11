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
        li s1, 0x4000
        csetbounds cs0, cs0, s1

test_setbounds_dropuninit:
        li gp, 1
        cuninit ct0, cs0
        cincoffset ct0, ct0, 32
        csetbounds ct0, ct0, 64
        cgetuninit t1, ct0
        bgtz t1, test_fail

test_setbounds_inexact_uninit:
        li gp, 2
        cincoffset ct0, cs0, 15
        addi t1, s1, -15
        cuninit ct0, ct0
        csetbounds ct0, ct0, t1
        j test_fail

test_setbounds_inexact_normal:
        li gp, 3
        cincoffset ct0, cs0, 15
        addi t1, s1, -15
        csetbounds ct0, ct0, t1

test_success:
        RVTEST_PASS

test_fail:
        RVTEST_FAIL

# exception handler instructions
# inspects error code to ensure it is correct
mtvec_handler:
        csrrc t0, mtval, zero # load error value
        li t1, 2
        beq gp, t1, handle_inexact
        j test_fail

handle_inexact:
        li t1, 0b0010111101    # register ct0 (x5), exception code 28 (UninitViolation)
        bne t0, t1, test_fail
        j mtval_return

mtval_return:
        csrrc t0, mepc, zero
        addi t0, t0, 8         # advance pc 2 instructions to skip jump to fail
        csrrw zero, mepc, t0
        mret

.align 5
.global tohost
tohost: .dword 0
