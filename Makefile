SRC_DIR := src
SRC_FILES := $(shell find $(SRC_DIR) -type f)
SCRIPTS_DIR := scripts
SCRIPT_FILES := $(shell find $(SCRIPTS_DIR) -type f)
INSTALL_SCRIPT := $(SCRIPTS_DIR)/install
# install script requires an absolute path to make a system link
INSTALL_TARGET_ABSOLUTE_PATH := $(shell pwd)/$(SRC_DIR)/dotfile

default:
	@echo "Nothing to make by default - try \"make install\""
.PHONY: default

lint:
	@echo "Linting shell scripts"
	@shellcheck $(SRC_FILES) $(SCRIPT_FILES)
	@echo "Done"
.PHONY: test

install:
	@$(INSTALL_SCRIPT) -f $(INSTALL_TARGET_ABSOLUTE_PATH)
.PHONY: install
