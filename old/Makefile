# Makefile

# The full build command:
# gcc -o joykey main.c -Wall -Wextra -lm -lGL $(sdl2-config --cflags --libs) -lSDL2_image -lSDL2_ttf

CC := cc
CWARNS := -Wall -Wextra
CLIBS  := -lm -lGL \
	$(shell sdl2-config --cflags --libs) \
	-lSDL2_image -lSDL2_ttf
CFLAGS := $(CWARNS) $(CLIBS)
CFLAGS_REL := $(CWARNS) $(CLIBS) -O2

OBJS_DIR =.objs
OBJS =$(OBJS_DIR)/joykey.o

all: joykey

joykey: $(OBJS_DIR)/joykey.o
	$(CC) $^ -o $@ $(CLIBS)

$(OBJS_DIR)/%.o: %.c $(OBJS_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(OBJS_DIR):
	$(shell mkdir -p $(OBJS_DIR))

clean:
	rm -rf $(OBJS_DIR)

.PHONY: all clean
