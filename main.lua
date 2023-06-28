inspect = require("lib/inspect")
fmt = string.format

local Analog = require("analog")

function printf(...)
   print(string.format(...))
end

global_conf = {
   fullscreen = false,
}
global_state = {
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
left_analog = nil
right_analog = nil

function init_vkeyboard()
   if vkeyboard.width + window_margin * 2 > window_width then
      vkeyboard.width = window_width - window_margin * 2
   end
   if vkeyboard.height + window_margin * 2 > window_height then
      vkeyboard.height = window_height - window_margin * 2
   end

   -- Center vkeyboard inside window
   vkeyboard.x = (window_width - vkeyboard.width) / 2
   vkeyboard.y = (window_height - vkeyboard.height) / 2
end

function init_joystick()
   joystick:setVibration(1, 1, 0.2)
   left_analog = Analog:new({
      x = vkeyboard.x + vkeyboard.width / 3,
      y = vkeyboard.y + vkeyboard.height / 2,
      reach_radius = vkeyboard.width / 3
   })
   right_analog = Analog:new({
      x = vkeyboard.x + vkeyboard.width / 3 * 2,
      y = vkeyboard.y + vkeyboard.height / 2,
      reach_radius = vkeyboard.width / 3
   })
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
   left_analog:update(joystick:getAxis(1), joystick:getAxis(2), dt)
   right_analog:update(joystick:getAxis(4), joystick:getAxis(5), dt)
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

   love.graphics.setColor(1, 0, 0, 0.2)
   love.graphics.rectangle("fill", vkeyboard.x, vkeyboard.y, vkeyboard.width, vkeyboard.height)

   left_analog:draw()
   right_analog:draw()
end
