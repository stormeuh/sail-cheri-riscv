#ifndef RISCV_TEST_H
#define RISCV_TEST_H

#include "encoding.h"

.macro defToHost
  .p2align 5
  .global tohost
tohost: .dword 0
.endm

.macro defExit
.global _exit
_exit:
  fence
  csrr t0, mcause
  csrr t0, mtval
  cllc ctp, tohost
  sll a0, a0, 1
  addi a0, a0, 1
1:
  csw a0, 0(ctp)
  j 1b
.endm

#define INIT_XREG                                                       \
  cclear 0, 254;                                                         \
  cclear 1, 255;                                                         \
  cclear 2, 255;                                                         \
  cclear 3, 255;

#define RISCV_MULTICORE_DISABLE                                         \
  csrr a0, mhartid;                                                     \
  1: bnez a0, 1b

#define CHERI_CAPMODE_ENABLE                                            \
  li t1, 1;                                                             \
  cspecialrw ct0, pcc, c0;                                              \
  cincoffsetimm ct0, ct0, 16;                                           \
  csetflags ct0, ct0, t1;                                               \
  jr.cap ct0;                                                           \

#define INIT_PMP                                                        \
  cllc ct0, 1f          ;                                               \
  cspecialrw c0, mtcc, ct0;                                             \
  /* Set up a PMP to permit all accesses */                             \
  li t0, (1 << (31 + (__riscv_xlen / 64) * (53 - 31))) - 1;             \
  csrw pmpaddr0, t0;                                                    \
  li t0, PMP_NAPOT | PMP_R | PMP_W | PMP_X;                             \
  csrw pmpcfg0, t0;                                                     \
  .align 2;                                                             \
1:

#define INIT_SATP                                                       \
  cllc ct0, 1f        ;                                                 \
  cspecialrw c0, mtcc, ct0;                                             \
  csrwi satp, 0;                                                        \
  .align 2;                                                             \
1:

#define DELEGATE_NO_TRAPS                                               \
  csrwi mie, 0;                                                         \
  csrwi medeleg, 0;                                                     \
  csrwi mideleg, 0;                                                     \
  .align 2;                                                             \


#define RVTEST_ENABLE_MACHINE                                           \
  li a0, MSTATUS_MPP;                                                   \
  csrs mstatus, a0;                                                     \

#define INIT_TRAP_HANDLER                                               \
  cllc ct0, _exit;                                                      \
  cspecialrw c0, mtcc, ct0;                                             \
  cmove ct0, c0;                                                        \
  li a0, 1337;                                                          \

#define WIPE_DDC                                                        \
  cspecialrw c0, ddc, ct0;

//  create stack capability:
//
//            |            |
// 0x80100000 |------------| <- top, cursor
//            |            |
// 0x80010000 |------------| <- base
//            |            |
// todo: make stack a statically allocated symbol in linking

#define INIT_C_ENV                                                      \
  cspecialrw csp, ddc, c0;                                              \
  li t0, 0x80010000;                                                    \
  csetoffset csp, csp, t0;                                              \
  li t0, 0x100000;                                                      \
  csetbounds csp, csp, t0;                                              \
  cincoffset csp, csp, t0;                                              \
  li t0, 1;                                                             \
  csetflags csp, csp, t0;                                               \
  cmove ct0, c0;                                                        \

#endif
