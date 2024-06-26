#
# ███████╗ ██████╗██████╗  █████╗  ██████╗     ██████╗ ███████╗
# ██╔════╝██╔════╝██╔══██╗██╔══██╗██╔════╝    ██╔═══██╗██╔════╝
# ███████╗██║     ██████╔╝███████║██║         ██║   ██║███████╗
# ╚════██║██║     ██╔══██╗██╔══██║██║         ██║   ██║╚════██║
# ███████║╚██████╗██║  ██║██║  ██║╚██████╗    ╚██████╔╝███████║
# ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝     ╚═════╝ ╚══════╝
# 
# By: Kerdonov

.PHONY: bootloader kernel

# build vars
BUILD_DIR=build

BOOT_SRC=src/boot
STAGE2_SRC=src/boot/stage2
KERNEL_SRC=src/kernel

STAGE2_SOURCES_C=$(sort $(wildcard $(STAGE2_SRC)/*.c))
STAGE2_OBJECTS_C=$(patsubst $(STAGE2_SRC)/%.c, $(BUILD_DIR)/boot/c/%.o, $(STAGE2_SOURCES_C))
STAGE2_SOURCES_ASM=$(sort $(wildcard $(STAGE2_SRC)/*.asm))
STAGE2_OBJECTS_ASM=$(patsubst $(STAGE2_SRC)/%.asm, $(BUILD_DIR)/boot/asm/%.o, $(STAGE2_SOURCES_ASM))

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
GREEN=\033[1;32m
BLUE=\033[1;34m
RED=\033[1;31m
CYAN=\033[1;36m
NC=\033[0m

# floppy disk image
disk: $(BUILD_DIR)/floppa.img

$(BUILD_DIR)/floppa.img: bootloader kernel
	@echo "${BLUE}WRITE FILES TO $@:${NC}"
	dd if=/dev/zero of=$(BUILD_DIR)/floppa.img bs=512 count=2880
	mkfs.fat -F 12 -n "scrac" $(BUILD_DIR)/floppa.img
	dd if=$(BUILD_DIR)/boot/boot.bin of=$(BUILD_DIR)/floppa.img conv=notrunc
	mcopy -i $(BUILD_DIR)/floppa.img $(BUILD_DIR)/boot/stage2.bin "::stage2.bin"
	mcopy -i $(BUILD_DIR)/floppa.img $(BUILD_DIR)/kernel/kernel.bin "::kernel.bin"




bootloader: $(BUILD_DIR)/boot/boot.bin $(BUILD_DIR)/boot/stage2.bin

# stage1
$(BUILD_DIR)/boot/boot.bin: $(BOOT_SRC)/boot.asm
	@echo "${GREEN}ASSEMBLE BOOTLOADER:${NC}"
	mkdir -p build/boot
	nasm $< -f bin -o $@

# stage2
$(BUILD_DIR)/boot/stage2.bin: $(STAGE2_OBJECTS_C) $(STAGE2_OBJECTS_ASM)
	@echo "${BLUE}LINK STAGE2:${NC}"
	$(LD) -o $@ $^ --oformat binary

$(BUILD_DIR)/boot/c/%.o: $(STAGE2_SRC)/%.c
	@echo "${GREEN}COMPILE $(patsubst $(STAGE2_SRC)/%,%,$<):${NC}"
	mkdir -p build/boot/c
	$(CC) -ffreestanding -m32 -g -c -o $@ $<

$(BUILD_DIR)/boot/asm/%.o: $(STAGE2_SRC)/%.asm
	@echo "${GREEN}ASSEMBLE $(patsubst $(STAGE2_SRC)/%,%,$<):${NC}"
	mkdir -p build/boot/asm
	nasm $< -f elf -o $@



kernel: $(BUILD_DIR)/kernel/kernel.bin

# kernel entry + kernel
$(BUILD_DIR)/kernel/kernel.bin: $(KERNEL_OBJECTS_C) $(KERNEL_OBJECTS_ASM)
	@echo "${BLUE}LINK KERNEL OBJECT FILES:${NC}"
	mkdir -p build/kernel
	$(LD) -o $@ -Ttext 0x1000 $^ --oformat binary

$(BUILD_DIR)/kernel/c/%.o: $(KERNEL_SRC)/%.c
	@echo "${GREEN}COMPILE $(patsubst $(KERNEL_SRC)/%,%,$<):${NC}"
	mkdir -p build/kernel/c
	$(CC) -ffreestanding -m32 -g -c -o $@ $<

$(BUILD_DIR)/kernel/asm/%.o: $(KERNEL_SRC)/%.asm
	@echo "${GREEN}ASSEMBLE $(patsubst $(KERNEL_SRC)/%,%,$<):${NC}"
	mkdir -p build/kernel/asm
	nasm $< -f elf -o $@

# rust in the future
$(BUILD_DIR)/kernel/rs/%.o: $(KERNEL_SRC)/%.rs
	@echo "${GREEN}COMPILE $(patsubst $(KERNEL_SRC)/%,%,$<):${NC}"
	mkdir -p build/kernel/rs
	$(RUSTC) -o $@ $< --target=x86_64-unknown-none --emit=obj





# boot disk image in qemu
run: $(BUILD_DIR)/floppa.img
	@echo "${CYAN}BOOT DISK IMAGE:${NC}"
	qemu-system-i386 -drive format=raw,file=$<,index=0,if=floppy, -m 32
	#qemu-system-i386 -debugcon stdio -m 32 -fda $<


# launch debugging sesh
debug: $(BUILD_DIR)/floppa.img
	@echo "${CYAN}LAUNCH DEBUG SESSION:${NC} (gdb: target remote localhost:1234)"
	qemu-system-x86_64 -s -S -drive format=raw,file=$<,index=0,if=floppy, -m 256M
	#bochs -f bochs_config


	

# clean build dir
clean:
	@echo "${RED}CLEAN BUILD FILES:${NC}"
	rm -rf $(BUILD_DIR)/*

# print project info
info: header
	@echo "This is a project by Kerdonov. Heavily inspired by Daedalus Community YouTube channel."
	@echo "Written in x86 assembly and C(++) for BIOS systems on x86.\n"
	@echo "${GREEN}Make Commands:${NC}"
	@echo "${GREEN}$$ make build${NC}\t\tbuild the floppa.img file"
	@echo "${GREEN}$$ make run${NC}\t\tbuild and run floppa.img on qemu"
	@echo "${GREEN}$$ make debug${NC}\t\trun in debug mode (gdb port 1234)"
	@echo "${GREEN}$$ make clean${NC}\t\tclean build directory\n"
	
	@echo "${RED}Error codes:${NC}"
	@echo "${RED}B${NC} - kernel loading successful"
	@echo "${RED}1${NC} - floppy disk read error"
	@echo "${RED}2${NC} - kernel not found error"

	@echo ""

	@echo "This project needs i386elfgcc and binutils to cross compile C code. For more info, see this install script (for Arch Linux)"
	@echo "${SCRIPT_LINK}\n"
	@echo "I want to thank Daedalus Community, nanobyte, Uncle Scientist on YouTube, Philipp Oppermann and Brandon F. for teaching me the basics of operating system development.\n"
	@echo "I ♡ GNU make now, wth"

header:
	@echo ""
	@echo "${BLUE}$$HEADER${NC}"



# print personal notes on what to do next
next:
	@echo "Create different interrupt handlers."
	@echo "Second, make yourself comfortable with memory management. Read about and implement paging (and everything else I have yet to find out about). Organize the memory of the kernel PERFECTLY. (the fact that I have no idea where i could fit in my heap, is a problem.)"
	@echo "Implement an allocator (preferrably (l grammar) fixed size block or linked list)"
	@echo "I am leaning towards fixed size block, but idk. It just seems more organized."
