CLANG?=clang
# The CLANG env variable should be set to the path to the custom clang compiler
TESTS = test-CGetUninit.elf \
	test-CUninit.elf \
	test-CDropUninit.elf \
	test-CShrink.elf \
	test-StoreUninit.elf \
	test-LoadUninit.elf \
	test-LoadUninitCapMode.elf \
	test-AMO.elf \
	test-CSetBounds.elf

FLAGS = -nostdlib -Ttext 0x80000000 --target=riscv64-unknown-freebsd -march=rv64gxcheri -mno-relax -fuse-ld=lld

SAIL_RISCV_SIM = ../../ocaml_emulator/cheri_riscv_ocaml_sim_RV64

all: $(TESTS)

%.elf: %.S
	$(CLANG) $< $(FLAGS) -o $@

%.test: %.elf
	@$(SAIL_RISCV_SIM) $<

%.out: %.elf
	@$(SAIL_RISCV_SIM) $< > $@

# %.result: %.out
#	$

clean:
	rm -rf *.elf *.out *.cout
