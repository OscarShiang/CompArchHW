SHELL   := /bin/bash
CC_C    := gcc
CC_CPP  := g++
EXE     := cache
SRC_C   := cache.c
OBJ     := cache.o
PYTHON  := python3
# CLIENT  := client.py
VERIFY_EXE := Verify
# VERIFY_OBJ := verify.o
# VERIFY_SRC := verify.cpp
LIBDIR  := ./lib/
INCLUDE := .
CFLAGS  := -I${INCLUDE}
LIBFLAG := -L${LIBDIR} -Wl,-rpath,${LIBDIR}
 
PREOPERATION := 
ifneq (${REQ_FILE},)
PREOPERATION += ${REQ_FILE}
endif
ifneq (${VIC_FILE},)
PREOPERATION += ${VIC_FILE}
endif

.PHONY: all clean

all: ${EXE}
	 
${EXE}: ${OBJ}
	@${CC_CPP} ${OBJ} -o ${EXE}
		 
${OBJ}: ${SRC_C}
	${CC_C} -c ${SRC_C} -o ${OBJ} ${LIBFLAGS}
			 
sim: clean ${EXE}
	./${EXE} ${PREOPERATION}
	 
BLUE   = \033[1;34m
RED    = \033[1;31m
NORMAL = \033[0m
	 
verify: sim ${VERIFY_EXE}
	./${VERIFY_EXE} ${PREOPERATION}

format:
	clang-format -i ${SRC_C}

clean:
	@rm -rf ${EXE} *.o
