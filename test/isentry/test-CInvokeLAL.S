#include "test_macros.h"

defToHost

.p2align 5
.global _start
_start:
    INIT_XREG
    CHERI_CAPMODE_ENABLE
    INIT_TRAP_HANDLER
    cllc ct0, actrec
    cllc ct1, actrec_handler
    csealentry ct1, ct1
    csc ct1, 0(ct0)
    clc ct1, 0(ct0)
    cseall ct0, ct0
    cinvokelal cra, ct0
    cj _exit

.p2align 5
actrec:
    .dword 0
    .dword 0
    .word 42

actrec_handler:
    clw a0, 16(idc)
    cret

defExit
