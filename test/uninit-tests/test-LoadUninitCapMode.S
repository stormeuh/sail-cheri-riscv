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
#
# Additionally the permissions are masked to unset the execute permission since
# cinvoke does not allow a data capability which is executable
prepare_cap:
        cspecialrw cs0, ddc, c0
        cmove ct0, cs0  # save ddc temporarily to seal with
        li t1, 0x1000
        csetaddr cs0, cs0, t1
        csetboundsimm cs0, cs0, 32
        addi t1, t1, 16
        csetaddr cs0, cs0, t1
        cuninit cs0, cs0
        li t1, 0xffffD
        candperm cs0, cs0, t1
        cseal cs0, cs0, ct0 # seal with ddc

prepare_pcc:
        cspecialrw cs1, pcc, c0
        la t1, test_load
        csetaddr cs1, cs1, t1
        li t2, 1
        csetflags cs1, cs1, t2
        cseal cs1, cs1, ct0
        cinvoke cs1, cs0  # use cinvoke to install pcc with capability mode flag

li t1, 1
cspecialrw ct0, pcc, cnull
cincoffsetimm ct0, ct0, 20
csetflags ct0, ct0, t1
jr.cap ct0 

# to enforce throwing of exceptions on each instruction, jump to fail is interleaved
#   the exception handler will advance the pc past this jump
# test loads in capability mode
test_load:
.option capmode
        li gp, 1
        cmove cs0, c31
        clb t0, -8(cs0)
        j test_fail
        clh t0, -8(cs0)
        j test_fail
        clw t0, -8(cs0)
        j test_fail
        cld t0, -8(cs0)
        j test_fail
        clc ct0, -8(cs0)
        j test_fail

test_success:
.option nocapmode
        RVTEST_PASS

test_fail:
.option nocapmode
        RVTEST_FAIL

mtvec_handler: # handle exceptions thrown by tests
.option nocapmode
        csrrc t0, mtval, zero

handle_test:
        li t1, 0b0100011110 # register cs0, exception code 30 (UninitLoadViolation)
        beq t0, t1, mtval_return
        j test_fail

mtval_return:
        # when returning, advance the program counter past the "j test_fail" instruction
        csrrc t0, mepc, zero
        addi t0, t0, 8 # advance pc 2 instructions to skip jump to fail
        csrrw zero, mepc, t0
        mret
.align 5
.global tohost
tohost: .dword 0
