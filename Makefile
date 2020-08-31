
.PHONY: all
all: lint

.PHONY: lint
lint:
	luacheck .

.PHONY: bumpversion
bumpversion:
	@./scripts/bumpversion.sh
