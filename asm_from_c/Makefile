AS := nasm
AS_FLAGS := -f elf64
LD := ld
LD_FLAGS := -s -lc -I /lib64/ld-linux-x86-64.so.2
CC := cc
CC_FLAGS := -c

EXE := asm_from_c
ASM_SRCS := my_putc.s
C_SRCS := main.c
OBJS := $(ASM_SRCS:%.s=%.o) $(C_SRCS:%.c=%.o)
LIBS := /usr/lib/crt1.o
SRC_DIR := .
OBJ_DIR := build

OBJ_PATHS := $(addprefix $(OBJ_DIR)/, $(OBJS))

.PHONY: clean all

all: $(EXE)

$(EXE) : $(OBJ_PATHS)
	$(LD) $(LD_FLAGS) -o $(EXE) $(OBJ_PATHS) $(LIBS)

$(OBJ_DIR)/%.o : $(SRC_DIR)/%.s | $(OBJ_DIR)
	$(AS) $(AS_FLAGS) -l $(OBJ_DIR)/$*.lst -o $@ $<

$(OBJ_DIR)/%.o : $(SRC_DIR)/%.c | $(OBJ_DIR)
	$(CC) $(CC_FLAGS) -o $@ $<

$(OBJ_DIR):
	mkdir $(OBJ_DIR)

clean:
	rm -r $(OBJ_DIR) $(EXE)
