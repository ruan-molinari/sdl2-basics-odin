package main

// importing necessary packages
import "core:fmt"
import SDL "vendor:sdl2"

// constants
WINDOW_FLAGS :: SDL.WINDOW_SHOWN
RENDER_FLAGS :: SDL.RENDERER_ACCELERATED
TARGET_DT :: 1000 / 60

Game :: struct {
  perf_frequency: f64,
  render: ^SDL.Renderer,
}

game := Game{}

main :: proc() {
  assert(SDL.Init(SDL.INIT_VIDEO) == 0, SDL.GetErrorString())
  defer SDL.Quit()

  window := SDL.CreateWindow(
    "Odin GPU introduction",
    SDL.WINDOWPOS_CENTERED,
    SDL.WINDOWPOS_CENTERED,
    640,
    480,
    WINDOW_FLAGS,
  )
  assert(window != nil, SDL.GetErrorString())
  defer SDL.DestroyWindow(window)

  // Must not do VSync because we run the tick loop on the same thread as rendering
  game.render = SDL.CreateRenderer(window, -1, RENDER_FLAGS)
  assert(game.render != nil, SDL.GetErrorString())
  defer SDL.DestroyRenderer(game.render)

  game.perf_frequency = f64(SDL.GetPerformanceFrequency())
  start : f64
  end : f64
  
  event : SDL.Event
  state : [^]u8

  game_loop : for {
    
    start = get_time()

    // Begin loop code
    // 1. Get keyboard state, which keys are pressed
    state = SDL.GetKeyboardState(nil)

    // Handle any imput events :: quit, pause, shoot...?
    if SDL.PollEvent(&event) {
      if event.type == SDL.EventType.QUIT {
        break game_loop
      }

      if event.type == SDL.EventType.KEYDOWN {
        // a #partial switch allows us to ignore other scancode types;
        // otherwise, the compiler will refuse to compile the program, alerting us of unhandled cases
        #partial switch event.key.keysym.scancode {
        case .ESCAPE:
          break game_loop
        }
      }
    }

    // spin lock to hit framerate
    end = get_time()
    for end - start < TARGET_DT {
      end = get_time()
    }

    fmt.println("FPS: ", 1000 / (end - start))

    // actual flipping / presentation of the copy
    // read comments here: https://wiki.libsdl.org/SDL_RenderCopy
    SDL.RenderPresent(game.render)

    // make sure our backgroung is black
    // RenderClear colors the entire screen whatever color is set here
    SDL.SetRenderDrawColor(game.render, 0, 0, 0, 100)

    // clear the old scene from the renderer
    // clear after presentation so we remain free to call RenderCopy() throughout our update code / whatever it makes the most sense
    SDL.RenderClear(game.render)
  }
}

get_time :: proc() -> f64 {
  return f64(SDL.GetPerformanceCounter()) * 1000 / game.perf_frequency
}
