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

test_sealed:
        li gp, 2
        csealentry cs0, cs0
        cuninit cs0, cs0
        cgettag t0, cs0
        bnez t0, test_fail

test_success:
        RVTEST_PASS

test_fail:
        RVTEST_FAIL

mtvec_handler:
        j test_fail

       .align 5
        .global tohost
tohost: .dword 0
