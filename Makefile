SHELL := /bin/bash
UUID := $(shell jq -r '.uuid' metadata.json)
PACK_OUT := $(UUID).shell-extension.zip

.PHONY: check pack pack-zip pack-dual production install install-legacy

check:
	./scripts/check-all.sh

# Pack + install current GNOME (45-50) on this machine
pack:
	./scripts/pack-dual.sh
	./scripts/install-variant.sh gnome45-50

# Zip only — current GNOME variant, no install
pack-zip:
	./scripts/pack-dual.sh
	@echo "Artifacts in dist/ and $(PACK_OUT)"

# Both GNOME variants → dist/
pack-dual:
	./scripts/pack-dual.sh

# Full production: syntax, schema, dual pack, zip verify, shexli
production: check

install:
	./scripts/install-variant.sh gnome45-50

install-legacy:
	./scripts/install-variant.sh gnome40-44
