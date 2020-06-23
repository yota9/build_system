ifeq ($(wildcard $(BUILD_DIR)/config.mk),)
  $(error Choose config.mk from configs folder)
endif

define CHECKTOOLCHAIN
ifeq ($(shell $(CC) --version),)
  $$(error Check TOOLCHAIN_TRIPLET option, no such toolchain)
endif
ifeq ($(shell $(CC_NWD) --version),)
  $$(error Check NWD_ARM_TOOLCHAIN_TRIPLET option, no such toolchain)
endif
endef

define CHANGE_CONFIG
$(eval CONFIG_$(0) := $(strip $(1)))
$(eval PARAM_$(0) := $(strip $(2)))
$(eval VALUE_$(0) := $(strip $(3)))
grep -q $(PARAM_$(0)) $(CONFIG_$(0)) && \
sed -ie '/$(PARAM_$(0))/c\$(PARAM_$(0))=$(VALUE_$(0))' $(CONFIG_$(0)) || \
echo $(PARAM_$(0))=$(VALUE_$(0)) >> $(CONFIG_$(0))
endef

BUILD_TYPES_LIST = debug release
