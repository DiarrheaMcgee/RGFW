OUT ?= out
AR ?= ar
.DEFAULT_GOAL = all

NO_GLES ?= 1
NO_OSMESA ?= 1
NO_EGL ?= 1
DIR := /
LIBM := -lm

DETECTED_OS = $(shell uname 2>/dev/null || echo unknown)

ifneq (,$(filter $(CC),emcc em++))
	DETECTED_OS := web
endif

ifneq (,$(filter $(CC),g++ clang++ em++))
	CPEEPEE := 1
else
	CPEEPEE := 0
endif

ifeq ($(WAYLAND_ONLY), 1)
	RGFW_WAYLAND := 1
endif

ifeq ($(DETECTED_OS),Linux)

	OBJ_EXT := .o
	STATIC_EXT := .a
	SHARED_EXT := .so
	DEFAULT_CFLAGS := -I./

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
	DEFAULT_CFLAGS := -I./
	NO_VULKAN := 1

	LIBS := -framework CoreVideo -framework Cocoa -framework OpenGL -framework IOKit

	ifeq ($(CPEEPEE),0)
		DEFAULT_CFLAGS += -Wno-deprecated -Wno-unknown-warning-option -Wno-pedantic
	endif

else ifeq ($(DETECTED_OS),web)

	EXT := .js
	DEFAULT_CFLAGS := -I./
	WASM_LINK_GL1 := -s LEGACY_GL_EMULATION -D LEGACY_GL_EMULATION -sGL_UNSAFE_OPTS=0
	WASM_LINK_GL2 := -s FULL_ES2 -s USE_WEBGL2
	WASM_LINK_GL3 := -s FULL_ES3 -s USE_WEBGL2
	WASM_LINK_OSMESA := -sALLOW_MEMORY_GROWTH
	WASM_LINK_MICROUI := -s USE_WEBGL2 $(WASM_LINK_GL1)
	LIBS := -s WASM=1 -s ASYNCIFY -s GL_SUPPORT_EXPLICIT_SWAP_CONTROL=1 -s EXPORTED_RUNTIME_METHODS="['stringToNewUTF8']"

else

	EXT = .exe
	OBJ_EXT := .obj
	STATIC_EXT = .lib
	SHARED_EXT = .dll

	ifeq ($(CC),cl)
		DEFAULT_CFLAGS := /I.\\ /D_WIN32_WINNT=0x0501
		LIBS := /link opengl32.lib /link gdi32.lib
		DIR := \\
		LIBM :=
		NO_VULKAN := 1
	else
		DEFAULT_CFLAGS := -I./
		ifneq ($(CC),zig cc)
			DEFAULT_CFLAGS += -D _WIN32_WINNT=0x0501
		endif
		DX11_LIBS := -static -lgdi32 -ldxgi -ld3d11 -luuid -ld3dcompiler
		VULKAN_LIBS := -lgdi32 -I $(VULKAN_SDK)/Include -L $(VULKAN_SDK)/Lib -lvulkan-1
		LIBS := -lopengl32 -static -lgdi32
	endif

	ifeq ($(CC),cc)
		CC := gcc
	endif

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
	rm -rf $(OUT)

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
ifeq ($(CC),cl)
	$(CC) $(DEFAULT_CFLAGS) examples$(DIR)$(basename $(notdir $@))$(DIR)$(basename $(notdir $@)).c $(EXTRA_SRC) $(CFLAGS) /Fe$(subst /,$(DIR),$@) $(LIBS)
else
	$(CC) $(DEFAULT_CFLAGS) examples/$(basename $(notdir $@))/$(basename $(notdir $@)).c $(EXTRA_SRC) $(CFLAGS) -o $@ $(LIBS) $(CUSTOM_LIBS)
endif

$(OUT)/RGFW$(OBJ_EXT): RGFW.h | $(OUT)
ifeq ($(CC),cl)
	$(CC) $(DEFAULT_CFLAGS) $(CFLAGS) /TC $(subst /,$(DIR),$^) /c /Fo$(subst /,$(DIR),$@)
else
	$(CC) -x c -c -D RGFW_NO_API -D RGFW_EXPORT -D RGFW_IMPLEMENTATION -c -fPIC $(DEFAULT_CFLAGS) $(CFLAGS) $^ -o $@
endif

$(OUT)/libRGFW$(STATIC_EXT): $(OUT)/RGFW$(OBJ_EXT) | $(OUT)
	ar rcs $(subst /,$(DIR),$@) $(subst /,$(DIR),$^)
libRGFW$(STATIC_EXT): $(OUT)/libRGFW$(STATIC_EXT) | $(OUT)

$(OUT)/libRGFW$(SHARED_EXT): $(OUT)/RGFW$(OBJ_EXT) | $(OUT)
ifeq ($(CC), cl)
	link /dll /out:$(subst /,$(DIR),$@) $(subst /,$(DIR),$^)
else
	$(CC) -shared -fPIC $(DEFAULT_CFLAGS) $(CFLAGS) $^ -o $@ $(LIBS) $(CUSTOM_LIBS)
endif
libRGFW$(SHARED_EXT): $(OUT)/libRGFW$(SHARED_EXT)

$(OUT)/basic.js:         LIBS += $(WASM_LINK_GL1)
$(OUT)/buffer.js:        LIBS += $(WASM_LINK_GL1)
$(OUT)/events.js:        LIBS += $(WASM_LINK_GL1)
$(OUT)/callbacks.js:     LIBS += $(WASM_LINK_GL1)
$(OUT)/flags.js:         LIBS += $(WASM_LINK_GL1)
$(OUT)/monitor.js:       LIBS += $(WASM_LINK_GL1)
$(OUT)/gl33_ctx.js:      LIBS += $(WASM_LINK_GL1)
$(OUT)/smooth-resize.js: LIBS += $(WASM_LINK_GL1)
$(OUT)/multi-window.js:  LIBS += $(WASM_LINK_GL1)
$(OUT)/icons.js:         LIBS += $(LIBM) $(WASM_LINK_GL1)
$(OUT)/gamepad.js:       LIBS += $(LIBM) $(WASM_LINK_GL1)
$(OUT)/camera.js:        LIBS += $(LIBM) $(WASM_LINK_GL1)
$(OUT)/gears.js:         LIBS += $(LIBM) $(WASM_LINK_GL1)
$(OUT)/gles2.js:         LIBS += $(WASM_LINK_GL2)
$(OUT)/gl33.js:          LIBS += $(WASM_LINK_GL3)
$(OUT)/osmesa_demo.js:   LIBS += -lOSMesa $(WASM_LINK_OSMESA)
$(OUT)/webgpu.js:        LIBS += -s USE_WEBGPU=1

$(OUT)/icons.exe:      LIBS += $(LIBM)
$(OUT)/gamepad.exe:    LIBS += $(LIBM)
$(OUT)/camera.exe:     LIBS += $(LIBM)
$(OUT)/portableGL.exe: LIBS += $(LIBM)
$(OUT)/gears.exe:      LIBS += $(LIBM)

$(OUT)/icons:       LIBS += $(LIBM)
$(OUT)/gamepad:     LIBS += $(LIBM)
$(OUT)/camera:      LIBS += $(LIBM)
$(OUT)/portableGL:  LIBS += $(LIBM)
$(OUT)/egl:         LIBS += -lEGL
$(OUT)/webgpu:      LIBS += -s USE_WEBGPU=1
$(OUT)/gears:       LIBS += $(LIBM)
$(OUT)/osmesa_demo: LIBS += $(LIBM) -lOSMesa

$(OUT)/microui_demo$(EXT): examples/microui_demo/microui.c examples/microui_demo/microui_demo.c
	$(CC) -Iexamples/microui $(DEFAULT_CFLAGS) $(CFLAGS) $(WASM_LINK_MICROUI) $^ $(LIBS) -o $@

$(OUT)/metal$(EXT): LIBS := -framework CoreVideo -framework Metal -framework Cocoa -framework IOKit -framework QuartzCore
$(OUT)/metal$(EXT): examples/metal/metal.m $(OUT)/RGFW$(OBJ_EXT)
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

ifneq (,$(filter $(CC),gcc g++))
	EVERYTHING += gears
endif

ifeq ($(DETECTED_OS),Darwin)
	EVERYTHING += metal
endif

ifeq ($(DETECTED_OS),web)
	EVERYTHING += webgpu microui_demo
else
	EVERYTHING += portableGL
endif

$(EVERYTHING): %: $(OUT)/%$(EXT)

all: $(EVERYTHING)

