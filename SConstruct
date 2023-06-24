import subprocess

# Run sdl2-config and capture its output
sdl2_cflags = subprocess.check_output(['sdl2-config', '--cflags', '--libs']).decode().strip().split()

shared_cflags = ['-Wall', '-Wextra'] + sdl2_cflags
dev_env = Environment(CFLAGS=shared_cflags + ['-O0', '-g'])
rel_env = Environment(CFLAGS=shared_cflags + ['-O2', '-Werror'])
libs = ['m', 'GL', 'SDL2', 'SDL2_image', 'SDL2_ttf']

Default(dev_env.Program(dev_env.Object('joykey', ['main.c'], LIBS=libs), LIBS=libs))
rel_program = rel_env.Program(rel_env.Object('joykey-rel', ['main.c']), LIBS=libs)

Alias('release', rel_program)
