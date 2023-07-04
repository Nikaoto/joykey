local lg = love.graphics

local Vkeyboard = {
   x = 0,
   y = 0,
   z = 1,
   width = 1200,
   height = 480,
   row_margin = 12,
   column_margin = 12,
   container_margin = 10,
   container_width = nil,
   container_height = nil,
   recenter = false,
   draw_collider = false,
   buttons = {},
}

function Vkeyboard:new(o)
   assert(o and type(o) == "table")
   assert(o.container_width)
   assert(o.container_height)
   assert(o.button_rows and type(o.button_rows) == "table")
   setmetatable(o, self)
   self.__index = self

   o:init()
   return o
end

function Vkeyboard:resize_to_fit_container()
   local resized = false

   if self.width + self.container_margin * 2 > self.container_width then
      self.width = self.container_width - self.container_margin * 2
      resized = true
   end
   if self.height + self.container_margin * 2 > self.container_height then
      self.height = self.container_height - self.container_margin * 2
      resized = true
   end

   return resized
end

function Vkeyboard:recenter_keyboard()
   self.x = (self.container_width - self.width) / 2
   self.y = (self.container_height - self.height) / 2
end

function Vkeyboard:rearrange_keys()
   local row_y = self.y
   for ri, row in ipairs(self.button_rows) do
      local row_width = reduce_arr(row, -self.column_margin, function(acc, btn)
         return acc + btn.width + self.column_margin
      end)
      local row_height = max_in_arr(row, function(btn) return btn.height end)
      -- TODO: fix centering bug
      local btn_x = center_1D(self.x, self.width, row_width)
      for ci, btn in ipairs(row) do
         btn.x = btn_x
         btn.y = row_y
         btn:resize_collider()
         btn_x = btn_x + btn.width + self.column_margin
      end

      row_y = row_y + row_height + self.row_margin
   end
end

function Vkeyboard:init()
   local resized = self:resize_to_fit_container()

   if resized or self.recenter then
      self:recenter_keyboard()
   end

   self:rearrange_keys()
end

function Vkeyboard:draw_actual()
   -- Draw outline
   if self.draw_collider or global_conf.debug_mode then
      love.graphics.setColor(1, 0, 0, 1)
      love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
   end
end

function Vkeyboard:draw()
   deep.queue(self.z + 10, self.draw_actual, self)

   -- Draw buttons
   for i, row in ipairs(self.button_rows) do
      for j, btn in ipairs(row) do
         btn:draw()
      end
   end
end

function Vkeyboard:update(dt)
   -- Update buttons
   for i, row in ipairs(self.button_rows) do
      for j, btn in ipairs(row) do
         btn:update(dt)
      end
   end
end

return Vkeyboard
