require("map_funcs")

inspect = require("lib/inspect")
function dumptable(t) print(inspect(t)) end
fmt = string.format
function printf(...) print(string.format(...)) end

local Analog = require("analog")
local Vkeyboard = require("vkeyboard")
local Vkeybutton = require("vkeybutton")
local lg = love.graphics

local key_font = nil
local key_font_size = 24

global_conf = {
   fullscreen = true,
   alt_background_color = {77/255, 169/255, 220/255, 1},
   background_color = {89/255, 157/255, 220/255},
}
global_state = {
}

window_width = 0
window_height = 0

joystick = nil -- Currently active joystick
axis_deadzone = 0.08

vkeyboard = nil
left_analog = nil
right_analog = nil

function init_analogs()
   local margin_x_from_edge = (vkeyboard.width / 3) * 0.8
   left_analog = Analog:new({
      x = vkeyboard.x + margin_x_from_edge,
      y = vkeyboard.y + vkeyboard.height / 2,
      reach_radius = vkeyboard.width / 4
   })
   right_analog = Analog:new({
      x = vkeyboard.x + vkeyboard.width - margin_x_from_edge,
      y = vkeyboard.y + vkeyboard.height / 2,
      reach_radius = vkeyboard.width / 4
   })
end

function try_init_joystick()
   local js = love.joystick.getJoysticks()
   if #js > 0 then
      joystick = js[1]
      joystick:setVibration(1, 1, 0.2)
      init_analogs()
      return true
   end

   return false
end

function apply_deadzone(val)
   if math.abs(val) > axis_deadzone then
      return val
   else
      return 0
   end
end

function love.load()
   love.window.updateMode({
      borderless = false,
      centered = true,
      fullscreen = global_conf.fullscreen,
      fullscreentype = "desktop",
   })
   love.window.setDisplaySleepEnabled(false)

   -- TODO: love.window.setIcon()

   window_width, window_height = love.graphics.getDimensions()

   key_font = lg.newFont("fonts/courier.ttf", key_font_size)
   local make_vkeybutton = function (txt)
      return Vkeybutton:new({ text = txt, font = key_font })
   end

   vkeyboard = Vkeyboard:new({
      container_width = window_width,
      container_height = window_height,
      recenter = true,
      button_rows = {
         map_str("1234567890", make_vkeybutton),
         map_str("qwertyuiop", make_vkeybutton),
         map_str("asdfghjkl\"", make_vkeybutton),
         map_str("zxcvbnm,.!",  make_vkeybutton),
      }
   })
   
   try_init_joystick()

   love.window.requestAttention()
end

function love.update(dt)
   if joystick == nil then try_init_joystick() end

   if left_analog then
      local lx = apply_deadzone(joystick:getAxis(1))
      local ly = apply_deadzone(joystick:getAxis(2))
      left_analog:update(lx, ly, dt)
   end
   if right_analog then
      local rx = apply_deadzone(joystick:getAxis(4))
      local ry = apply_deadzone(joystick:getAxis(5))
      right_analog:update(rx, ry, dt)
   end
end

function love.keyreleased(key)
   if key == "q" then
      love.event.quit()
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
end
