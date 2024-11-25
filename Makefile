# Directories
UNITY_DIR = Unity/src
SRC_DIR = src
TEST_DIR = test

# Files
MAIN_TEST = $(TEST_DIR)/spec.c
TEST_SRC = $(TEST_DIR)/ccwc.spec.c
PARSER_TEST_SRC = $(TEST_DIR)/parser.spec.c
SRC = $(SRC_DIR)/ccwc.c
PARSER_SRC = $(SRC_DIR)/parser.c
ERROR_SRC = $(SRC_DIR)/errors.c
UNITY_SRC = $(UNITY_DIR)/unity.c
MAIN = $(SRC_DIR)/main.c

# Compiler flags
CFLAGS_SRC = -I $(SRC_DIR)
CFLAGS_TEST = -I $(UNITY_DIR) -I $(SRC_DIR)

# Targets
TARGET_SRC = ccwc
TARGET_TEST = ccwc.test

all: $(TARGET_TEST)

$(TARGET_TEST): $(MAIN_TEST) $(TEST_SRC) $(PARSER_TEST_SRC) $(SRC) $(UNITY_SRC) $(PARSER_SRC) $(ERROR_SRC)
	gcc -fprofile-arcs -ftest-coverage $(CFLAGS_TEST) -o $(TARGET_TEST) $(UNITY_SRC) $(MAIN_TEST) $(TEST_SRC) $(PARSER_TEST_SRC) $(SRC) $(PARSER_SRC) $(ERROR_SRC)

$(TARGET_SRC): $(MAIN) $(SRC) $(PARSER_SRC) $(ERROR_SRC)
	gcc -O3 $(CFLAGS_SRC) -o $(TARGET_SRC) $(SRC) $(MAIN) $(PARSER_SRC) $(ERROR_SRC)

build: $(TARGET_SRC)
	@echo "Successfully compiled"

run: $(TARGET_SRC)
	./$(TARGET_SRC) $(ARGS)

test: $(TARGET_TEST)
	./$(TARGET_TEST)

report: test
	lcov --capture --directory . --output-file coverage.info
	genhtml coverage.info --output-directory coverage --exclude $(UNITY_DIR)
	firefox coverage/index.html

benchmark: build
	$(eval CURRENT_TIME := $(shell date +"%Y%m%d%H%M%S%3N"))
	./scripts/bm.py "${CURRENT_TIME}" "no_args" "./ccwc data/test.txt" "wc data/test.txt"
	./scripts/bm.py "${CURRENT_TIME}" "byte_count" "./ccwc -c data/test.txt" "wc -c data/test.txt"
	./scripts/bm.py "${CURRENT_TIME}" "line_count" "./ccwc -l data/test.txt" "wc -l data/test.txt"
	./scripts/bm.py "${CURRENT_TIME}" "word_count" "./ccwc -w data/test.txt" "wc -w data/test.txt"
	./scripts/bm.py "${CURRENT_TIME}" "char_count" "./ccwc -m data/test.txt" "wc -m data/test.txt"
	./scripts/bm.py "${CURRENT_TIME}" "all_args" "./ccwc -cmwl data/test.txt" "wc -cmwl data/test.txt"
	./scripts/bm.py "${CURRENT_TIME}" "stdin_no_args" "cat data/test.txt | ./ccwc" "cat data/test.txt | wc"
	./scripts/bm.py "${CURRENT_TIME}" "stdin_byte_count" "cat data/test.txt | ./ccwc -c" "cat data/test.txt | wc -c"
	./scripts/bm.py "${CURRENT_TIME}" "stdin_line_count" "cat data/test.txt | ./ccwc -l" "cat data/test.txt | wc -l"
	./scripts/bm.py "${CURRENT_TIME}" "stdin_word_count" "cat data/test.txt | ./ccwc -w" "cat data/test.txt | wc -w"
	./scripts/bm.py "${CURRENT_TIME}" "stdin_char_count" "cat data/test.txt | ./ccwc -m" "cat data/test.txt | wc -m"
	./scripts/bm.py "${CURRENT_TIME}" "stdin_all_args" "cat data/test.txt | ./ccwc -cmwl" "cat data/test.txt | wc -cmwl"
	firefox benchmark

clean:
	rm -f *.gcda *.gcno
	rm -f $(TARGET_TEST) $(TARGET_SRC)
	rm -f coverage.info
	rm -rf coverage/
	rm -rf benchmark/
