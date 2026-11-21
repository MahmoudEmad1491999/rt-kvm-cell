.PHONY: images run check ci clean submodule-init

BUILDROOT       := buildroot
BR2_EXT         := $(CURDIR)/br2-external
OUTPUT_CELLHOST := $(CURDIR)/output/cellhost
DL_DIR          := $(HOME)/.cache/rt-kvm-cell/dl

# Populate the Buildroot submodule (run once after clone).
submodule-init:
	git submodule update --init --depth=1 $(BUILDROOT)

# Build all Buildroot images (L1 cell host; guests added in Phase 1).
images: images-cellhost

images-cellhost:
	mkdir -p $(OUTPUT_CELLHOST) $(DL_DIR)
	$(MAKE) -C $(BUILDROOT) \
		O=$(OUTPUT_CELLHOST) \
		BR2_EXTERNAL=$(BR2_EXT) \
		BR2_DL_DIR=$(DL_DIR) \
		cellhost_defconfig
	$(MAKE) -C $(BUILDROOT) \
		O=$(OUTPUT_CELLHOST) \
		BR2_DL_DIR=$(DL_DIR) \
		-j$(shell nproc)

# Boot the L1 cell-host VM in QEMU (requires 'make images' first).
run:
	scripts/run-l1.sh

# Run all host-side unit and integration tests that exist.
check:
	@echo "check: no tests yet"

# Fast CI subset: shellcheck + unit tests. No image builds.
ci:
	ci/check.sh

clean:
	rm -rf output/ build/
