#!/usr/bin/env bash
# Runs the docgen test suite headlessly via plenary.busted.
# The minimal_init option keeps plenary's spawned spec processes off the user config.
cd "$(dirname "$0")/.." || exit 1
nvim --headless -u tests/minimal_init.lua \
  -c "PlenaryBustedDirectory tests/docgen { minimal_init = 'tests/minimal_init.lua' }"
