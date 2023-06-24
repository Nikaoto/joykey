#include <stdio.h>
#include <math.h>
#include <string.h>
#include <SDL2/SDL.h>
#include <SDL2/SDL_image.h>
#include <SDL2/SDL_opengl.h>
#include <SDL2/SDL_ttf.h>
#include <SDL2/SDL_audio.h>
#include "joykey.h"

#define WINDOW_WIDTH                  1024
#define WINDOW_HEIGHT                 600
#define KEY_FONT_SIZE                 45
#define KEY_WIDTH                     60
#define KEY_HEIGHT                    80
#define KEY_SHADOW_THICKNESS          6
#define ANALOG_THICKNESS              6
#define ANALOG_INNER_SHADOW_THICKNESS 4
#define ANALOG_OUTER_SHADOW_THICKNESS 2
#define ANALOG_RADIUS                 14
#define ANALOG_SPEED                  10
#define BG_COLOR                      77, 169, 220, 255

#define LEFT_ANALOG_INITIAL_X  250
#define LEFT_ANALOG_INITIAL_Y  350
#define RIGHT_ANALOG_INITIAL_X 550
#define RIGHT_ANALOG_INITIAL_Y 350

int
deadzone(int x)
{
    int val = 1000;
    if (x > val || x < -val) return x;
    return 0;
}

void
draw_rect(SDL_Renderer *rend, int x, int y, int w, int h)
{
    SDL_RenderDrawLine(rend, x,   y,   x+w, y);
    SDL_RenderDrawLine(rend, x+w, y,   x+w, y+h);
    SDL_RenderDrawLine(rend, x+w, y+h, x,   y+h);
    SDL_RenderDrawLine(rend, x,   y+h, x,   y);
}

void
draw_circle(SDL_Renderer *rend, int x, int y, int r, int thickness)
{
    // Draw the circle using a series of thick lines
    for (int t = 0; t < thickness; t++) {
        for (int i = 0; i <= 360; i += 1) {
            // Calculate the coordinates of the endpoints of the current line segment
            float angle = i * (3.141592 / 180.0f);
            int start_x = x + (r - t) * cos(angle);
            int start_y = y + (r - t) * sin(angle);
            int end_x = x + (r - t + 1) * cos(angle);
            int end_y = y + (r - t + 1) * sin(angle);
            
            // Draw the current line segment
            SDL_RenderDrawLine(rend, start_x, start_y, end_x, end_y);
        }
    }
}

struct Sprite {
    SDL_Texture *tex;
    SDL_Rect *rect;
};
typedef struct Sprite Sprite;

Sprite*
new_key(char *str, SDL_Renderer *rend, TTF_Font *font, SDL_Rect *rect)
{
    Sprite *k = malloc(sizeof(Sprite));
    k->rect = malloc(sizeof(*rect));
    memcpy(k->rect, rect, sizeof(*rect));

    // Create key texture
    k->tex = SDL_CreateTexture(
        rend,
        SDL_PIXELFORMAT_RGBA8888,
        SDL_TEXTUREACCESS_TARGET,
        k->rect->w,
        k->rect->h
    );
    SDL_SetRenderTarget(rend, k->tex);
    SDL_SetTextureBlendMode(k->tex, SDL_BLENDMODE_BLEND);

    // Draw the gray rectangle on the key texture
    SDL_SetRenderDrawColor(rend, 128, 128, 128, 255);
    SDL_RenderClear(rend);

    // Draw black shadow on the outside
    SDL_SetRenderDrawColor(rend, 0, 0, 0, 30);
    for (int i = 0; i < KEY_SHADOW_THICKNESS; i++) {
        draw_rect(rend, i, i, k->rect->w-2*i, k->rect->h-2*i);
    }

    // Create letter texture
    SDL_Color text_color = { 255, 255, 255, 255 };
    SDL_Surface *text_sur = TTF_RenderUTF8_Solid(font, str, text_color);
    SDL_Texture *text_tex = SDL_CreateTextureFromSurface(rend, text_sur);

    // Render the letter to the key texture
    SDL_Rect text_rect = {
        .x = (k->rect->w - text_sur->w)/2,
        .y = (k->rect->h - text_sur->h)/2,
        .w = text_sur->w,
        .h = text_sur->h
    };
    SDL_RenderCopy(rend, text_tex, NULL, &text_rect);

    // Free memory
    SDL_DestroyTexture(text_tex);
    SDL_FreeSurface(text_sur);

    return k;
}

Sprite**
generate_keys(int *count, SDL_Renderer *rend, TTF_Font *font, int start_x, int start_y, int mh, int mv)
{
    char *keyboard_letters = 
        "1234567890\n"
        "qwertyuiop\n"
        "asdfghjkl\"\n"
        "zxcvbnm-_/\n";

    // Determinme number of keys
    int key_count = 0;
    for (char *c = keyboard_letters; *c != '\0'; c++) {
        if (*c == '\n') continue;
        key_count++;
    }

    // Set key count outside
    *count = key_count;

    // Generate them
    Sprite **keys = malloc(sizeof(Sprite*) * key_count);
    char current_letter[2] = {'0', '\0'};
    int curr_x = start_x;
    int curr_y = start_y;
    int key_ind = 0;
    for (char *c = keyboard_letters; *c != '\0'; c++) {
        if (*c == '\n') {
            curr_x = start_x;
            curr_y += mv + KEY_HEIGHT;
            continue;
        }
        current_letter[0] = *c;
        keys[key_ind++] = new_key(current_letter, rend, font, &(SDL_Rect){
            .x = curr_x,
            .y = curr_y,
            .w = KEY_WIDTH,
            .h = KEY_HEIGHT
        });
        curr_x += mh + KEY_WIDTH;
    }

    return keys;
}

Sprite*
new_analog(SDL_Renderer *rend, SDL_Rect *rect)
{
    Sprite *sprite = malloc(sizeof(Sprite));
    sprite->rect = malloc(sizeof(SDL_Rect));
    memcpy(sprite->rect, rect, sizeof(SDL_Rect));
    sprite->tex = SDL_CreateTexture(
        rend,
        SDL_PIXELFORMAT_RGBA8888,
        SDL_TEXTUREACCESS_TARGET,
        sprite->rect->w,
        sprite->rect->h
    );
    SDL_SetRenderTarget(rend, sprite->tex);
    SDL_SetTextureBlendMode(sprite->tex, SDL_BLENDMODE_BLEND);

    // Clear the texture
    SDL_SetRenderDrawColor(rend, 0, 0, 0, 0);
    SDL_RenderClear(rend);

    // Draw circle shadows/outlines
    SDL_SetRenderDrawColor(rend, 0, 0, 0, 20);
    draw_circle(
        rend,
        sprite->rect->w/2,
        sprite->rect->h/2,
        ANALOG_RADIUS - ANALOG_THICKNESS,
        ANALOG_INNER_SHADOW_THICKNESS
    );
    draw_circle(
        rend,
        sprite->rect->w/2,
        sprite->rect->h/2,
        ANALOG_RADIUS,
        ANALOG_OUTER_SHADOW_THICKNESS
    );

    // Draw circle
    SDL_SetRenderDrawColor(rend, 246, 233, 213, 100);
    draw_circle(
        rend,
        sprite->rect->w/2,
        sprite->rect->h/2,
        ANALOG_RADIUS - ANALOG_OUTER_SHADOW_THICKNESS,
        ANALOG_THICKNESS
    );

    return sprite;
}

double
get_delta_time()
{
    static Uint64 last_tick_time = 0;
    static Uint64 delta = 0;

    Uint64 now = SDL_GetTicks64();
    delta = now - last_tick_time;
    last_tick_time = now;

    return delta / 1000.0;
}

int
main(void)
{
    // Init SDL
    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_EVENTS | SDL_INIT_JOYSTICK) < 0) {
        printf("SDL_Init failed: %s\n", SDL_GetError());
        return 1;
    }

    // Create window
    SDL_Window *window = SDL_CreateWindow(
        "SDLtest",
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
        WINDOW_WIDTH, WINDOW_HEIGHT,
        SDL_WINDOW_SHOWN);
    if (!window) {
        printf("SDL_CreateWindow failed: %s\n", SDL_GetError());
        SDL_Quit();
        return 1;
    }

    // Init OpenGL
    SDL_GLContext context = SDL_GL_CreateContext(window);
    int major, minor;
    SDL_GL_GetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, &major);
    SDL_GL_GetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, &minor);
    printf("Using OpenGL version %i.%i\n", major, minor);

    // Init renderer
    SDL_Renderer *rend = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);
    if (!rend) {
        printf("SDL_CreateRenderer failed: %s\n", SDL_GetError());
        SDL_Quit();
        return 1;
    }
    SDL_SetRenderDrawBlendMode(rend, SDL_BLENDMODE_BLEND);

    // Generate analog sprites
    Sprite *left_analog = new_analog(rend, &(SDL_Rect){
        .x = LEFT_ANALOG_INITIAL_X,
        .y = LEFT_ANALOG_INITIAL_Y,
        .w = ANALOG_RADIUS*2 + ANALOG_THICKNESS*2,
        .h = ANALOG_RADIUS*2 + ANALOG_THICKNESS*2
    });
    Sprite *right_analog = new_analog(rend, &(SDL_Rect){
        .x = RIGHT_ANALOG_INITIAL_X,
        .y = RIGHT_ANALOG_INITIAL_Y,
        .w = ANALOG_RADIUS*2 + ANALOG_THICKNESS*2,
        .h = ANALOG_RADIUS*2 + ANALOG_THICKNESS*2
    });

    SDL_SetRenderTarget(rend, NULL);

    // Load font
    if (TTF_Init() == -1) {
        printf("TTF_Init failed: %s\n", TTF_GetError());
        SDL_Quit();
        return 1;
    }
    TTF_Font *font = TTF_OpenFont("courier.ttf", KEY_FONT_SIZE);
    if (!font) {
        printf("TTF_OpenFont failed: %s\n", TTF_GetError());
        SDL_Quit();
        return 1;
    }

    // Generate key textures
    int key_count = 0;
    Sprite **keys = generate_keys(&key_count, rend, font, 70, 170, 10, 10);

    // Render to the window
    SDL_SetRenderTarget(rend, NULL);

    SDL_Joystick* joystick = NULL;
    if (SDL_NumJoysticks() > 0) {
        joystick = SDL_JoystickOpen(0);
        if (joystick == NULL) {
            return 0;
        }
    }

    Uint64 frame_count = 0;
    Uint64 frame_start_ms = 0;
    float fps = 0.0f;

    Uint64 now_ms = 0;
    int quit = 0;
    while (!quit) {
        double dt = get_delta_time();

        SDL_Event event;
        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_QUIT) {
                quit = 1;
            } else if (event.type == SDL_KEYDOWN) {
                switch (event.key.keysym.sym) {
                case SDLK_q:
                    quit =1;
                    break;
                case SDLK_w:
                    left_analog->rect->y -= ANALOG_SPEED * dt;
                    break;
                case SDLK_s:
                    left_analog->rect->y += ANALOG_SPEED * dt;
                    break;
                case SDLK_d:
                    left_analog->rect->x += ANALOG_SPEED * dt;
                    break;
                case SDLK_a:
                    left_analog->rect->x -= ANALOG_SPEED * dt;
                    break;
                case SDLK_UP:
                    right_analog->rect->y -= ANALOG_SPEED * dt;
                    break;
                case SDLK_DOWN:
                    right_analog->rect->y += ANALOG_SPEED * dt;
                    break;
                case SDLK_RIGHT:
                    right_analog->rect->x += ANALOG_SPEED * dt;
                    break;
                case SDLK_LEFT:
                    right_analog->rect->x -= ANALOG_SPEED * dt;
                    break;
                }
            }
        }

        if (joystick) {
            double k = 0.0055;
            Sint16 laxisx = deadzone(SDL_JoystickGetAxis(joystick, 0));
            Sint16 laxisy = deadzone(SDL_JoystickGetAxis(joystick, 1));
            left_analog->rect->x = LEFT_ANALOG_INITIAL_X + laxisx * k;
            left_analog->rect->y = LEFT_ANALOG_INITIAL_Y + laxisy * k;

            Sint16 raxisx = deadzone(SDL_JoystickGetAxis(joystick, 3));
            Sint16 raxisy = deadzone(SDL_JoystickGetAxis(joystick, 4));
            right_analog->rect->x = RIGHT_ANALOG_INITIAL_X + raxisx * k;
            right_analog->rect->y = RIGHT_ANALOG_INITIAL_Y + raxisy * k;
        }

        // Clear the screen
        SDL_SetRenderDrawColor(rend, BG_COLOR);
        SDL_RenderClear(rend);

        // Render keyboard
        for (int i = 0; i < key_count; i++) {
            SDL_RenderCopy(rend, keys[i]->tex, NULL, keys[i]->rect);
        }

        // Render analogs
        SDL_RenderCopy(rend, left_analog->tex, NULL, left_analog->rect);
        SDL_RenderCopy(rend, right_analog->tex, NULL, right_analog->rect);

        // Present
        SDL_RenderPresent(rend);

        // Update FPS
        frame_count++;
        now_ms = SDL_GetTicks64();
        if (now_ms >= frame_start_ms + 1000) {
            fps = frame_count / ((now_ms - frame_start_ms)/1000);
            frame_count = 0;
            frame_start_ms = now_ms;
            printf("fps: %d\n", (int)fps);
        }
    }

    SDL_GL_DeleteContext(context);
    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}
