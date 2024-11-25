#include <stdbool.h>
#include <stdlib.h>

#include "parser.h"
#include "ccwc.h"
#include "constants.h"

bool count_flag_setter(Arguments* args, int key) {
  int flag_idx = -1;
  switch(key) {
    case LINE_FLAG: args -> flag_mask |= LINE_FLAG_MASK; flag_idx = LINE_FLAG_INDEX; break;
    case WORD_FLAG: args -> flag_mask |= WORD_FLAG_MASK; flag_idx = WORD_FLAG_INDEX; break;
    case CHAR_FLAG: args -> flag_mask |= CHAR_FLAG_MASK; flag_idx = CHAR_FLAG_INDEX; break;
    case BYTE_FLAG: args -> flag_mask |= BYTE_FLAG_MASK; flag_idx = BYTE_FLAG_INDEX; break;
  }

  bool is_valid_key = flag_idx != -1;
  if(is_valid_key) {
    args -> flag_counter++;
    args -> count_flags[flag_idx] = (char) key;
  }

  return is_valid_key;
}

error_t parse_opt(int key, char* arg, struct argp_state *state) {
  Arguments* args = state -> input;
  bool was_valid_key = count_flag_setter(args, key);

  switch (key) {
    case ARGP_KEY_ARG:
      if(state -> arg_num == 0) {
        args -> filename = arg;
      } else {
        return argp_err_exit_status;
      }
      break;
    case ARGP_KEY_END:
      if(state -> arg_num < 1) {
        args -> is_from_stdin = true;
      }
      break;
    default: if(!was_valid_key) return ARGP_ERR_UNKNOWN;
  }

  return 0;
}

void parse_args(const struct argp* argp, int argc, char** argv, Arguments* args) {
  argp_parse(argp, argc, argv, 0, 0, args);

  if(args -> flag_counter == 0) {
    args -> count_flags[LINE_FLAG_INDEX] = LINE_FLAG;
    args -> count_flags[WORD_FLAG_INDEX] = WORD_FLAG;
    args -> count_flags[BYTE_FLAG_INDEX] = BYTE_FLAG;
  }
}

int process_args(const Arguments* args) {
  char* file_content;
  bool check_file_content = true;
  if(args -> is_from_stdin) {
    file_content = get_stdin_content();
  } else {
    uint8_t combined_mask = CHAR_FLAG_MASK | BYTE_FLAG_MASK;
    if(args -> flag_mask == BYTE_FLAG_MASK || ((args -> flag_mask & combined_mask) && (args -> flag_mask & ~combined_mask) == 0) && MB_CUR_MAX == 1) {
      check_file_content = false;
    } else {
      file_content = get_file_content(args -> filename);
    }
  }
  if(check_file_content && file_content == NULL) {
    return 1;
  }

  int flag_idx = 0;
  int count_value_idx = 0;
  size_t count_values[4];
  while(flag_idx < 4) {
    char current_count_flag = args -> count_flags[flag_idx];
    if(current_count_flag != '\0') {
      size_t count_value = 0;
      switch(current_count_flag) {
        case LINE_FLAG:
          count_value = count_newlines(file_content);
          break;
        case WORD_FLAG:
          count_value = count_words(file_content);
          break;
        case CHAR_FLAG:
          if(MB_CUR_MAX == 1) {
            if(args -> is_from_stdin) {
              count_value = count_bytes(file_content);
            } else {
              ssize_t tmp_byte_count = count_bytes_in_file(args -> filename);
              if(tmp_byte_count == -1) return 1;
              count_value = (size_t) tmp_byte_count;
            }
          } else {
            count_value = count_chars(file_content);
          }
          break;
        case BYTE_FLAG:
          if(args -> is_from_stdin) {
            count_value = count_bytes(file_content);
          } else {
            ssize_t tmp_byte_count = count_bytes_in_file(args -> filename);
            if(tmp_byte_count == -1) return 1;
            count_value = (size_t) tmp_byte_count;
          }
          break;
      }
      count_values[count_value_idx] = count_value;
      count_value_idx++;
    }

    flag_idx++;
  }

  for(int i = 0; i < count_value_idx; i++) printf("%zu ", count_values[i]);
  if(args -> is_from_stdin) printf("\n");
  else printf("%s\n", args -> filename);

  free(file_content);
  return 0;
}
