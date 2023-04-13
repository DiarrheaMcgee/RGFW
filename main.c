#define RGFW_IMPLEMENTATION
#define RGFW_PRINT_ERRORS

#include "RGFW.h"

void drawLoop(RGFW_window* w); /* I seperate the draw loop only because it's run twice */
void* loop2(void *);


unsigned char icon[4 * 3 * 3] = {0xFF, 0x00, 0x00, 0xFF, 0xFF, 0x00, 0x00, 0xFF, 0xFF, 0x00, 0x00, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0x00, 0x00, 0xFF, 0xFF, 0x00, 0x00, 0xFF, 0xFF, 0x00, 0x00, 0xFF};

unsigned char running = 1;

int main() {
    RGFW_window* win = RGFW_createWindowPointer("name", 500, 500, 500, 500, RGFW_ALLOW_DND);

    win->fpsCap = 60;

    RGFW_createThread(loop2, NULL); /* the function must be run after the window of this thread is made for some reason (using X11) */

    unsigned short js = RGFW_registerJoystick(win, 0);

    RGFW_setIcon(win, icon, 3, 3, 4);

    unsigned char i, frames = 60;

    unsigned char mouseHidden = 0;

    while (running) {
        RGFW_checkEvents(win);
        frames++;

        if (win->event.type == RGFW_quit)
            running = 0;

        if (RGFW_isPressedS(win, "Up"))
            printf("Pasted : %s\n", RGFW_readClipboard(win));
        else if (RGFW_isPressedS(win, "Down"))
            RGFW_writeClipboard(win, "DOWN");
        else if (RGFW_isPressedS(win, "Space"))
            printf("fps : %i\n", win->fps);
        else if (RGFW_isPressedS(win, "w") && win->event.type == RGFW_keyPressed && frames >= 60) {
            if (!mouseHidden) {
                RGFW_hideMouse(win);
                mouseHidden = 1;
            }
            else {
                RGFW_setMouseDefault(win);
                mouseHidden = 0;
            }
            
            frames = 0;
        }
        else if (RGFW_isPressedS(win, "t")) 
            RGFW_setMouse(win, icon, 3, 3, 4);

        for (i = 0; i < win->event.droppedFilesCount; i++)
            printf("dropped : %s\n", win->event.droppedFiles[i]);

        if (win->event.type == RGFW_jsButtonPressed)
            printf("pressed %i\n", win->event.button);

        if (win->event.type == RGFW_jsAxisMove && !win->event.button)
            printf("{%i, %i}\n", win->event.axis[0][0], win->event.axis[0][1]);
    
        drawLoop(win);
    }

    time_t t;
    for (t = time(0); (float)(time(0) - t) <= 0.05;); /*wait for the sub window to close*/

    RGFW_closeWindow(win);
}

void drawLoop(RGFW_window *w) {
    #ifndef RGFW_VULKAN
    RGFW_clear(w, 255, 255, 255, 0);
    glBegin(GL_TRIANGLES);
    glColor3f(1, 0, 0);
    glVertex2f(-0.6, -0.75);
    glColor3f(0, 1, 0);
    glVertex2f(0.6, -0.75);
    glColor3f(0, 0, 1);
    glVertex2f(0, 0.75);
    glEnd();
    #else

    #endif
}

void *loop2(void * args) {
    #ifndef __APPLE__
    RGFW_window *win = RGFW_createWindowPointer("subwindow", 200, 200, 200, 200, NULL);
    win->fpsCap = 60;

    while (running)
    {
        RGFW_checkEvents(win);

        if (win->event.type == RGFW_quit)
            break;

        drawLoop(win);
    }

    RGFW_closeWindow(win);
    #else
    printf("Managing windows on a seperate thread is not supported on MacOS :(\n");
    #endif

    return NULL;
    
}