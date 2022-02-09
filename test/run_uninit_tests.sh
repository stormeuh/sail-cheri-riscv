#!/bin/bash

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR
RISCVDIR="$DIR/.."
UNINITTESTDIR="$RISCVDIR/test/uninit-tests"
CLEAN_AFTER=true

RED='\033[0;91m'
GREEN='\033[0;92m'
NC='\033[0m'

pass=0
fail=0

ocaml_success=false
c_success=false

function green {
    (( pass += 1 ))
    printf "$1: ${GREEN}$2${NC}\n"
}

function red {
    (( fail += 1 ))
    printf "$1: ${RED}$2${NC}\n"
}

function finish_suite {
    printf "$1: Passed ${pass} out of $(( pass + fail ))\n\n"
    pass=0
    fail=0
}

cd $RISCVDIR

printf "Building 64-bit RISCV specification...\n"

if make ocaml_emulator/cheri_riscv_ocaml_sim_RV64 &> /dev/null;
then
    green "Building 64-bit RISCV OCaml emulator" "ok"
else
    red "Building 64-bit RISCV OCaml emulator" "fail"
fi

cd $UNINITTESTDIR
if ! make; then
    echo "Set the CLANG environment variable to the custom clang binary."
    exit 1
else
    for test in *.elf; do
        if timeout 15 $RISCVDIR/ocaml_emulator/cheri_riscv_ocaml_sim_RV64 $test > ${test%.elf}.out 2>&1 && grep -q SUCCESS ${test%.elf}.out
        then
        green "OCaml-64 $(basename $test)" "ok"
        else
        red "OCaml-64 $(basename $test)" "fail"
        fi
    done
fi

if [ $fail = 0 ] ; then
    ocaml_success=true
fi

finish_suite "64-bit RISCV OCaml tests"

cd $RISCVDIR

if make c_emulator/cheri_riscv_sim_RV64 &> /dev/null;
then
    green "Building 64-bit RISCV C emulator" "ok"
else
    red "Building 64-bit RISCV C emulator" "fail"
fi

cd $UNINITTESTDIR
if ! make; then
    echo "Set the CLANG environment variable to the custom clang binary."
    exit 1
else
    for test in *.elf; do
        if timeout 15 $RISCVDIR/c_emulator/cheri_riscv_sim_RV64 -p $test > ${test%.elf}.cout 2>&1 && grep -q SUCCESS ${test%.elf}.cout
        then
            green "C-64 $(basename $test)" "ok"
        else
            red "C-64 $(basename $test)" "fail"
        fi
    done
fi

if [ $fail = 0 ] ; then
    c_success=true
fi

finish_suite "64-bit RISCV C tests"

if [ $CLEAN_AFTER ] && [ $ocaml_success ] && [ $c_success ] ; then
    echo "All succeeded, cleaning test folder."
    echo "Set CLEAN_AFTER to false to keep logs."
    make clean
fi
