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
        csetboundsimm cs0, cs0, 32
        li s1, 16
        csetaddr cs0, cs0, s1

# following two tests check if capability base, address and length are modified
# correctly, using check_shrink defined at the end of the file
test_shrink:
        li gp, 1
        li a1, 8
        cshrink ca0, cs0, a1
        move a2, s1
        move a3, s1
        call check_shrink

test_shrinkimm:
        li gp, 2
        cshrinkimm ca0, cs0, 8
        call check_shrink


# test tag is cleared when cap is sealed
test_sealed:
        li gp, 3
        csealentry cs1, cs0
        cshrink cs2, cs1, gp
        cgettag t0, cs2
        bnez t0, test_fail
        cshrinkimm cs2, cs1, 3
        cgettag t0, cs2
        bnez t0, test_fail

# test exceptions are thrown when trying to increase authority of capability
test_length:
        li gp, 4
        csetaddr cs0, cs0, gp
        csetboundsimm cs0, cs0, 24
# try to lower base
        cshrink ct0, cs0, zero
        j test_fail
# no cshrinkimm because immediate is unsigned and thus cannot lower base
# try to raise top
        li t0, 32
        csetaddr cs0, cs0, t0
        cshrink ct0, cs0, gp
        j test_fail
        cshrinkimm ct0, cs0, 4
        j test_fail

test_large:
	li gp, 5
        cspecialrw cs0, ddc, c0
	li t0, 0x80000000
	li t1, 0x80000
        cincoffset cs0, cs0, t0
	csetbounds cs0, cs0, t0
	cincoffset cs0, cs0, t1
	cincoffsetimm cs0, cs0, -1
	cshrink ca0, cs0, 0
	li t2, 0x7FC00
	mv a1, t0
	add a2, t0, t1
	addi a2, a2, -1
	add a3, t0, t2
	call check_shrink

test_success:
        RVTEST_PASS

test_fail:
        RVTEST_FAIL

# exception handler instructions
# inspects error code to ensure it is correct
mtvec_handler:
        csrrc t0, mtval, zero # load error value
        li t2, 4
        beq gp, t2, handle_length
        j test_fail

handle_length:
        li t1, 0b0100000001    # register cs0, exception code 1 (LengthViolation)
        bne t0, t1, test_fail
        j mtval_return

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
        cgettop t2, ca0
        bne t2, a3, test_fail
        addi gp, gp, -30
        ret

.align 5
.global tohost
tohost: .dword 0
