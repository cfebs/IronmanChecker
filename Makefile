
.PHONY: all
all: lint

.PHONY: lint
lint:
	luacheck .
