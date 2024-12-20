CFLAGS_OPTIMIZATION = -Os -Wall -Wextra -Werror
CFLAGS_COMMON = -g -ggdb $(CFLAGS_OPTIMIZATION) -fPIC

CFLAGS_SWD_COMMON = $(CFLAGS_COMMON) -nostdlib
CFLAGS_NWD_COMMON = $(CFLAGS_COMMON)
CFLAGS_HOST_COMMON = $(CFLAGS_COMMON)

CFLAGS_ARM_COMMON = -D__$(PLATFORM)__ -mcpu=$(CPU)
CFLAGS_SWD_ARM = $(CFLAGS_SWD_COMMON) $(CFLAGS_ARM_COMMON)
CFLAGS_NWD_ARM = $(CFLAGS_NWD_COMMON) $(CFLAGS_ARM_COMMON)

CURRENT_PLATFORM = $(call TO_UPPER, $(PLATFORM))
CFLAGS_SWD = $(CFLAGS_SWD_$(CURRENT_PLATFORM))
CFLAGS_NWD = $(CFLAGS_NWD_$(CURRENT_PLATFORM))
CFLAGS_HOST = $(CFLAGS_HOST_COMMON)
