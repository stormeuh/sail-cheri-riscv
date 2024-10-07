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

test_success:
        RVTEST_PASS

test_fail:
        RVTEST_FAIL

# exception handler
# inspects error code to ensure it is correct
mtvec_handler:
        j test_fail

        .align 5
        .global tohost
tohost: .dword 0
