require("map_funcs")

tween = require("lib/tween")
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
axis_dampen_amount = 0.8

vkeyboard = nil
left_analog = nil
right_analog = nil

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

function mod_axis(val)
   return apply_deadzone(val) * axis_dampen_amount
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

   -- Do controls
   if left_analog then
      local lx = mod_axis(joystick:getAxis(1))
      local ly = mod_axis(joystick:getAxis(2))
      left_analog:update(lx, ly, dt)
   end
   if right_analog then
      local rx = mod_axis(joystick:getAxis(4))
      local ry = mod_axis(joystick:getAxis(5))
      right_analog:update(rx, ry, dt)
   end

   -- Check analog collisions
   for _, row in ipairs(vkeyboard.button_rows) do
      for _, btn in ipairs(row) do
         if aabb(
            btn.collider_x,          btn.collider_y,
            btn.collider_width,      btn.collider_height,
            left_analog.x,           left_analog.y,
            left_analog.ring_radius, left_analog.ring_radius
         ) then
            btn.is_colliding = true
            left_analog:trigger_btn_collision()
         elseif aabb(
            btn.collider_x,           btn.collider_y,
            btn.collider_width,       btn.collider_height,
            right_analog.x,           right_analog.y,
            right_analog.ring_radius, right_analog.ring_radius
         ) then
            btn.is_colliding = true
            right_analog:trigger_btn_collision()
         else
            btn.is_colliding = false
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
