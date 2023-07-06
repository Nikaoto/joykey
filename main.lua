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
local text_font_size = 46
local key_font = nil
local key_font_size = 46
local action_key_font = nil
local action_key_font_size = 28

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
local jinput_conf = {}
do
   local is_axis_down = function(inp, axis, cnf, src)
      local threshold = cnf.thr
      return cnf.thr < src:getGamepadAxis(cnf.axis_name)
   end
   jinput_conf = {
      capture_fns = {
         is_button_down = function(inp, btn, cnf, src)
            return src:isGamepadDown(btn)
         end,
         get_axis = function(inp, axis, cnf, src)
            return src:getGamepadAxis(axis)
         end,
         is_axis_down = is_axis_down,
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
         ["triggerleft_btn"] = {
            thr = 0.8,
            on_press = "shift_select",
            on_release = "shift_accept",
            axis_name = "triggerleft",
            capture_is_down = is_axis_down,
         },
         ["triggerright_btn"] = {
            thr = 0.8,
            on_press = "switch_select",
            on_release = "switch_accept",
            axis_name = "triggerright",
            capture_is_down = is_axis_down,
         },
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
end

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

local delbtn = nil
local donebtn = nil
local spacebtn = nil
local switchbtn = nil

-- Maps 'action name' -> 'action callback'
local jinput_actions = {
   ["done_select"] =   function()
      if donebtn then
         love.audio.play(sounds.select)
         donebtn:set_state("selected")
      end
   end,
   ["done_accept"] =   function()
      if donebtn then
         love.audio.play(sounds.accept)
         donebtn:set_state("accepted")
         joystick:setVibration(1, 1, 0.1)
      end
   end,

   ["space_select"] =  function()
      if spacebtn then
         love.audio.play(sounds.select)
         spacebtn:set_state("selected")
      end
   end,
   ["space_accept"] =  function()
      if spacebtn then
         love.audio.play(sounds.accept)
         textbox:append_text(spacebtn.data.char)
         spacebtn:set_state("accepted")
         joystick:setVibration(1, 1, 0.1)
      end
   end,

   ["delete_select"] = function()
      if delbtn then
         love.audio.play(sounds.select)
         delbtn:set_state("selected")
      end
   end,
   ["delete_accept"] = function()
      if delbtn then
         love.audio.play(sounds.accept)
         delbtn:set_state("accepted")
         joystick:setVibration(1, 1, 0.1)
      end
      textbox:delete_last_char()
   end,

   ["exit_select"] =   function() print("jinput_action: exit_select") end,
   ["exit_accept"] =   function() print("jinput_action: exit_accept") end,

   ["next_layout"] =   function() print("jinput_action: next_layout") end,
   ["prev_layout"] =   function() print("jinput_action: prev_layout") end,

   ["select_left"] =   function()
      local hit = left_analog:select_btn()
      if hit then love.audio.play(sounds.select) end
   end,
   ["accept_left"] =   function(self)
      local accepted_btn = left_analog:accept_btn()
      if accepted_btn then
         love.audio.play(sounds.accept)
         if accepted_btn.data.type == "char" then
            textbox:append_text(accepted_btn.data.char)
         elseif accepted_btn.data.type == "action" then
            local act = self[accepted_btn.data.action]
            if act then act(self) end
         end
      end
   end,

   ["select_right"] =  function()
      local hit = right_analog:select_btn()
      if hit then love.audio.play(sounds.select) end
   end,
   ["accept_right"] =  function(self)
      local accepted_btn = right_analog:accept_btn()
      if accepted_btn then
         love.audio.play(sounds.accept)
         if accepted_btn.data.type == "char" then
            textbox:append_text(accepted_btn.data.char)
         elseif accepted_btn.data.type == "action" then
            local act = self[accepted_btn.data.action]
            if act then act(self) end
         end
         joystick:setVibration(1, 1, 0.1)
      end
   end,

   ["shift_select"] = function()
      if shiftbtn then
         love.audio.play(sounds.select)
         shiftbtn:set_state("selected")
      end
   end,
   ["shift_accept"] = function()
      if shiftbtn then
         love.audio.play(sounds.accept)
         shiftbtn:set_state("accepted")
         joystick:setVibration(1, 1, 0.1)
      end
   end,

   ["switch_select"] = function()
      if switchbtn then
         love.audio.play(sounds.select)
         switchbtn:set_state("selected")
      end
   end,
   ["switch_accept"] = function()
      if switchbtn then
         love.audio.play(sounds.accept)
         switchbtn:set_state("accepted")
         joystick:setVibration(1, 1, 0.1)
      end
   end,

   ["caret_left"] =    function() print("jinput_action: caret_left") end,
   ["caret_right"] =   function() print("jinput_action: caret_right") end,
   ["caret_up"] =      function() print("jinput_action: caret_up") end,
   ["caret_down"] =    function() print("jinput_action: caret_down") end,
}

function init_analogs()
   local margin_x_from_edge = vkeyboard.width * 0.25
   left_analog = Analog:new({
      x = vkeyboard.x + margin_x_from_edge,
      y = vkeyboard.y + vkeyboard.height / 2 + 35,
      reach_radius = vkeyboard.width * 0.3
   })
   right_analog = Analog:new({
      x = vkeyboard.x + vkeyboard.width - margin_x_from_edge,
      y = vkeyboard.y + vkeyboard.height / 2 + 35,
      reach_radius = vkeyboard.width * 0.3
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
   love.window.updateMode(1366, 768, {
      borderless = true,
      centered = true,
      fullscreen = global_conf.fullscreen,
      fullscreentype = "desktop",
   })
   love.window.setDisplaySleepEnabled(false)

   -- Load sounds
   sounds.select = love.audio.newSource("sounds/select.wav", "static")
   sounds.accept = love.audio.newSource("sounds/accept.wav", "static")
   --sounds.accept:setVolume(0)

   window_width, window_height = love.graphics.getDimensions()

   key_font = lg.newFont("fonts/courier.ttf", key_font_size)
   action_key_font = lg.newFont("fonts/courier.ttf", action_key_font_size)
   local make_vkeybutton = function (txt)
      return Vkeybutton:new({
         text = txt,
         font = key_font,
         data = { type = "char", char = txt },
      })
   end

   shiftbtn = Vkeybutton:new({
      text = "Shift",
      width = 200,
      font = action_key_font,
      corner_drawable = lg.newImage("images/XboxOne_LT.png"),
      data = { type = "action", action = nil },
   })

   switchbtn = Vkeybutton:new({
      text = "...",
      font = action_key_font,
      width = 140,
      corner_drawable = lg.newImage("images/XboxOne_RT.png"),
      data = { type = "action", action = nil },
   })

   spacebtn = Vkeybutton:new({
      text = " ",
      width = 340,
      font = action_key_font,
      corner_drawable = lg.newImage("images/XboxOne_Y.png"),
      data = { type = "char", char = " " },
   })

   delbtn = Vkeybutton:new({
      text = "Delete",
      font = action_key_font,
      corner_drawable = lg.newImage("images/XboxOne_X.png"),
      width = 200,
      data = { type = "action", action = "delete_accept" },
   })

   donebtn = Vkeybutton:new({
      text = "Done",
      font = action_key_font,
      width = 180,
      corner_drawable = lg.newImage("images/XboxOne_A.png"),
      data = { type = "action", action = "done_accept" },
   })

   vkeyboard = Vkeyboard:new({
      container_width = window_width,
      container_height = window_height,
      width = 1120,
      height = 400,
      recenter = true,
      button_rows = {
         map_str("1234567890-", make_vkeybutton),
         map_str("qwertyuiop\"", make_vkeybutton),
         map_str("asdfghjkl-_", make_vkeybutton),
         map_str("zxcvbnm,.?!",  make_vkeybutton),
         {shiftbtn, switchbtn, spacebtn, delbtn, donebtn},
      }
   })

   text_font = lg.newFont("fonts/courier.ttf", text_font_size)
   textbox = Textbox:new({
      font = text_font,
      width = 1000,
      x = (window_width - 1000) / 2,
      y = 60,
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
         if action then action(jinput_actions) end
      end

      -- on_press
      if btn_state.just_pressed then
         local action = jinput_actions[btn_conf.on_press]
         if action then action(jinput_actions) end
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
