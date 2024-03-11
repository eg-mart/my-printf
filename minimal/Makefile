CC := nasm -f elf64
LD := ld -s

EXE := minimal
SRCS := minimal.s
SRC_DIR := .
OBJ_DIR := build

OBJS := $(SRCS:%.s=%.o)
OBJ_PATHS := $(addprefix $(OBJ_DIR)/, $(OBJS))

.PHONY: clean all

all: $(EXE)

$(EXE) : $(OBJ_PATHS)
	$(LD) -o $(EXE) $(OBJ_PATHS)

$(OBJ_DIR)/%.o : $(SRC_DIR)/%.s | $(OBJ_DIR)
	$(CC) -l $(OBJ_DIR)/$*.lst -o $@ $<

$(OBJ_DIR):
	mkdir $(OBJ_DIR)

clean:
	rm -r $(OBJ_DIR) $(EXE)