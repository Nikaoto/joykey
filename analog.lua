
local lg = love.graphics

local Analog = {
   ring_color = {246/255, 233/255, 213/255, 0.8},
   shadow_color = {0, 0, 0, 0.3},
   ring_radius = 14,
   ring_thickness = 7,
   inner_shadow_thickness = 3,
   outer_shadow_thickness = 2,
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

local function draw_ring(x, y, outer_r, thickness)
   local hole_radius = outer_r - thickness
   for i=outer_r, hole_radius + 1, -1 do
      lg.circle("line", x, y, i)
   end
end

function Analog:draw()
   -- Draw main ring
   lg.setColor(self.ring_color)
   draw_ring(self.x, self.y, self.ring_radius, self.ring_thickness)

   -- Draw outer shadow
   lg.setColor(self.shadow_color)
   draw_ring(
      self.x,
      self.y,
      self.ring_radius + self.outer_shadow_thickness,
      self.outer_shadow_thickness
   )

   -- Draw inner shadow
   lg.setColor(self.shadow_color)
   draw_ring(
      self.x,
      self.y,
      self.ring_radius - self.ring_thickness,
      self.inner_shadow_thickness
   )
end

function Analog:trigger_btn_collision()
end

return Analog
