SHELL := /bin/bash
PLUGIN_ID := $(shell jq -r '.KPlugin.Id' metadata.json)
PACK_OUT := dist/$(PLUGIN_ID).plasmoid

.PHONY: check pack install

check:
	./scripts/check-all.sh

pack:
	./scripts/pack-plasmoid.sh

install:
	./install.sh
