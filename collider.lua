local lg = love.graphics

local Collider = {
   x = 0,
   y = 0,
   z = 0,
   width = 0,
   height = 0,
   parent = nil,
   collisions = nil,
   color = {0, 0, 0, 0.1},
   outline_color = {0, 0, 1, 1},
   outline_thickness = 2,
   debug_draw = false,
}

function Collider:new(o)
   assert(o and type(o) == "table")
   assert(o.parent)
   setmetatable(o, self)
   self.__index = self

   o.collisions = {}

   return o
end

local function aabb(x1, y1, w1, h1, x2, y2, w2, h2)
   return
      ((x1 <= x2 and x1 + w1 >= x2) or (x1 >= x2 and x2 + w2 >= x1))
      and
      ((y1 <= y2 and y1 + h1 >= y2) or (y1 >= y2 and y2 + h2 >= y1))
end

function Collider:aabb(col)
   return aabb(
      self.x,     self.y,
      self.width, self.height,
      col.x,      col.y,
      col.width,  col.height
   )
end

function Collider:get_first_colliding()
   local first = nil
   for col, time in pairs(self.collisions) do
      if first == nil or self.collisions[first] > time then
         first = col
      end
   end
   return first
end

function Collider:collision_enter(col, time)
   self.collisions[col] = time
end

function Collider:collision_exit(col)
   self.collisions[col] = nil
end

function Collider:do_collision(col, time)
   local was_colliding = self.collisions[col] ~= nil
   local is_colliding = self:aabb(col)

   if not was_colliding and is_colliding then
      self:collision_enter(col, time)
      -- NOTE: the line of code below would be TERRIBLE when doing a
      --       cartesian scan in an actual game.
      col:collision_enter(self, time)
      return "enter"
   elseif was_colliding and not is_colliding then
      self:collision_exit(col)
      -- NOTE: the line of code below would be TERRIBLE when doing a
      --       cartesian scan in an actual game.
      col:collision_exit(self)
      return "exit"
   end

   --dumptable(col, self)

   return "no_change"
end

function Collider:draw_actual()
   lg.bordered_rectangle(
      self.x, self.y, self.width, self.height,
      self.outline_thickness, self.color, self.outline_color, 0)
end

function Collider:draw()
   if self.debug_draw or global_conf.debug_mode then
      deep.queue(self.z, self.draw_actual, self)
   end
end

return Collider
