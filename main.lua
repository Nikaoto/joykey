inspect = require("lib/inspect")
fmt = string.format

function printf(...)
   print(string.format(...))
end

global_conf = {
   fullscreen = false,
}
global_state = {
   analog_ring_color = {246/255, 233/255, 213/255, 100/255},
   analog_ring_thickness = 6,
   analog_ring_outside_radius = 14,
}

vkeyboard = {
   width = 800,
   height = 600,
   x = 0,
   y = 0,
}

window_margin = 10
window_width = 0
window_height = 0
joystick = nil -- Currently active joystick
left_analog = { x = 0, y = 0 }
right_analog = { x = 0, y = 0 }

function init_vkeyboard()
   if vkeyboard_width > window_width then
      vkeyboard_width = window_width - window_margin * 2
   end
   if vkeyboard_height > window_height then
      vkeyboard_height = window_height - window_margin * 2
   end

   -- Center vkeyboard inside window
   vkeyboard.x = (window_width - vkeyboard.width) / 2
   vkeyboard.y = (window_height - vkeyboard.height) / 2
end

function init_joystick()
   joystick:setVibration(1, 1, 0.2)
   left_analog.x = vkeyboard.x + vkeyboard.width / 3
   left_analog.y = vkeyboard.y + vkeyboard.height / 2
   right_analog.x = vkeyboard.x + vkeyboard.width / 3 * 2
   right_analog.y = vkeyboard.y + vkeyboard.height / 2
end

function draw_analog(x, y)
   love.graphics.setColor()
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

   init_vkeyboard()

   local js = love.joystick.getJoysticks()
   if #js > 0 then
      joystick = js[1]
      init_joystick()
   end

   love.window.requestAttention()
end

function love.update(dt)
end

function love.keyreleased(key)
   if key == "q" then
      love.event.quit()
   end
end

function love.draw()
   love.graphics.setBackgroundColor(89/255, 157/255, 220/255)

   if joystick == nil then
      love.graphics.setColor(1, 1, 1)
      love.graphics.print("Joystick not connected", 100, 100)
      return
   end

   draw_analog(left_analog.x, left_analog.y)
   draw_analog(right_analog.x, right_analog.y)
   
end
