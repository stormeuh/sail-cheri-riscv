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

# test tag is cleared when cap is sealed
test_sealed:
        li gp, 3
        cuninit cs0, cs0
        csealentry cs0, cs0
        cdropuninit cs0, cs0
        cgettag t0, cs0
        bnez t0, test_fail

test_success:
        RVTEST_PASS

test_fail:
        RVTEST_FAIL

# exception handler
mtvec_handler:
        j test_fail

        .align 5
        .global tohost
tohost: .dword 0
