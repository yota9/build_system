DIRECTORY = $$(@D)/directory.checked
%/directory.checked:
	$(if $(V),, @echo MKDIR $(@D))
	@mkdir -p $(@D)
	@touch $@

_RUN = @echo $(strip $(1)) $(strip $(2))

ifeq ($(V),@)
  VERBOSITY_RUN = @$(strip $(1)) || (echo "$(strip $(1))"; exit 1)
else
  VERBOSITY_RUN = $(strip $(1))
endif

define RUN
$(if $(3), $(error Pass parameters with commas through variables))
	$(call _RUN, $(strip $(1)), $@ $$@)
	$(call VERBOSITY_RUN, $(2))
endef

CC_STR = $$(CC) -c $$(FLAGS) $$^ -o $$@
define COMPILE
@echo $(CC_STR) > $$@.cmd
$(call RUN,CC, $(CC_STR))
endef

LD_STR = $$(CC) $$(FLAGS) $$^ -o $$@ $$(LDLIBS)
define LINK
@echo $(LD_STR) > $$@.cmd
$(call RUN,LD, $(LD_STR))
endef

AR_STR = $$(AR) $$(ARFLAGS) $$@ $$^
define ARCHIVE
@echo $(AR_STR) > $$@.cmd
$(call RUN,AR, $(AR_STR))
endef

DTC_STR = $$(DTC) -I dts -O dtb $$< > $$@
define RUN_DTC
@echo $(DTC_STR) > $$@.cmd
$(call RUN,DTC, $(DTC_STR))
endef

define STRIP_ELF
$(call RUN,STRIP,\
$$(STRIP) $$@)
endef

define FILTER_OUT_TOOLCHAIN_FLAGS
$(eval CC_$(0) := $(strip $(1)))
$(eval TARGET_$(0) := $(strip $(2)))
$(eval TARGET_FLAGS_$(0) := $(strip $(3)))
$(eval OUT_FLAGS_$(0) := $(strip $(4)))
$(eval TFLAGS_$(0) := $(if $(filter $(ARCH)%, $(shell $(CC_$(0)) -dumpmachine)), $(C_TFLAGS_$(ARCH)),)) #VAR

# GCC could not receive multiple mfloat-abi options
$(eval TFLAGS_$(0) := $(if $(filter -mfloat-abi%,$(TARGET_FLAGS_$(0))), \
     $(filter-out -mfloat-abi%, $(TFLAGS_$(0))), $(TFLAGS_$(0))))

$(if $(OUT_FLAGS_$(0)), $(eval $(OUT_FLAGS_$(0)) += $(TFLAGS_$(0)) $(TARGET_FLAGS_$(0))),)
$(TARGET_$(0)): FLAGS = $(TFLAGS_$(0)) $(TARGET_FLAGS_$(0))
endef

define BUILD_OBJECT
$(eval CC_$(0) := $(strip $(1)))
$(eval SRC_$(0) := $(strip $(2)))
$(eval SRC_DIR_$(0) := $(strip $(3)))
$(eval OBJ_DIR_$(0) := $(strip $(4)))
$(eval CFLAGS_$(0) := $(strip $(5)) -I$(COMMON_PATH))

$(eval OBJ_NAME_$(0) := $(SRC_$(0)).o)
$(eval OBJ_$(0) := $(OBJ_DIR_$(0))/$(OBJ_NAME_$(0)))

$(eval MK_NAME_$(0) := $(subst $(CURDIR)/,,$(SRC_DIR_$(0)))/$(OBJ_NAME_$(0)))
$(eval $(MK_NAME_$(0)) := $(OBJ_$(0)))

$(OBJ_$(0)): CC = $(CC_$(0))
$(call FILTER_OUT_TOOLCHAIN_FLAGS, $(CC_$(0)), $(OBJ_$(0)), $(CFLAGS_$(0)))

TARGETS += $(OBJ_$(0))
$(OBJ_$(0)): $(SRC_DIR_$(0))/$(SRC_$(0)) | $$(DIRECTORY)
	$(call COMPILE)
endef

define BUILD_ALL_OBJECTS
$(eval CC_$(0) := $(strip $(1)))
$(eval SRC_$(0) := $(strip $(2)))
$(eval SRC_DIR_$(0) := $(strip $(3)))
$(eval OBJ_DIR_$(0) := $(strip $(4)))
$(eval CFLAGS_$(0) := $(strip $(5)))

$(foreach source, \
          $(SRC_$(0)), \
          $(call BUILD_OBJECT, \
                 $(CC_$(0)), \
                 $(source), \
                 $(SRC_DIR_$(0)), \
                 $(OBJ_DIR_$(0)), \
                 $(CFLAGS_$(0)), \
))
endef

define NEEDED_LIBRARIES
$(eval OBJ_$(0) := $(strip $(1)))
$(eval DEPEND_$(0) := $(strip $(2)))
$(OBJ_$(0)): $(DEPEND_$(0))
$(OBJ_$(0)): NEEDED_LIBS += $(DEPEND_$(0))
endef

define LINK_OBJECTS
$(eval CC_$(0) := $(strip $(1)))
$(eval OBJ_$(0) := $(strip $(2)))
$(eval OBJ_DIR_$(0) := $(strip $(3)))
$(eval LDFLAGS_$(0) := $(strip $(4)))
$(eval LDLIBS_$(0) := $(strip $(5)))
$(eval SRC_$(0) := $(strip $(6)))
$(eval EXTRA_OBJS_$(0) := $(strip $(7)))

$(eval OBJ_FILES_$(0) := $(SRC_$(0)))
$(eval OBJ_FILES_$(0) := $(addprefix $(OBJ_DIR_$(0))/, $(OBJ_FILES_$(0))))
$(eval OBJ_FILES_$(0) := $(addsuffix .o, $(OBJ_FILES_$(0))))

$(OBJ_$(0)): CC = $(CC_$(0))
$(call FILTER_OUT_TOOLCHAIN_FLAGS, $(CC_$(0)), $(OBJ_$(0)), $(LDFLAGS_$(0)))
$(OBJ_$(0)): LDLIBS = -Wl,--start-group $$(NEEDED_LIBS) $(LDLIBS_$(0)) -Wl,--end-group


TARGETS += $(OBJ_$(0))
$(OBJ_$(0)): $(OBJ_FILES_$(0)) $(EXTRA_OBJS_$(0))
	$(call LINK)
endef

define CREATE_ARCHIVE
# TODO use AR based on CC or remove CC param from other macroses
$(eval OBJ_$(0) := $(strip $(1)))
$(eval OBJ_DIR_$(0) := $(strip $(2)))
$(eval SRC_$(0) := $(strip $(3)))

$(eval OBJ_FILES_$(0) := $(SRC_$(0)))
$(eval OBJ_FILES_$(0) := $(addprefix $(OBJ_DIR_$(0))/, $(OBJ_FILES_$(0))))
$(eval OBJ_FILES_$(0) := $(addsuffix .o, $(OBJ_FILES_$(0))))

$(OBJ_$(0)): AR = $(AR)
$(OBJ_$(0)): ARFLAGS = -rcs

TARGETS += $(OBJ_$(0))
$(OBJ_$(0)): $(OBJ_FILES_$(0))
	$(call ARCHIVE)
endef

define CREATHE_THIN_ARCHIVE
$(eval OBJ_$(0) := $(strip $(1)))
$(eval ARCHIVES_$(0) := $(strip $(2)))

$(OBJ_$(0)): AR = $(AR)
$(OBJ_$(0)): ARFLAGS = -rcT

TARGETS += $(OBJ_$(0))
$(OBJ_$(0)):
	$(V) cd $$(@D) && $(AR_STR) $(ARCHIVES_$(0))
endef

define BUILD_EXECUTABLE
$(eval CC_$(0) := $(strip $(1)))
$(eval WORLD_$(0) := $(strip $(2)))
$(eval SRC_$(0) := $(strip $(3)))
$(eval SRC_DIR_$(0) := $(strip $(4)))
$(eval SRC_DIR_NAME_$(0) := $(subst $(CURDIR)/,,$(SRC_DIR_$(0)))) #VAR
$(eval NAME_$(0) := $(strip $(5)))
$(eval OBJ_DIR_$(0) := $(OBJDIR)/$(SRC_DIR_NAME_$(0))) #VAR
$(eval OBJ_$(0) := $(OBJ_DIR_$(0))/$(NAME_$(0))) #VAR
$(eval CFLAGS_$(0) := $(strip $(6)))
$(eval LDFLAGS_$(0) := $(strip $(7)))
$(eval LDLIBS_$(0) := $(strip $(8)))
$(eval EXTRA_OBJS_$(0) := $(strip $(9)))

$(eval MK_NAME_$(0) := $(subst $(CURDIR)/,,$(SRC_DIR_$(0)))/$(NAME_$(0)))
$(eval $(MK_NAME_$(0)) := $(OBJ_$(0)))

$(call BUILD_ALL_OBJECTS, \
       $(CC_$(0)), \
       $(SRC_$(0)), \
       $(SRC_DIR_$(0)), \
       $(OBJ_DIR_$(0)), \
       $(CFLAGS_$(WORLD_$(0))) $(CFLAGS_$(0)) \
)

$(call LINK_OBJECTS, \
       $(CC_$(0)), \
       $(OBJ_$(0)), \
       $(OBJ_DIR_$(0)), \
       $(LDFLAGS_$(WORLD_$(0))) $(LDFLAGS_$(0)), \
       $(LDLIBS_$(WORLD_$(0))) $(LDLIBS_$(0)), \
       $(SRC_$(0)), \
       $(EXTRA_OBJS_$(0)) \
)
endef

define BUILD_LIBRARY
$(eval CC_$(0) := $(strip $(1)))
$(eval WORLD_$(0) := $(strip $(2)))
$(eval SRC_$(0) := $(strip $(3)))
$(eval SRC_DIR_$(0) := $(strip $(4)))
$(eval SRC_DIR_NAME_$(0) := $(subst $(CURDIR)/,,$(SRC_DIR_$(0)))) #VAR
$(eval NAME_$(0) := $(strip $(5)))
$(eval LIB_$(0) := lib$(NAME_$(0))) #VAR
$(eval OBJ_DIR_$(0) := $(OBJDIR)/$(SRC_DIR_NAME_$(0))/$(LIB_$(0))) #VAR
$(eval OBJ_$(0) := $(OBJ_DIR_$(0))/$(LIB_$(0))) #VAR
$(eval CFLAGS_$(0) := $(strip $(6)))
$(eval LDFLAGS_$(0) := $(strip $(7)))
$(eval LDLIBS_$(0) := $(strip $(8)))

$(call BUILD_ALL_OBJECTS, \
       $(CC_$(0)), \
       $(SRC_$(0)), \
       $(SRC_DIR_$(0)), \
       $(OBJ_DIR_$(0)), \
       $(CFLAGS_$(WORLD_$(0))) $(CFLAGS_$(0)) \
)

$(eval OBJ_SO_LIBRARY_$(0) := $(OBJ_$(0)).so)
$(eval OBJ_A_LIBRARY_$(0) := $(OBJ_$(0)).a)
# Dependency variable ex. $(name/libname.so)
$(eval MK_NAME_$(0) := $(subst $(CURDIR)/,,$(SRC_DIR_$(0)))/$(LIB_$(0)))
$(eval $(MK_NAME_$(0)).so := $(OBJ_SO_LIBRARY_$(0)))
$(eval $(MK_NAME_$(0)).a := $(OBJ_A_LIBRARY_$(0)))

$(call LINK_OBJECTS, \
       $(CC_$(0)), \
       $(OBJ_SO_LIBRARY_$(0)), \
       $(OBJ_DIR_$(0)), \
       -shared $(LDFLAGS_$(WORLD_$(0))) $(LDFLAGS_$(0)), \
       $(LDLIBS_$(WORLD_$(0))) $(LDLIBS_$(0)), \
       $(SRC_$(0)) \
)

$(call CREATE_ARCHIVE, \
       $(OBJ_A_LIBRARY_$(0)), \
       $(OBJ_DIR_$(0)), \
       $(SRC_$(0)) \
)

endef

define BUILD_DTB
$(eval DTC_$(0) := $(strip $(1)))
$(eval SRC_$(0) := $(strip $(2)))
$(eval SRC_DIR_$(0) := $(strip $(3)))
$(eval SRC_DIR_NAME_$(0) := $(subst $(CURDIR)/,,$(SRC_DIR_$(0)))) #VAR
$(eval OBJ_DIR_$(0) := $(OBJDIR)/$(SRC_DIR_NAME_$(0))) #VAR
$(eval OBJ_$(0) := $(OBJ_DIR_$(0))/$(subst .dts,.dtb,$(SRC_$(0)))) #VAR

$(eval MK_NAME_$(0) := $(subst $(CURDIR)/,,$(SRC_DIR_$(0)))/$(SRC_$(0)))
$(eval $(MK_NAME_$(0)) := $(OBJ_$(0)))

TARGETS += $(OBJ_$(0))
$(OBJ_$(0)): DTC = $(DTC_$(0))
$(OBJ_$(0)): $(SRC_DIR_$(0))/dts/$(SRC_$(0)) | $$(DIRECTORY)
	$(call RUN_DTC)
endef
