define CHECKOPTION
$(eval OPTION := $(strip $(1)))
$(eval VALUES := $(strip $(2)))
ifneq ($(3),)
  $$(error CHECKOPTION mast have only 2 params)
endif
ifeq ($(filter $($(OPTION)), $(VALUES)),)
  $$(error Unknown value $($(OPTION)) for $(OPTION); possible values are: $(VALUES))
endif
endef

define TO_LOWER
$(shell echo $(strip $(1)) | tr '[:upper:]' '[:lower:]')
endef

define TO_UPPER
$(shell echo $(strip $(1)) | tr '[:lower:]' '[:upper:]')
endef

define GET_Y_N
$(strip
$(eval TMP_$(0) := $(subst yes,y,$(call TO_LOWER,$(1))))
$(subst no,n,$(TMP_$(0))))
endef
