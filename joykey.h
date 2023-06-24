#ifndef _JK_JOYKEY_H
#define _JK_JOYKEY_H

#include <SDL2/SDL.h>

struct Key {
    SDL_Rect rect;
    SDL_Texture tex;
    char *c;
};
typedef struct Key Key;

struct Keyboard {
    Key* keys;
};

#endif
