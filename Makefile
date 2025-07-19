DEFAULT_CFLAGS := -I./
CC             ?= cc
AR             ?= ar
.DEFAULT_GOAL   = all

NO_GLES ?= 1
NO_OSMESA ?= 1
NO_EGL ?= 1

DETECTED_OS = $(shell uname 2>/dev/null || echo Unknown)

ifneq (,$(filter $(CC),emcc em++))
	DETECTED_OS := web
endif

ifeq ($(CC),g++)
	DEFAULT_CFLAGS += -x c -Wall -Werror -Wextra -Wpedantic -Wconversion -Wsign-conversion -Wshadow -Wpointer-arith -Wvla -Wcast-align -Wstrict-overflow -Wstrict-aliasing -Wredundant-decls -Winit-self -Wmissing-noreturn
	CPEEPEE := 1
else ifeq ($(CC),clang++)
	DEFAULT_CFLAGS += -x c -Wall -Werror -Wextra -Wpedantic -Wconversion -Wsign-conversion -Wshadow -Wpointer-arith -Wvla -Wcast-align -Wstrict-overflow -Wstrict-aliasing -Wredundant-decls -Winit-self -Wmissing-noreturn
	CPEEPEE := 1
else ifeq ($(CC),em++)
	DEFAULT_CFLAGS += -x c
	CPEEPEE := 1
else ifneq ($(CC),emcc)
	DEFAULT_CFLAGS += -std=c99 -Werror -Wall -Wextra -Wstrict-prototypes -Wold-style-definition -Wpedantic -Wconversion -Wsign-conversion -Wshadow -Wpointer-arith -Wvla -Wcast-align -Wstrict-overflow -Wnested-externs -Wstrict-aliasing -Wredundant-decls -Winit-self -Wmissing-noreturn
	CPEEPEE := 0
endif


ifneq ($(CC),zig cc)
	DEFAULT_CFLAGS += -D _WIN32_WINNT=0x0501
endif

ifeq ($(DETECTED_OS),Linux)

	ifeq ($(RGFW_WAYLAND),1)

		LIBS := -ldl -lEGL -lGL -lwayland-egl -lwayland-cursor -lwayland-client -lxkbcommon relative-pointer-unstable-v1-client-protocol.c xdg-decoration-unstable-v1.c xdg-shell.c
		VULKAN_LIBS := -ldl -lEGL -lGL -lwayland-egl -lwayland-cursor -lwayland-client -lxkbcommon -lvulkan relative-pointer-unstable-v1-client-protocol.c xdg-decoration-unstable-v1.c xdg-shell.c
		DEFAULT_CFLAGS += -D RGFW_WAYLAND
		
		ifeq ($(WAYLAND_ONLY),1)
			DEFAULT_CFLAGS += -D RGFW_NO_X11
		endif

	else
		LIBS := -lX11 -lXrandr -ldl -lGL
		VULKAN_LIBS := -lX11 -lXrandr -ldl -lpthread -lvulkan
	endif

else ifeq ($(DETECTED_OS),Darwin)

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

endif

OUT ?= out

.PHONY: clean
clean:
	-rm -rf $(OUT)

$(OUT):
	mkdir -p $(OUT)

$(OUT)/%$(EXT): RGFW.h | $(OUT)
	@mkdir -p $(dir $@)
	$(CC) $(DEFAULT_CFLAGS) $(CFLAGS) $(LIBS) examples/$(basename $(notdir $@))/$(basename $(notdir $@)).c -o $@

$(OUT)/RGFW.o: DEFAULT_CFLAGS += -x c -D RGFW_NO_API -D RGFW_EXPORT -D RGFW_IMPLEMENTATION
$(OUT)/RGFW.o: RGFW.h | $(OUT)
	$(CC) -c -o $@ -fPIC $(DEFAULT_CFLAGS) $(CFLAGS) $^

$(OUT)/libRGFW.a: $(OUT)/RGFW.o | $(OUT)
	ar rcs $@ $^

$(OUT)/libRGFW.so: $(OUT)/RGFW.o | $(OUT)
	$(CC) -shared -fPIC $(DEFAULT_CFLAGS) $(CFLAGS) $(LIBS) $^ -o $@

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

$(OUT)/microui_demo$(EXT): examples/microui_demo/microui.c examples/microui_demo/microui_demo.c examples/microui_demo/renderer.c
	$(CC) -Iexamples/microui $(DEFAULT_CFLAGS) $(CFLAGS) $(LIBS) $(WASM_LINK_MICROUI)

$(OUT)/metal$(EXT): LIBS += -framework Metal -framework QuartzCore
$(OUT)/metal$(EXT): examples/metal/metal.m $(OUT)/RGFW.o
	$(CC) $(DEFAULT_CFLAGS) $(CFLAGS) $(LIBS) $^ -o $@

$(OUT)/vk10$(EXT): examples/vk10/vk10.c
	@mkdir -p $(OUT)/shaders
	glslangValidator -V examples/vk10/shaders/vert.vert -o $(OUT)/shaders/vert.h --vn vert_code
	glslangValidator -V examples/vk10/shaders/frag.frag -o $(OUT)/shaders/frag.h --vn frag_code
	$(CC) $(DEFAULT_CFLAGS) $(CFLAGS) $(VULKAN_LIBS) -I$(OUT) $^ -o $@

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
	gl33 \
	gles2 \

ifeq ($(DETECTED_OS),Linux)
	EVERYTHING += vk10
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

