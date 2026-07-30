# Noise app template — build pipeline.
#
# Compiles the Racket backend into app/res/core.zo (self-contained runtime +
# module bytecode) and generates the Swift Backend.swift client from the
# define-record / define-rpc declarations.
#
# Run `make` whenever you change app-core/*.rkt. (Run `./bin/setup` first, and
# again whenever your Racket version changes.)

ARCH      = $(shell uname -m)
APP_SRC   = app
RKT_SRC   = app-core
RKT_FILES = $(shell find $(RKT_SRC) -name '*.rkt')
RKT_MAIN  = $(RKT_SRC)/main.rkt

RESOURCES_PATH = $(APP_SRC)/res
RUNTIME_NAME   = runtime-$(ARCH)
RUNTIME_PATH   = $(RESOURCES_PATH)/$(RUNTIME_NAME)
CORE_ZO        = $(RESOURCES_PATH)/core.zo

.PHONY: all clean

all: $(CORE_ZO) $(APP_SRC)/Backend.swift

# --- 1. compile Racket to bytecode bundle --------------------------------
$(CORE_ZO): $(RKT_FILES)
	mkdir -p $(RESOURCES_PATH)
	rm -fr $(RUNTIME_PATH)
	raco ctool \
		--runtime $(RUNTIME_PATH) \
		--runtime-access $(RUNTIME_NAME) \
		--mods $@ $(RKT_MAIN)

# --- 2. generate the Swift client ----------------------------------------
# Uses `raco noise-serde-codegen` when registered; falls back to invoking
# the codegen submodule directly (when noise-serde-lib was installed with
# --no-setup).
$(APP_SRC)/Backend.swift: $(RKT_FILES)
	@if raco noise-serde-codegen $(RKT_MAIN) > $@ 2>/dev/null; then \
		echo "[codegen] raco noise-serde-codegen"; \
	else \
		echo "[codegen] fallback: direct submodule"; \
		./bin/codegen $(RKT_MAIN) > $@; \
	fi

clean:
	rm -rf $(RESOURCES_PATH)
