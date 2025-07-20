DEFAULT_CFLAGS := -I./
OUT            ?= out
CC             ?= cc
AR             ?= ar
.DEFAULT_GOAL   = all

NO_GLES ?= 1
NO_OSMESA ?= 1
NO_EGL ?= 1

DETECTED_OS = $(shell uname 2>/dev/null || echo unknown)

ifneq (,$(filter $(CC),emcc em++))
	DETECTED_OS := web
endif

ifneq (,$(filter $(CC),g++ clang++ em++))
	CPEEPEE := 1
else
	CPEEPEE := 0
endif

ifneq ($(CC),zig cc)
	DEFAULT_CFLAGS += -D _WIN32_WINNT=0x0501
endif

ifeq ($(WAYLAND_ONLY), 1)
	RGFW_WAYLAND := 1
endif

ifeq ($(DETECTED_OS),Linux)

	OBJ_EXT := .o
	STATIC_EXT := .a
	SHARED_EXT := .so

	ifeq ($(RGFW_WAYLAND),1)

		EXTRA_SRC := \
		       $(OUT)/xdg/relative-pointer-unstable-v1-client-protocol.c \
		       $(OUT)/xdg/xdg-decoration-unstable-v1.c \
		       $(OUT)/xdg/xdg-shell.c \
		       $(OUT)/xdg/relative-pointer-unstable-v1-client-protocol.h \
		       $(OUT)/xdg/xdg-decoration-unstable-v1.h \
		       $(OUT)/xdg/xdg-shell.h

		LIBS := -ldl -lEGL -lGL -lwayland-egl -lwayland-cursor -lwayland-client -lxkbcommon
		VULKAN_LIBS := -ldl -lEGL -lGL -lwayland-egl -lwayland-cursor -lwayland-client -lxkbcommon -lvulkan
		DEFAULT_CFLAGS += -D RGFW_WAYLAND -I$(OUT)/xdg
		NO_VULKAN := 1

		ifeq ($(WAYLAND_ONLY),1)
			DEFAULT_CFLAGS += -D RGFW_NO_X11
		else
			LIBS += -lX11 -lXrandr
		endif

	else

		LIBS := -lX11 -lXrandr -ldl -lGL
		VULKAN_LIBS := -lX11 -lXrandr -ldl -lpthread -lvulkan

	endif

else ifeq ($(DETECTED_OS),Darwin)

	OBJ_EXT := .o
	STATIC_EXT := .a
	SHARED_EXT := .dylib

	LIBS := -framework CoreVideo -framework Cocoa -framework OpenGL -framework IOKit

	ifeq ($(CPEEPEE),0)
		DEFAULT_CFLAGS += -Wno-deprecated -Wno-unknown-warning-option -Wno-pedantic
	endif

else ifeq ($(DETECTED_OS),web)

	EXT := .js
	WASM_LINK_GL1 := -s LEGACY_GL_EMULATION -D LEGACY_GL_EMULATION -sGL_UNSAFE_OPTS=0
	WASM_LINK_GL2 := -s FULL_ES2 -s USE_WEBGL2
	WASM_LINK_GL3 := -s FULL_ES3 -s USE_WEBGL2
	WASM_LINK_OSMESA := -sALLOW_MEMORY_GROWTH
	WASM_LINK_MICROUI := -s USE_WEBGL2 $(WASM_LINK_GL1)
	LIBS := -s WASM=1 -s ASYNCIFY -s GL_SUPPORT_EXPLICIT_SWAP_CONTROL=1 -s EXPORTED_RUNTIME_METHODS="['stringToNewUTF8']"

else

	EXT = .exe
	STATIC_EXT = .lib
	SHARED_EXT = .dll
	DX11_LIBS := -static -lgdi32 -ldxgi -ld3d11 -luuid -ld3dcompiler
	VULKAN_LIBS := -lgdi32 -I $(VULKAN_SDK)/Include -L $(VULKAN_SDK)/Lib -lvulkan-1
	LIBS := -lopengl32 -static -lgdi32 -ggdb

endif

ifneq ($(DETECTED_OS),Linux)
	RGFW_WAYLAND := 0
endif

ifeq ($(CPEEPEE),1)
	ifneq ($(DETECTED_OS),Darwin)
		ifeq ($(CPEEPEE),1)
			DEFAULT_CFLAGS += -x c -Wall -Wextra -Wpedantic -Wconversion -Wsign-conversion -Wshadow -Wpointer-arith -Wvla -Wcast-align -Wstrict-overflow -Wstrict-aliasing -Wredundant-decls -Winit-self -Wmissing-noreturn
		else ifneq ($(CC),emcc)
			DEFAULT_CFLAGS += -Wall -Wextra -Wstrict-prototypes -Wold-style-definition -Wpedantic -Wconversion -Wsign-conversion -Wshadow -Wpointer-arith -Wvla -Wcast-align -Wstrict-overflow -Wnested-externs -Wstrict-aliasing -Wredundant-decls -Winit-self -Wmissing-noreturn
		endif

endif

	NO_VULKAN := 1
endif

.PHONY: clean
clean:
	-rm -rf $(OUT)

$(OUT):
	mkdir -p $(OUT)

$(OUT)/xdg: | $(OUT)
	mkdir $(OUT)/xdg

$(OUT)/xdg/xdg-shell.h: | $(OUT)/xdg
	wayland-scanner client-header /usr/share/wayland-protocols/stable/xdg-shell/xdg-shell.xml $(OUT)/xdg/xdg-shell.h
$(OUT)/xdg/xdg-shell.c: | $(OUT)/xdg
	wayland-scanner public-code /usr/share/wayland-protocols/stable/xdg-shell/xdg-shell.xml $(OUT)/xdg/xdg-shell.c
$(OUT)/xdg/xdg-decoration-unstable-v1.h: | $(OUT)/xdg
	wayland-scanner client-header /usr/share/wayland-protocols/unstable/xdg-decoration/xdg-decoration-unstable-v1.xml $(OUT)/xdg/xdg-decoration-unstable-v1.h
$(OUT)/xdg/xdg-decoration-unstable-v1.c: | $(OUT)/xdg
	wayland-scanner public-code /usr/share/wayland-protocols/unstable/xdg-decoration/xdg-decoration-unstable-v1.xml $(OUT)/xdg/xdg-decoration-unstable-v1.c
$(OUT)/xdg/relative-pointer-unstable-v1-client-protocol.h: | $(OUT)/xdg
	wayland-scanner client-header /usr/share/wayland-protocols/unstable/relative-pointer/relative-pointer-unstable-v1.xml $(OUT)/xdg/relative-pointer-unstable-v1-client-protocol.h
$(OUT)/xdg/relative-pointer-unstable-v1-client-protocol.c: | $(OUT)/xdg
	wayland-scanner client-header /usr/share/wayland-protocols/unstable/relative-pointer/relative-pointer-unstable-v1.xml $(OUT)/xdg/relative-pointer-unstable-v1-client-protocol.c

$(OUT)/%$(EXT): $(EXTRA_SRC) RGFW.h | $(OUT)
	@mkdir -p $(dir $@)
	$(CC) $(DEFAULT_CFLAGS) $(CFLAGS) examples/$(basename $(notdir $@))/$(basename $(notdir $@)).c $(EXTRA_SRC) $(LIBS) -o $@

$(OUT)/RGFW$(OBJ_EXT): DEFAULT_CFLAGS += -x c -D RGFW_NO_API -D RGFW_EXPORT -D RGFW_IMPLEMENTATION
$(OUT)/RGFW$(OBJ_EXT): RGFW.h | $(OUT)
	$(CC) -c -fPIC $(DEFAULT_CFLAGS) $(CFLAGS) $^ -o $@

$(OUT)/libRGFW$(STATIC_EXT): $(OUT)/RGFW$(OBJ_EXT) | $(OUT)
	ar rcs $@ $^
libRGFW$(STATIC_EXT): $(OUT)/libRGFW$(STATIC_EXT) | $(OUT)

$(OUT)/libRGFW$(SHARED_EXT): $(OUT)/RGFW$(OBJ_EXT) | $(OUT)
	$(CC) -shared -fPIC $(DEFAULT_CFLAGS) $(CFLAGS) $^ $(LIBS) -o $@
libRGFW$(SHARED_EXT): $(OUT)/libRGFW$(SHARED_EXT)

$(OUT)/basic$(EXT):         LIBS += $(WASM_LINK_GL1)
$(OUT)/buffer$(EXT):        LIBS += $(WASM_LINK_GL1)
$(OUT)/events$(EXT):        LIBS += $(WASM_LINK_GL1)
$(OUT)/callbacks$(EXT):     LIBS += $(WASM_LINK_GL1)
$(OUT)/flags$(EXT):         LIBS += $(WASM_LINK_GL1)
$(OUT)/monitor$(EXT):       LIBS += $(WASM_LINK_GL1)
$(OUT)/gl33_ctx$(EXT):      LIBS += $(WASM_LINK_GL1)
$(OUT)/smooth-resize$(EXT): LIBS += $(WASM_LINK_GL1)
$(OUT)/multi-window$(EXT):  LIBS += $(WASM_LINK_GL1)
$(OUT)/icons$(EXT):         LIBS += -lm $(WASM_LINK_GL1)
$(OUT)/gamepad$(EXT):       LIBS += -lm $(WASM_LINK_GL1)
$(OUT)/silk$(EXT):          LIBS += -lm $(WASM_LINK_GL1)
$(OUT)/camera$(EXT):        LIBS += -lm $(WASM_LINK_GL1)
$(OUT)/gl33$(EXT):          LIBS += $(WASM_LINK_GL3)
$(OUT)/portableGL$(EXT):    LIBS += -lm
$(OUT)/gles2$(EXT):         LIBS += $(WASM_LINK_GL2)
$(OUT)/egl$(EXT):           LIBS += -lEGL
$(OUT)/webgpu$(EXT):        LIBS := -s USE_WEBGPU=1
$(OUT)/gears$(EXT):         LIBS += -lm $(WASM_LINK_GL1)
$(OUT)/osmesa_demo$(EXT):   LIBS += -lm -lOSMesa $(WASM_LINK_OSMESA)

$(OUT)/microui_demo$(EXT): examples/microui_demo/microui.c examples/microui_demo/microui_demo.c
	$(CC) -Iexamples/microui $(DEFAULT_CFLAGS) $(CFLAGS) $(WASM_LINK_MICROUI) $^ $(LIBS) -o $@

$(OUT)/metal$(EXT): EXTRA_SRC := $(OUT)/RGFW$(OBJ_EXT) LIBS := -framework CoreVideo -framework Metal -framework Cocoa -framework IOKit -framework QuartzCore
$(OUT)/metal$(EXT): examples/metal/metal.m
	$(CC) $(DEFAULT_CFLAGS) $(CFLAGS) $^ $(LIBS) -o $@

$(OUT)/vk10$(EXT): examples/vk10/vk10.c
	@mkdir -p $(OUT)/shaders
	glslangValidator -V examples/vk10/shaders/vert.vert -o $(OUT)/shaders/vert.h --vn vert_code
	glslangValidator -V examples/vk10/shaders/frag.frag -o $(OUT)/shaders/frag.h --vn frag_code
	$(CC) -I$(OUT) $(DEFAULT_CFLAGS) $(CFLAGS) $^ $(VULKAN_LIBS) -o $@

EVERYTHING := \
	basic \
	buffer \
	events \
	callbacks \
	flags \
	monitor \
	gl33_ctx \
	smooth-resize \
	multi-window \
	icons \
	camera \
	gl33

ifeq ($(DETECTED_OS),Linux)
	ifneq ($(NO_VULKAN),1)
		EVERYTHING += vk10
	endif
endif

ifneq ($(NO_GLES),1)
	EVERYTHING += gles2
endif

ifneq ($(NO_OSMESA),1)
	EVERYTHING += osmesa_demo
endif

ifneq ($(NO_EGL),1)
	EVERYTHING += egl
endif

ifeq ($(CPEEPEE),0)
	EVERYTHING += silk
endif

ifeq ($(DETECTED_OS),Darwin)
	EVERYTHING += metal
endif

ifeq ($(DETECTED_OS),web)
	EVERYTHING += webgpu microui_demo
else
	EVERYTHING += \
		      portableGL \
		      gears
endif

$(EVERYTHING): %: $(OUT)/%$(EXT)

all: $(EVERYTHING)

