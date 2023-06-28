
local lg = love.graphics

local Analog = {
   ring_color = {246/255, 233/255, 213/255, 100/255},
   ring_radius = 14,
   ring_thickness = 6,
   reach_radius = 200,
   anchor_x = nil,
   anchor_y = nil,
   x = 0,
   y = 0
}

function Analog:new(o)
   o = o or {}
   o.anchor_x = o.anchor_x or o.x
   o.anchor_y = o.anchor_y or o.y

   setmetatable(o, self)
   self.__index = self
   return o
end

function Analog:update(tilt_x, tilt_y, dt)
   self.x = self.anchor_x + self.reach_radius * tilt_x
   self.y = self.anchor_y + self.reach_radius * tilt_y
end

function Analog:draw()
   local hole_radius = self.ring_radius - self.ring_thickness
   for i=self.ring_radius, hole_radius, -1 do
      lg.setColor(self.ring_color)
      lg.circle("fill", self.x, self.y, i)
   end
end

return Analog
