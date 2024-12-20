LXDIALOG_SRC := \
  lxdialog/checklist.c \
  lxdialog/inputbox.c \
  lxdialog/menubox.c \
  lxdialog/textbox.c \
  lxdialog/util.c \
  lxdialog/yesno.c

KCONFIG_SRC := \
  confdata.c \
  expr.c \
  lexer.lex.c \
  mconf.c \
  menu.c \
  mnconf-common.c \
  parser.tab.c \
  preprocess.c \
  symbol.c \
  util.c

$(eval $(call BUILD_LIBRARY, \
       $(CC_HOST), \
       HOST, \
       $(LXDIALOG_SRC), \
       $(KCONFIGDIR), \
       lxdialog, \
       -fPIC -I$(KCONFIGDIR) -Wno-extra -Wno-all, \
))

ifneq ($(filter menuconfig, $(MAKECMDGOALS)),)
$(eval $(call BUILD_EXECUTABLE, \
       $(CC_HOST), \
       HOST, \
       $(KCONFIG_SRC), \
       $(KCONFIGDIR), \
       menuconfig, \
       -fPIC -I$(KCONFIGDIR) -Wno-extra -Wno-all, \
	   -pie,\
))

$(eval $(call NEEDED_LIBRARIES, \
       $(build_system/kconfig/menuconfig), \
       $(build_system/kconfig/liblxdialog.a) \
       -lncurses \
))
endif # menuconfig
