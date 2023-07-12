#
# ███████╗ ██████╗██████╗  █████╗  ██████╗     ██████╗ ███████╗
# ██╔════╝██╔════╝██╔══██╗██╔══██╗██╔════╝    ██╔═══██╗██╔════╝
# ███████╗██║     ██████╔╝███████║██║         ██║   ██║███████╗
# ╚════██║██║     ██╔══██╗██╔══██║██║         ██║   ██║╚════██║
# ███████║╚██████╗██║  ██║██║  ██║╚██████╗    ╚██████╔╝███████║
# ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝     ╚═════╝ ╚══════╝
# 
# By: Kerdonov


# build vars
BUILD_DIR=build

BOOT_SRC=src/boot
KERNEL_SRC=src/kernel

KERNEL_SOURCES_C=$(sort $(wildcard $(KERNEL_SRC)/*.c))
KERNEL_OBJECTS_C=$(patsubst $(KERNEL_SRC)/%.c, $(BUILD_DIR)/kernel/c/%.o, $(KERNEL_SOURCES_C))
KERNEL_SOURCES_ASM=$(sort $(wildcard $(KERNEL_SRC)/*.asm))
KERNEL_OBJECTS_ASM=$(patsubst $(KERNEL_SRC)/%.asm, $(BUILD_DIR)/kernel/asm/%.o, $(KERNEL_SOURCES_ASM))
#KERNEL_SOURCES_RS=$(wildcard $(KERNEL_SRC)/*.rs)
#KERNEL_OBJECTS_RS=$(patsubst $(KERNEL_SRC)/%.rs, $(BUILD_DIR)/kernel/rs/%.o, $(KERNEL_SOURCES_RS))

# modify these, where you have your cross compiler toolchain installed
CC=/mnt/i386elfgcc/bin/i386-elf-gcc
LD=/mnt/i386elfgcc/bin/i386-elf-ld
RUSTC=rustc


# info vars
SCRIPT_LINK="https://raw.githubusercontent.com/mell-o-tron/MellOs/main/A_Setup/setup-gcc-arch.sh"
define HEADER
                            ___  ____  
 ___  ___ _ __ __ _  ___   / _ \/ ___| 
/ __|/ __| '__/ _` |/ __| | | | \___ \ 
\__ \ (__| | | (_| | (__  | |_| |___) |
|___/\___|_|  \__,_|\___|  \___/|____/ 

endef
export HEADER


# beauty vars
GREEN=\e[1;32m
BLUE=\e[1;34m
RED=\e[1;31m
CYAN=\e[1;36m
NC=\e[0m


# bin
build: $(BUILD_DIR)/OS.bin


# main os bin file
$(BUILD_DIR)/OS.bin: $(BUILD_DIR)/boot/boot.bin $(BUILD_DIR)/kernel/kernel.bin $(BUILD_DIR)/utility/zeroes.bin
	@echo -e "${BLUE}COMBINE BOOTLOADER, KERNEL AND BUFFER:${NC}"
	cat $^ > $@


# bootloader
$(BUILD_DIR)/boot/boot.bin: $(BOOT_SRC)/boot.asm
	@echo -e "${GREEN}ASSEMBLE BOOTLOADER:${NC}"
	mkdir -p build/boot
	nasm $< -f bin -o $@


# kernel entry + kernel
$(BUILD_DIR)/kernel/kernel.bin: $(KERNEL_OBJECTS_C) $(KERNEL_OBJECTS_ASM)
	@echo -e "${BLUE}LINK KERNEL OBJECT FILES:${NC}"
	mkdir -p build/kernel
	$(LD) -o $@ -Ttext 0x1000 $^ --oformat binary

$(BUILD_DIR)/kernel/c/%.o: $(KERNEL_SRC)/%.c
	@echo -e "${GREEN}COMPILE $(patsubst $(KERNEL_SRC)/%,%,$<):${NC}"
	mkdir -p build/kernel/c
	$(CC) -ffreestanding -m32 -g -c -o $@ $<

$(BUILD_DIR)/kernel/asm/%.o: $(KERNEL_SRC)/%.asm
	@echo -e "${GREEN}ASSEMBLE $(patsubst $(KERNEL_SRC)/%,%,$<):${NC}"
	mkdir -p build/kernel/asm
	nasm $< -f elf -o $@

# rust in the future
$(BUILD_DIR)/kernel/rs/%.o: $(KERNEL_SRC)/%.rs
	@echo -e "${GREEN}COMPILE $(patsubst $(KERNEL_SRC)/%,%,$<):${NC}"
	mkdir -p build/kernel/rs
	$(RUSTC) -o $@ $< --target=x86_64-unknown-none --emit=obj



# padding
$(BUILD_DIR)/utility/zeroes.bin: $(BOOT_SRC)/zeroes.asm
	@echo -e "${GREEN}ASSEMBLE BUFFER:${NC}"
	mkdir -p build/utility
	nasm $< -f bin -o $@



# run os in qemu (binary)
run: $(BUILD_DIR)/OS.bin
	@echo -e "${CYAN}LAUNCH EMULATOR:${NC}"
	qemu-system-x86_64 -drive format=raw,file=$<,index=0,if=floppy, -m 256M


# launch with debugging (gdb, port 1234)
debug: $(BUILD_DIR)/OS.bin
	@echo -e "${CYAN}LAUNCH DEBUG SESSION:${NC}"
	qemu-system-x86_64 -s -S -drive format=raw,file=$<,index=0,if=floppy, -m 256M

	

# clean build dir
clean:
	@echo -e "${RED}CLEAN BUILD FILES:${NC}"
	rm -rf $(BUILD_DIR)/*

# print project info
info: header
	@echo "This is a project by Kerdonov. Heavily inspired by Daedalus Community YouTube channel."
	@echo -e "Written in x86 assembly and C(++) for BIOS systems on x86.\n"
	@echo "Commands:"
	@echo -e "${GREEN}$$ make build${NC}\t\tbuild the OS.bin file"
	@echo -e "${GREEN}$$ make run${NC}\t\tbuild and run OS.bin on qemu"
	@echo -e "${GREEN}$$ make debug${NC}\t\trun in debug mode (gdb port 1234)"
	@echo -e "${GREEN}$$ make clean${NC}\t\tclean build directory\n"
	@echo -e "This project needs i386elfgcc and binutils to cross compile C code. For more info, see this install script (for Arch Linux)"
	@echo -e "${SCRIPT_LINK}\n"
	@echo -e "I want to thank Daedalus Community, nanobyte, Uncle Scientist on YouTube, Philipp Oppermann and Brandon F. for teaching me the basics of operating system development.\n"
	@echo "I ♡ GNU make now, wth"

header:
	@echo ""
	@echo -e "${BLUE}$$HEADER${NC}"



# print personal notes on what to do next
next:
	@echo "Create different interrupt handlers."
	@echo "Second, make yourself comfortable with memory management. Read about and implement paging (and everything else I have yet to find out about). Organize the memory of the kernel PERFECTLY. (the fact that I have no idea where i could fit in my heap, is a problem.)"
	@echo "Implement an allocator (preferrably (l grammar) fixed size block or linked list)"
	@echo "I am leaning towards fixed size block, but idk. It just seems more organized."
