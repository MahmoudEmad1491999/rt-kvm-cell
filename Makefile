.PHONY: images run check ci clean

# Build all Buildroot images (L1 cell host + L2 guests).
# Implemented in Phase 0 step 3 of the roadmap.
images:
	@echo "TODO: images not yet implemented (see ROADMAP.md Phase 0)" && exit 1

# Boot the L1 cell-host VM in QEMU.
# Implemented in Phase 0 step 4 of the roadmap.
run:
	@echo "TODO: run not yet implemented (see ROADMAP.md Phase 0)" && exit 1

# Run all host-side unit and integration tests that exist.
check:
	@echo "check: no tests yet"

# Fast CI subset: shellcheck + unit tests. No image builds.
ci:
	ci/check.sh

clean:
	rm -rf output/ build/
