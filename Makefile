CC = gcc
AR = ar

CUSTOM_CFLAGS = 

DX11_LIBS = -ldxgi -ld3d11 -luuid -ld3dcompiler
VULAKN_LIBS = -I $(VULKAN_SDK)\Include -L $(VULKAN_SDK)\Lib -lvulkan-1
LIBS :=-lgdi32 -lm -lopengl32 -lwinmm -ggdb 
EXT = .exe
LIB_EXT = .dll
STATIC =

WARNINGS = -Wall -Werror -Wstrict-prototypes -Wextra
OS_DIR = \\

ifneq (,$(filter $(CC),winegcc x86_64-w64-mingw32-gcc i686-w64-mingw32-gcc))
	STATIC = --static
    detected_OS := WindowsCross
	LIB_EXT = .dll
	OS_DIR = /
else
	ifeq '$(findstring ;,$(PATH))' ';'
		detected_OS := Windows
	else
		detected_OS := $(shell uname 2>/dev/null || echo Unknown)
		detected_OS := $(patsubst CYGWIN%,Cygwin,$(detected_OS))
		detected_OS := $(patsubst MSYS%,MSYS,$(detected_OS))
		detected_OS := $(patsubst MINGW%,MSYS,$(detected_OS))
	endif
endif

ifeq ($(detected_OS),Windows)
	LIBS := -ggdb -ldwmapi -lshell32 -lwinmm -lgdi32 -lopengl32 $(STATIC)
	VULAKN_LIBS = -I $(VULKAN_SDK)\Include -L $(VULKAN_SDK)\Lib -lvulkan-1
	EXT = .exe
	LIB_EXT = .dll
	OS_DIR = \\

endif
ifeq ($(detected_OS),Darwin)        # Mac OS X
	LIBS := -lm -framework Foundation -framework AppKit -framework OpenGL -framework CoreVideo$(STATIC)
	VULAKN_LIBS = -lvulkan
	EXT = 
	LIB_EXT = .dylib
	OS_DIR = /
endif
ifeq ($(detected_OS),Linux)
    LIBS := -lXrandr -lX11 -lm -lGL -ldl -lpthread $(STATIC)
	VULAKN_LIBS = -lvulkan
	EXT =
	LIB_EXT = .so
	OS_DIR = /
endif

ifneq (,$(filter $(CC),cl))
	OS_DIR = \\

endif

ifneq (,$(filter $(CC),/opt/msvc/bin/x64/cl.exe /opt/msvc/bin/x86/cl.exe))
	OS_DIR = /
endif

ifneq (,$(filter $(CC),cl /opt/msvc/bin/x64/cl.exe /opt/msvc/bin/x86/cl.exe))
	WARNINGS =
	STATIC = /static
	LIBS = $(STATIC)
	EXT = .exe
	LIB_EXT = .dll
endif

all: examples$(OS_DIR)basic$(OS_DIR)main.c examples$(OS_DIR)buffer$(OS_DIR)main.c examples$(OS_DIR)portableGL$(OS_DIR)main.c  examples$(OS_DIR)gl33$(OS_DIR)main.c examples$(OS_DIR)gles2$(OS_DIR)main.c examples$(OS_DIR)vk10$(OS_DIR)main.c .$(OS_DIR)RGFW.h
	$(CC) examples$(OS_DIR)basic$(OS_DIR)main.c $(LIBS) -I. $(WARNINGS) -o basic
	$(CC) examples$(OS_DIR)buffer$(OS_DIR)main.c $(LIBS) -I. $(WARNINGS) -o buffer
	$(CC) examples$(OS_DIR)events$(OS_DIR)main.c $(LIBS) -I. $(WARNINGS) -o events
	$(CC) examples$(OS_DIR)callbacks$(OS_DIR)main.c $(LIBS) -I. $(WARNINGS) -o callbacks
	$(CC) examples$(OS_DIR)first-person-camera$(OS_DIR)main.c $(LIBS) -I. $(WARNINGS) -o camera
	$(CC) examples$(OS_DIR)portableGL$(OS_DIR)main.c $(LIBS) -I. -w -o portableGL
	$(CC) examples$(OS_DIR)gl33$(OS_DIR)main.c $(LIBS) -I. $(WARNINGS) -o gl33
	$(CC) examples$(OS_DIR)gles2$(OS_DIR)main.c -lEGL $(LIBS) -I. $(WARNINGS) -o gles2
	make vulkan_shaders
	$(CC) examples$(OS_DIR)vk10$(OS_DIR)main.c $(LIBS) $(VULAKN_LIBS) -I. $(WARNINGS) -o vk10

DX11: examples$(OS_DIR)dx11$(OS_DIR)main.c
	$(CC) $^ $(LIBS) $(DX11_LIBS) -I. $(WARNINGS) -o examples$(OS_DIR)dx11$(OS_DIR)$@

clean:
	rm -f *.exe .$(OS_DIR)examples$(OS_DIR)basic$(OS_DIR)basic .$(OS_DIR)examples$(OS_DIR)basic$(OS_DIR)basic.exe .$(OS_DIR)examples$(OS_DIR)gles2$(OS_DIR)gles2 .$(OS_DIR)examples$(OS_DIR)gles2$(OS_DIR)gles2.exe .$(OS_DIR)examples$(OS_DIR)gl33$(OS_DIR)gl33 .$(OS_DIR)examples$(OS_DIR)gl33$(OS_DIR)gl33.exe .$(OS_DIR)examples$(OS_DIR)vk10$(OS_DIR)vk10 .$(OS_DIR)examples$(OS_DIR)vk10$(OS_DIR)vk10.exe examples$(OS_DIR)vk10$(OS_DIR)shaders$(OS_DIR)*.h examples$(OS_DIR)dx11$(OS_DIR)DX11

debug: examples$(OS_DIR)*$(OS_DIR)main.c .$(OS_DIR)RGFW.h
	make clean

	$(CC) examples$(OS_DIR)buffer$(OS_DIR)main.c $(LIBS) -I. $(WARNINGS) -D RGFW_DEBUG -o examples$(OS_DIR)buffer$(OS_DIR)buffer
	.$(OS_DIR)examples$(OS_DIR)buffer$(OS_DIR)buffer$(EXT)

	$(CC) examples$(OS_DIR)events$(OS_DIR)main.c $(LIBS) -I. $(WARNINGS) -D RGFW_DEBUG -o examples$(OS_DIR)events$(OS_DIR)events
	.$(OS_DIR)examples$(OS_DIR)events$(OS_DIR)events$(EXT)

	$(CC) examples$(OS_DIR)callbacks$(OS_DIR)main.c $(LIBS) -I. $(WARNINGS) -D RGFW_DEBUG -o examples$(OS_DIR)callbacks$(OS_DIR)callbacks
	.$(OS_DIR)examples$(OS_DIR)callbacks$(OS_DIR)callbacks$(EXT)

	$(CC) examples$(OS_DIR)portableGL$(OS_DIR)main.c $(LIBS) -I. -w -o examples$(OS_DIR)portableGL$(OS_DIR)portableGL
	.$(OS_DIR)examples$(OS_DIR)portableGL$(OS_DIR)portableGL

	$(CC) examples$(OS_DIR)first-person-camera$(OS_DIR)main.c $(LIBS) -I. $(WARNINGS) -D RGFW_DEBUG -o examples$(OS_DIR)first-person-camera$(OS_DIR)camera
	.$(OS_DIR)examples$(OS_DIR)first-person-camera$(OS_DIR)camera$(EXT)

	$(CC) examples$(OS_DIR)basic$(OS_DIR)main.c $(LIBS) -I. $(WARNINGS) -D RGFW_DEBUG -o examples$(OS_DIR)basic$(OS_DIR)basic
	.$(OS_DIR)examples$(OS_DIR)basic$(OS_DIR)basic$(EXT)

	$(CC) examples$(OS_DIR)gl33$(OS_DIR)main.c $(LIBS) -I. $(WARNINGS) -D RGFW_DEBUG -o examples$(OS_DIR)gl33$(OS_DIR)gl33
	.$(OS_DIR)examples$(OS_DIR)gl33$(OS_DIR)gl33$(EXT)

	$(CC) examples$(OS_DIR)gles2$(OS_DIR)main.c $(LIBS) -lEGL -I. $(WARNINGS) -D RGFW_DEBUG -o examples$(OS_DIR)gles2$(OS_DIR)gles2
	.$(OS_DIR)examples$(OS_DIR)gles2$(OS_DIR)gles2$(EXT)

	make vulkan_shaders
	$(CC) examples$(OS_DIR)vk10$(OS_DIR)main.c $(LIBS) $(VULAKN_LIBS) -I. $(WARNINGS) -D RGFW_DEBUG -o examples$(OS_DIR)vk10$(OS_DIR)vk10
	.$(OS_DIR)examples$(OS_DIR)vk10$(OS_DIR)vk10$(EXT)

performance-checker:
	$(CC) examples$(OS_DIR)performance-checker$(OS_DIR)main.c $(LIBS) -I. $(WARNINGS) -o examples$(OS_DIR)performance-checker$(OS_DIR)performance-checker
	.$(OS_DIR)examples$(OS_DIR)performance-checker$(OS_DIR)performance-checker$(EXT)

vulkan_shaders:
	glslangValidator -V examples$(OS_DIR)vk10$(OS_DIR)shaders$(OS_DIR)vert.vert -o examples$(OS_DIR)vk10$(OS_DIR)shaders$(OS_DIR)vert.h --vn vert_code
	glslangValidator -V examples$(OS_DIR)vk10$(OS_DIR)shaders$(OS_DIR)frag.frag -o examples$(OS_DIR)vk10$(OS_DIR)shaders$(OS_DIR)frag.h --vn frag_code

debugDX11: examples$(OS_DIR)dx11$(OS_DIR)main.c
	$(CC) $^ $(LIBS) $(DX11_LIBS) -I. $(WARNINGS) -D RGFW_DEBUG -o dx11
	.$(OS_DIR)dx11.exe

RGFW.o: RGFW.h
	$(CC) -x c $(CUSTOM_CFLAGS) -c RGFW.h -D RGFW_IMPLEMENTATION -D RGFW_NO_JOYSTICK_CODES -fPIC -D RGFW_EXPORT

libRGFW$(LIB_EXT): RGFW.h RGFW.o
	make RGFW.o
	$(CC) $(CUSTOM_CFLAGS) -shared RGFW.o $(LIBS) -o libRGFW$(LIB_EXT)

libRGFW.a: RGFW.h RGFW.o
	make RGFW.o
	$(AR) rcs libRGFW.a *.o
