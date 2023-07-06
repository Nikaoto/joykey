require("map_funcs")
require("love_extensions")
require("geometria")

deep = require("lib/deep")
tween = require("lib/tween")
inspect = require("lib/inspect")
function dumptable(t) print(inspect(t)) end
fmt = string.format
function printf(...) print(string.format(...)) end
function get_time() return love.timer.getTime() end
function lerp(a, b, x) return a + (b - a) * x end

local Input = require("input")
local Textbox = require("textbox")
local Analog = require("analog")
local Vkeyboard = require("vkeyboard")
local Vkeybutton = require("vkeybutton")
local lg = love.graphics

local text_font = nil
local text_font_size = 56
local key_font = nil
local key_font_size = 56

global_conf = {
   debug_mode = false,
   axis_deadzone = 0.08,
   axis_dampen_amount = 0.8,
   fullscreen = false,
   --background_color = {77/255, 169/255, 220/255, 1},
   background_color = {89/255, 157/255, 220/255, 1},
   analog_lerp = 0.2,
}
global_state = {
}

sounds = {
   ["accept"] = nil,
   ["select"] = nil,
}

window_width = 0
window_height = 0

textbox = nil
vkeyboard = nil
left_analog = nil
right_analog = nil

joystick = nil -- Currently active joystick
jinput = nil -- Joystick input module
local jinput_conf = {
   capture_fns = {
      is_button_down = function(inp, btn, cnf, src)
         return src:isGamepadDown(btn)
      end,
      get_axis = function(inp, axis, cnf, src)
         return src:getGamepadAxis(axis)
      end,
   },
   buttons = {
      ["a"] =             { on_release = "done_accept",   on_press = "done_select"   },
      ["b"] =             { on_release = "exit_accept",   on_press = "exit_select"   },
      ["x"] =             { on_release = "delete_accept", on_press = "delete_select" },
      ["y"] =             { on_release = "space_accept",  on_press = "space_select"  },
      ["leftshoulder"] =  { on_release = "accept_left",   on_press = "select_left"   },
      ["rightshoulder"] = { on_release = "accept_right",  on_press = "select_right"  },
      ["leftstick"] =     { on_release = "accept_left",   on_press = "select_left"   },
      ["rightstick"] =    { on_release = "accept_right",  on_press = "select_right"  },
      ["dpup"] =          { on_release = nil,             on_press = "caret_up"      },
      ["dpdown"] =        { on_release = nil,             on_press = "caret_down"    },
      ["dpleft"] =        { on_release = nil,             on_press = "caret_left"    },
      ["dpright"] =       { on_release = nil,             on_press = "caret_right"   },
   },
   axii = {
      ["leftx"] = {},
      ["lefty"] = {},
      ["rightx"] = {},
      ["righty"] = {},
      ["triggerleft"] = {},
      ["triggerright"] = {},
   },
}

jinput_conf.buttons["dpup"].capture_is_down = function(inp, btn, cnf, src)
   return src:getHat(1):find('u') ~= nil
end
jinput_conf.buttons["dpdown"].capture_is_down = function(inp, btn, cnf, src)
   return src:getHat(1):find('d') ~= nil
end
jinput_conf.buttons["dpleft"].capture_is_down = function(inp, btn, cnf, src)
   return src:getHat(1):find('l') ~= nil
end
jinput_conf.buttons["dpright"].capture_is_down = function(inp, btn, cnf, src)
   return src:getHat(1):find('r') ~= nil
end

-- Maps 'action name' -> 'action callback'
local jinput_actions = {
   ["delete_select"] = function() print("jinput_action: delete_select") end,
   ["exit_select"] =   function() print("jinput_action: exit_select") end,
   ["done_select"] =   function() print("jinput_action: done_select") end,
   ["space_select"] =  function() print("jinput_action: space_select") end,
   ["delete_accept"] = function()
      print("jinput_action: delete_accept")
      textbox:delete_last_char()
   end,
   ["exit_accept"] =   function() print("jinput_action: exit_accept") end,
   ["done_accept"] =   function() print("jinput_action: done_accept") end,
   ["space_accept"] =  function() print("jinput_action: space_accept") end,
   ["next_layout"] =   function() print("jinput_action: next_layout") end,
   ["prev_layout"] =   function() print("jinput_action: prev_layout") end,

   ["select_left"] =   function()
      print("jinput_action: select_left")
      local hit = left_analog:select_btn()
      if hit then love.audio.play(sounds.select) end
   end,
   ["accept_left"] =   function()
      print("jinput_action: accept_left")
      local accepted_btn = left_analog:accept_btn()
      if accepted_btn then
         love.audio.play(sounds.accept)
         textbox:append_text(accepted_btn.data.char)
      end
   end,
   ["select_right"] =  function()
      print("jinput_action: select_right")
      local hit = right_analog:select_btn()
      if hit then love.audio.play(sounds.select) end
   end,
   ["accept_right"] =  function()
      print("jinput_action: accept_right")
      local accepted_btn = right_analog:accept_btn()
      if accepted_btn then
         love.audio.play(sounds.accept)
         textbox:append_text(accepted_btn.data.char)
      end
   end,
   ["shift"] =         function() print("jinput_action: shift") end,
   ["caret_left"] =    function() print("jinput_action: caret_left") end,
   ["caret_right"] =   function() print("jinput_action: caret_right") end,
   ["caret_up"] =      function() print("jinput_action: caret_up") end,
   ["caret_down"] =    function() print("jinput_action: caret_down") end,
}

function aabb(x1, y1, w1, h1, x2, y2, w2, h2)
   return
      ((x1 <= x2 and x1 + w1 >= x2) or (x1 >= x2 and x2 + w2 >= x1))
      and
      ((y1 <= y2 and y1 + h1 >= y2) or (y1 >= y2 and y2 + h2 >= y1))
end

function aabb_objs(o1, o2)
   return aabb(
      o1.x, o1.y, o1.width, o1.height,
      o2.x, o2.y, o2.width, o2.height)
end

function init_analogs()
   local margin_x_from_edge = (vkeyboard.width / 3) * 0.7
   left_analog = Analog:new({
      x = vkeyboard.x + margin_x_from_edge,
      y = vkeyboard.y + vkeyboard.height / 2,
      reach_radius = vkeyboard.width / 3
   })
   right_analog = Analog:new({
      x = vkeyboard.x + vkeyboard.width - margin_x_from_edge,
      y = vkeyboard.y + vkeyboard.height / 2,
      reach_radius = vkeyboard.width / 3
   })
end

function try_init_joystick()
   local js = love.joystick.getJoysticks()
   if #js > 0 then
      joystick = js[1]
      joystick:setVibration(1, 1, 0.2)
      jinput = Input:new(jinput_conf)
      init_analogs()
      return true
   end

   return false
end

function love.load()
   love.window.updateMode(1920, 1080, {
      borderless = true,
      centered = true,
      fullscreen = global_conf.fullscreen,
      fullscreentype = "desktop",
   })
   love.window.setDisplaySleepEnabled(false)

   -- Load sounds
   sounds.select = love.audio.newSource("sounds/select.wav", "static")
   sounds.accept = love.audio.newSource("sounds/accept.wav", "static")

   window_width, window_height = love.graphics.getDimensions()

   key_font = lg.newFont("fonts/courier.ttf", key_font_size)
   local make_vkeybutton = function (txt)
      return Vkeybutton:new({
         text = txt,
         font = key_font,
         data = { type = "char", char = txt },
      })
   end
   local spacebar = Vkeybutton:new({
      text = " ",
      width = 800,
      font = key_font,
      data = { type = "char", char = " " },
   })

   local del = Vkeybutton:new({
      drawable = lg.newImage("images/delete.png"),
      corner_drawable = lg.newImage("images/XboxOne_X.png"),
      width = 300,
      data = { type = "action", action = "delete_accept" },
   })

   local done = Vkeybutton:new({
      text = "Done",
      font = key_font,
      width = 300,
      corner_drawable = lg.newImage("images/XboxOne_A.png"),
      data = { type = "action", action = "done_accept" },
   })

   vkeyboard = Vkeyboard:new({
      container_width = window_width,
      container_height = window_height,
      width = 1200,
      height = 480,
      recenter = true,
      button_rows = {
         map_str("1234567890-+", make_vkeybutton),
         map_str("qwertyuiop?!", make_vkeybutton),
         map_str("asdfghjkl:;\"", make_vkeybutton),
         map_str("zxcvbnm,./\\|",  make_vkeybutton),
         {spacebar, del, done},
      }
   })

   text_font = lg.newFont("fonts/courier.ttf", text_font_size)
   textbox = Textbox:new({
      font = text_font,
      width = 1200,
      x = (window_width - 1200) / 2,
      y = 120,
   })
   
   try_init_joystick()

   love.window.requestAttention()
end

function love.update(dt)
   if joystick == nil then try_init_joystick() end

   -- Capture joystick inputs
   jinput:capture_all(joystick)

   -- Trigger joystick button actions
   for btn_name, btn_conf in pairs(jinput.conf.buttons) do
      local btn_state = jinput.state.buttons[btn_name]

      -- on_release
      if btn_state.just_released then
         local action = jinput_actions[btn_conf.on_release]
         if action then action() end
      end

      -- on_press
      if btn_state.just_pressed then
         local action = jinput_actions[btn_conf.on_press]
         if action then action() end
      end
   end

   -- Trigger joystick asxii actions
   if left_analog then
      local lx = jinput.state.axii["leftx"].value
      local ly = jinput.state.axii["lefty"].value
      left_analog:update(lx, ly, dt)
   end
   if right_analog then
      local rx = jinput.state.axii["rightx"].value
      local ry = jinput.state.axii["righty"].value
      right_analog:update(rx, ry, dt)
   end

   local analogs = {left_analog, right_analog}

   -- Check analog collisions
   for _, row in ipairs(vkeyboard.button_rows) do
      for _, btn in ipairs(row) do
         for _, analog in ipairs(analogs) do
            if analog.state == "inactive" then goto continue end

            local ev = analog.collider:do_collision(btn.collider, get_time())
            if ev == "enter" then
               if analog.collider:get_first_colliding() == btn.collider then
                  btn:set_state("hovered")
               end
            elseif ev == "exit" then
               btn:set_state("idle")
               local col = analog.collider:get_first_colliding()
               if col then col.parent:set_state("hovered") end
            end
            ::continue::
         end
      end
   end

   -- Update keybaord
   vkeyboard:update(dt)
end

function love.keyreleased(key)
   if key == "q" then
      love.event.quit()
   end

   if key == "f1" then
      global_conf.debug_mode = not global_conf.debug_mode
   end

   if key == "1" then
      global_conf.analog_lerp = global_conf.analog_lerp - 0.02
   end

   if key == "2" then
      global_conf.analog_lerp = global_conf.analog_lerp + 0.02
   end

   if key == "3" then
      global_conf.axis_deadzone = global_conf.axis_deadzone - 0.01
   end

   if key == "4" then
      global_conf.axis_deadzone = global_conf.axis_deadzone + 0.01
   end

   if key == "5" then
      global_conf.axis_dampen_amount = global_conf.axis_dampen_amount - 0.01
   end

   if key == "6" then
      global_conf.axis_dampen_amount = global_conf.axis_dampen_amount + 0.01
   end
end

function love.draw()
   love.graphics.setBackgroundColor(global_conf.background_color)

   -- Draw joystick warning
   if joystick == nil then
      love.graphics.setColor(1, 1, 1)
      love.graphics.print("Joystick not connected", 100, 100)
      return
   end

   vkeyboard:draw()
   left_analog:draw()
   right_analog:draw()
   textbox:draw()

   -- Draw FPS
   if global_conf.debug_mode then
      lg.setColor(1, 1, 1, 1)
      local fps = love.timer.getFPS()
      love.graphics.print(
         fmt(
            "%d fps\n" ..
            "global_conf = %s",
            fps, inspect(global_conf)
         ), 10, 10)
   end
   deep.execute()
end
