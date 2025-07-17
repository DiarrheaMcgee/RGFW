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

$(OUT)/basic$(EXT): LIBS += $(WASM_LINK_GL1)
$(OUT)/basic$(EXT): examples/basic/basic.c

$(OUT)/buffer$(EXT): LIBS += $(WASM_LINK_GL1)
$(OUT)/buffer$(EXT): examples/buffer/buffer.c

$(OUT)/events$(EXT): LIBS += $(WASM_LINK_GL1)
$(OUT)/events$(EXT): examples/events/events.c

$(OUT)/callbacks$(EXT): LIBS += $(WASM_LINK_GL1)
$(OUT)/callbacks$(EXT): examples/callbacks/callbacks.c

$(OUT)/flags$(EXT): LIBS += $(WASM_LINK_GL1)
$(OUT)/flags$(EXT): examples/flags/flags.c

$(OUT)/monitor$(EXT): LIBS += $(WASM_LINK_GL1)
$(OUT)/monitor$(EXT): examples/monitor/monitor.c

$(OUT)/gl33_ctx$(EXT): LIBS += $(WASM_LINK_GL1)
$(OUT)/gl33_ctx$(EXT): examples/gl33_ctx/gl33_ctx.c

$(OUT)/smooth-resize$(EXT): LIBS += $(WASM_LINK_GL1)
$(OUT)/smooth-resize$(EXT): examples/smooth-resize/smooth-resize.c

$(OUT)/multi-window$(EXT): LIBS += $(WASM_LINK_GL1)
$(OUT)/multi-window$(EXT): examples/multi-window/multi-window.c

$(OUT)/icons$(EXT): LIBS += -lm $(WASM_LINK_GL1)
$(OUT)/icons$(EXT): examples/icons/icons.c

$(OUT)/gamepad$(EXT): LIBS += -lm $(WASM_LINK_GL1)
$(OUT)/gamepad$(EXT): examples/gamepad/gamepad.c

$(OUT)/silk$(EXT): LIBS += -lm $(WASM_LINK_GL1)
$(OUT)/silk$(EXT): examples/silk/silk.c

$(OUT)/camera$(EXT): LIBS += -lm $(WASM_LINK_GL1)
$(OUT)/camera$(EXT): examples/first-person-camera/camera.c

$(OUT)/microui_demo$(EXT): LIBS += $(WASM_LINK_GL1)
$(OUT)/microui_demo$(EXT): examples/microui_demo/microui_demo.c

$(OUT)/gl33$(EXT): LIBS += $(WASM_LINK_GL3)
$(OUT)/gl33$(EXT): examples/gl33/gl33.c

$(OUT)/pgl$(EXT): LIBS += -lm
$(OUT)/pgl$(EXT): examples/portableGL/pgl.c

$(OUT)/gles2$(EXT): LIBS += $(WASM_LINK_GL2)
$(OUT)/gles2$(EXT): examples/gles2/gles2.c

$(OUT)/egl$(EXT): LIBS += -lEGL
$(OUT)/egl$(EXT): examples/egl/egl.c

$(OUT)/osmesa_demo$(EXT): examples/osmesa_demo/osmesa_demo.c

$(OUT)/vk10$(EXT): examples/vk10/vk10.c
	@mkdir -p $(OUT)/shaders
	glslangValidator -V examples/vk10/shaders/vert.vert -o $(OUT)/shaders/vert.h --vn vert_code
	glslangValidator -V examples/vk10/shaders/frag.frag -o $(OUT)/shaders/frag.h --vn frag_code
	$(CC) -o $@ $(DEFAULT_CFLAGS) $(CFLAGS) $(VULKAN_LIBS) -I$(OUT) $^

$(OUT)/dx11$(EXT): examples/dx11/dx11.c

$(OUT)/metal$(EXT): LIBS += -framework Metal -framework QuartzCore
$(OUT)/metal$(EXT): examples/metal/metal.m $(OUT)/RGFW.o

$(OUT)/webgpu$(EXT): LIBS := -s USE_WEBGPU=1
$(OUT)/webgpu$(EXT): examples/webgpu/webgpu.c

$(OUT)/minimal_links$(EXT): examples/minimal_links/minimal_links.c

$(OUT)/gears$(EXT): LIBS += -lm $(WASM_LINK_GL1)
$(OUT)/gears$(EXT): examples/gears/gears.c

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

ifneq ($(NO_GLES),1)
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

