
local lg = love.graphics

local Collider = require("collider")
local Analog = {
   ring_color = {0, 0, 0, 0},
   shadow_color = {0, 0, 0, 0},
   active_ring_color = {246/255, 233/255, 213/255, 0.9},
   active_shadow_color = {0, 0, 0, 0.4},
   inactive_ring_color = {200/255, 200/255, 200/255, 0.6},
   inactive_shadow_color = {0, 0, 0, 0.1},
   collider_radius = 6,
   ring_radius = 14,
   ring_thickness = 7,
   inner_shadow_thickness = 3,
   outer_shadow_thickness = 2,
   reach_radius = 200,
   anchor_x = nil,
   anchor_y = nil,
   collider = nil,
   currently_selected_btn = nil,
   idle_time = 0,
   inactive_timeout = 2,
   x = 0,
   y = 0,
   z = 10,
   state = "inactive",
   print_state = false,
   draw_radius = false,
   tweens = {
      fade = nil,
   },
}

function Analog:new(o)
   o = o or {}
   o.anchor_x = o.anchor_x or o.x
   o.anchor_y = o.anchor_y or o.y

   setmetatable(o, self)
   self.__index = self

   o:init()
   return o
end

function Analog:init()
   self.collider = Collider:new({
      parent = self,
      x = self.x - self.collider_radius/2,
      y = self.y - self.collider_radius/2,
      z = self.z,
      width = self.collider_radius * 2,
      height = self.collider_radius * 2,
   })
   self:set_state("active")
end


local function apply_deadzone(val)
   if math.abs(val) > global_conf.axis_deadzone then
      return val
   else
      return 0
   end
end

local function mod_axis(val)
   return apply_deadzone(val) * global_conf.axis_dampen_amount
end

function Analog:set_state(new_state)
   if self.state == new_state then return end

   if new_state == "active" then
      self.idle_time = 0
      self.tweens.fade = tween.new(0.3, self, {
         ring_color = self.active_ring_color,
         shadow_color = self.active_shadow_color,
         tweens = { fade = nil },
      }, "outQuad")
      self.state = new_state
   elseif new_state == "inactive" then
      self.tweens.fade = tween.new(0.9, self, {
         ring_color = self.inactive_ring_color,
         shadow_color = self.inactive_shadow_color,
         tweens = { fade = nil },
      }, "outQuad", function(self)
         for col, time in pairs(self.collider.collisions) do
            col:collision_exit(self.collider)
            col.parent:set_state("idle")
         end
         self.collider.collisions = {}
      end)
      self.state = new_state
   end
end

function Analog:select_btn()
   local col = self.collider:get_first_colliding()
   if not col or not col.parent then return false end
   self.selected_btn = col.parent
   col.parent:set_state("selected")
   return true
end

function Analog:accept_btn()
   local col = self.collider:get_first_colliding()
   if not col or not col.parent then return end

   if self.selected_btn == col.parent then
      col.parent:set_state("accepted")
      return col.parent
   else
      print("false accept")
      -- TODO: do 'false accepted' state for the button
      return nil
   end
end

function Analog:update(tilt_x, tilt_y, dt)
   tilt_x = mod_axis(tilt_x)
   tilt_y = mod_axis(tilt_y)
   self.x = lerp(self.x, self.anchor_x + self.reach_radius * tilt_x, global_conf.analog_lerp)
   self.y = lerp(self.y, self.anchor_y + self.reach_radius * tilt_y, global_conf.analog_lerp)
   self.collider.x = self.x - self.collider.width/2
   self.collider.y = self.y - self.collider.height/2

   if self.tweens.fade then
      self.tweens.fade:update(dt)
   end

   -- TODO: fix some bug with this?
   if tilt_x == 0 and tilt_y == 0 then
      self.idle_time = self.idle_time + dt
      if self.idle_time > self.inactive_timeout then
         self:set_state("inactive")
      end
      return
   end

   self:set_state("active")
end

local function draw_ring(x, y, outer_r, thickness)
   local hole_radius = outer_r - thickness
   for i=outer_r, hole_radius + 1, -1 do
      lg.circle("line", x, y, i)
   end
end

function Analog:draw_actual()
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

   if self.print_state or global_conf.debug_mode then
      lg.setColor(1, 1, 1, 1)
      lg.print(self.state, self.x, self.y)
   end

   -- Draw reach radius
   if self.draw_radius or global_conf.debug_mode then
      lg.setColor(0, 1, 1, 1)
      local s = self.reach_radius * 2 * global_conf.axis_dampen_amount
      lg.rectangle("line", self.anchor_x - s/2, self.anchor_y - s/2, s, s, 60, 60)
   end

   -- Draw deadzone
   if self.draw_deadzone or global_conf.debug_mode then
      lg.setColor(0, 1, 0.7, 1)
      local s = self.reach_radius * global_conf.axis_deadzone * 2
      lg.rectangle("line", self.anchor_x - s/2, self.anchor_y - s/2, s, s, 10, 10)
   end
end

function Analog:draw()
   deep.queue(self.z, self.draw_actual, self)
end

return Analog
