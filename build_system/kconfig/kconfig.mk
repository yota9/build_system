LXDIALOG_SRC := \
  lxdialog/checklist.c \
  lxdialog/inputbox.c \
  lxdialog/menubox.c \
  lxdialog/textbox.c \
  lxdialog/util.c \
  lxdialog/yesno.c

KCONFIG_COMMON := \
  confdata.c \
  expr.c \
  lexer.lex.c \
  menu.c \
  parser.tab.c \
  preprocess.c \
  symbol.c \
  util.c

MENUCONFIG_SRC := \
  $(KCONFIG_COMMON) \
  mconf.c \
  mnconf-common.c

NCONFIG_SRC := \
  $(KCONFIG_COMMON) \
  nconf.c \
  nconf.gui.c \
  mnconf-common.c

$(eval $(call BUILD_LIBRARY, \
       $(CC_HOST), \
       HOST, \
       $(LXDIALOG_SRC), \
       $(KCONFIGDIR), \
       lxdialoghost, \
       -fPIC -I$(KCONFIGDIR) -Wno-extra -Wno-all, \
))

ifneq ($(filter menuconfig, $(MAKECMDGOALS)),)
$(eval $(call BUILD_EXECUTABLE, \
       $(CC_HOST), \
       HOST, \
       $(MENUCONFIG_SRC), \
       $(KCONFIGDIR), \
       menuconfig, \
       -fPIC -I$(KCONFIGDIR) -Wno-extra -Wno-all, \
	   -pie,\
	   -lncurses,\
))

$(eval $(call NEEDED_LIBRARIES, \
       $(build_system/kconfig/menuconfig), \
       $(build_system/kconfig/liblxdialoghost.a) \
))
endif # menuconfig

ifneq ($(filter nconfig, $(MAKECMDGOALS)),)
$(eval $(call BUILD_EXECUTABLE, \
       $(CC_HOST), \
       HOST, \
       $(NCONFIG_SRC), \
       $(KCONFIGDIR), \
       nconfig, \
       -fPIC -I$(KCONFIGDIR) -Wno-extra -Wno-all, \
	   -pie,\
	   -lmenu -lncurses -lpanel,\
))
endif # nconfig
