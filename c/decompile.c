#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ngs.h"
#include "vm.h"

// TODO: get rid of int16_t and int32_t, use types such as JUMP_OFFSET and PATCH_OFFSET instead.

void decompile(const char *buf, const size_t start, const size_t end) {
	size_t idx, orig_idx;
	unsigned char opcode;
	char info_buf[1024];
	unsigned char str_len;

	for(idx=start; idx < end; ) {
		orig_idx = idx;
		opcode = buf[idx++];
		info_buf[0] = 0;
		switch(opcode) {
			case OP_JMP:
			case OP_JMP_TRUE:
			case OP_JMP_FALSE:
				sprintf(info_buf, " %+05d (%04zu)", *(JUMP_OFFSET *)&buf[idx], idx + *(JUMP_OFFSET *)&buf[idx] + sizeof(JUMP_OFFSET));
				idx+=sizeof(JUMP_OFFSET);
				break;
			case OP_MAKE_CLOSURE:
				sprintf(info_buf, " %+05d (%04zu), %d", *(JUMP_OFFSET *)&buf[idx], idx + *(JUMP_OFFSET *)&buf[idx] + sizeof(JUMP_OFFSET) + sizeof(LOCAL_VAR_INDEX), *(LOCAL_VAR_INDEX *)&buf[idx+sizeof(JUMP_OFFSET)]);
				idx+=sizeof(JUMP_OFFSET)+sizeof(LOCAL_VAR_INDEX);
				break;
			case OP_PATCH:
				sprintf(info_buf, " %+05d (%04zu)", *(PATCH_OFFSET *)&buf[idx], idx + *(PATCH_OFFSET *)&buf[idx] + sizeof(PATCH_OFFSET));
				idx+=sizeof(PATCH_OFFSET);
				break;
			case OP_FETCH_GLOBAL:
			case OP_STORE_GLOBAL:
			case OP_GLOBAL_DEF_P:
				sprintf(info_buf, " %d", *(int16_t *)&buf[idx]); idx+=2; break;
			case OP_FETCH_LOCAL:
			case OP_STORE_LOCAL:
			case OP_LOCAL_DEF_P:
				sprintf(info_buf, " %d", *(LOCAL_VAR_INDEX *)&buf[idx]); idx+=sizeof(LOCAL_VAR_INDEX); break;
			case OP_PUSH_INT:
				sprintf(info_buf, " %d", *(int32_t *)&buf[idx]); idx+=4; break;
			case OP_PUSH_L_STR:
				str_len = (unsigned char)buf[idx++];
				sprintf(info_buf, " %.*s", str_len, &buf[idx]);
				idx += str_len;
		}
		if(opcode <= sizeof(opcodes_names) / sizeof(char *)) {
			printf("DECOMPILE [%04zu] %s%s\n", orig_idx, opcodes_names[opcode], info_buf);
		}
	}
}