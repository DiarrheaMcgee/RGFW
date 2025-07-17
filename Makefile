DEFAULT_CFLAGS := -pipe -march=native -std=c99 -pedantic -Wall -I./
CFLAGS         ?= -Og -ggdb3
CC             ?= cc
AR             ?= ar
.DEFAULT_GOAL   = all

NO_GLES ?= 1
NO_OSMESA ?= 1
NO_EGL ?= 1

DETECTED_OS = $(shell uname 2>/dev/null || echo Unknown)

ifneq (,$(filter $(CC),emcc em++))
	DETECTED_OS = web
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
		LIBS := -ldl -lGL -lXrandr -lX11
		VULKAN_LIBS := -lX11 -lXrandr -ldl -lpthread -lvulkan
	endif

else ifeq ($(DETECTED_OS),Darwin)

	LIBS := -framework CoreVideo -framework Cocoa -framework OpenGL -framework IOKit

else ifeq ($(DETECTED_OS),web)

	EXT := .js
	WASM_LINK_GL1 = -s LEGACY_GL_EMULATION -D LEGACY_GL_EMULATION -sGL_UNSAFE_OPTS=0
	WASM_LINK_GL2 = -s FULL_ES2 -s USE_WEBGL2
	WASM_LINK_GL3 = -s FULL_ES3 -s USE_WEBGL2
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
	$(CC) -o $@ $(DEFAULT_CFLAGS) $(CFLAGS) $(LIBS) $^

$(OUT)/%.o: | $(OUT)
	@mkdir -p $(dir $@)
	$(CC) -c -o $@ -fPIC $(DEFAULT_CFLAGS) $(CFLAGS) $^

$(OUT)/%.a: | $(OUT)
	@mkdir -p $(dir $@)
	ar rcs $@ $^

$(OUT)/%.so: | $(OUT)
	@mkdir -p $(dir $@)
	$(CC) -shared -o $@ -fPIC $(DEFAULT_CFLAGS) $(CFLAGS) $(LIBS) $^

$(OUT)/RGFW.o: DEFAULT_CFLAGS += -x c -D RGFW_NO_API -D RGFW_EXPORT -D RGFW_IMPLEMENTATION
$(OUT)/RGFW.o: RGFW.h

$(OUT)/libRGFW.a: $(OUT)/RGFW.o

$(OUT)/libRGFW.so: $(OUT)/RGFW.o

$(OUT)/basic: LIBS += $(WASM_LINK_GL1)
$(OUT)/basic: examples/basic/basic.c

$(OUT)/buffer: LIBS += $(WASM_LINK_GL1)
$(OUT)/buffer: examples/buffer/buffer.c

$(OUT)/events: LIBS += $(WASM_LINK_GL1)
$(OUT)/events: examples/events/events.c

$(OUT)/callbacks: LIBS += $(WASM_LINK_GL1)
$(OUT)/callbacks: examples/callbacks/callbacks.c

$(OUT)/flags: LIBS += $(WASM_LINK_GL1)
$(OUT)/flags: examples/flags/flags.c

$(OUT)/monitor: LIBS += $(WASM_LINK_GL1)
$(OUT)/monitor: examples/monitor/monitor.c

$(OUT)/gl33_ctx: LIBS += $(WASM_LINK_GL1)
$(OUT)/gl33_ctx: examples/gl33_ctx/gl33_ctx.c

$(OUT)/smooth-resize: LIBS += $(WASM_LINK_GL1)
$(OUT)/smooth-resize: examples/smooth-resize/smooth-resize.c

$(OUT)/multi-window: LIBS += $(WASM_LINK_GL1)
$(OUT)/multi-window: examples/multi-window/multi-window.c

$(OUT)/icons: LIBS += -lm $(WASM_LINK_GL1)
$(OUT)/icons: examples/icons/icons.c

$(OUT)/gamepad: LIBS += -lm $(WASM_LINK_GL1)
$(OUT)/gamepad: examples/gamepad/gamepad.c

$(OUT)/silk: LIBS += -lm $(WASM_LINK_GL1)
$(OUT)/silk: examples/silk/silk.c

$(OUT)/camera: LIBS += -lm $(WASM_LINK_GL1)
$(OUT)/camera: examples/first-person-camera/camera.c

$(OUT)/microui_demo: LIBS += $(WASM_LINK_GL1)
$(OUT)/microui_demo: examples/microui_demo/microui_demo.c

$(OUT)/gl33: LIBS += $(WASM_LINK_GL3)
$(OUT)/gl33: examples/gl33/gl33.c

$(OUT)/pgl: LIBS += -lm
$(OUT)/pgl: examples/portableGL/pgl.c

$(OUT)/gles2: LIBS += $(WASM_LINK_GL2)
$(OUT)/gles2: examples/gles2/gles2.c

$(OUT)/egl: LIBS += -lEGL
$(OUT)/egl: examples/egl/egl.c

$(OUT)/osmesa_demo: examples/osmesa_demo/osmesa_demo.c

$(OUT)/vk10: examples/vk10/vk10.c
	@mkdir -p $(OUT)/shaders
	glslangValidator -V examples/vk10/shaders/vert.vert -o $(OUT)/shaders/vert.h --vn vert_code
	glslangValidator -V examples/vk10/shaders/frag.frag -o $(OUT)/shaders/frag.h --vn frag_code
	$(CC) -o $@ $(DEFAULT_CFLAGS) $(CFLAGS) $(VULKAN_LIBS) -I$(OUT) $^

$(OUT)/dx11: examples/dx11/dx11.c

$(OUT)/metal: LIBS += -framework Metal -framework QuartzCore
$(OUT)/metal: examples/metal/metal.m $(OUT)/RGFW.o

$(OUT)/webgpu: LIBS := -s USE_WEBGPU=1
$(OUT)/webgpu: examples/webgpu/webgpu.c

$(OUT)/minimal_links: examples/minimal_links/minimal_links.c

$(OUT)/gears: LIBS += -lm $(WASM_LINK_GL1)
$(OUT)/gears: examples/gears/gears.c

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
	gamepad \
	silk \
	camera \
	gl33 \
	gles2 \

ifeq ($(DETECTED_OS),Linux)
	EVERYTHING += vk10
endif

ifneq ($(NO_GLES), 1)
	EVERYTHING += gles2
endif

ifneq ($(NO_OSMESA),1)
	EVERYTHING += osmesa_demo
endif

ifneq ($(NO_EGL),1)
	EVERYTHING += egl
endif

ifeq ($(DETECTED_OS),Darwin)
	EVERYTHING += metal
endif

ifeq ($(DETECTED_OS),web)
	EVERYTHING += webgpu
else
	EVERYTHING += \
		      pgl \
		      gears
endif

$(EVERYTHING): %: $(OUT)/%$(EXT)

all: $(EVERYTHING)

