local lg = love.graphics

local Vkeybutton = {
   x = 0,
   y = 0,
   width = 60,
   height = 80,
   color = {0.5, 0.5, 0.5, 1},
   text_color = {1, 1, 1, 1},
   text = nil,
   font = nil,

   corner_radius = 0,
   border_color = {0, 0, 0, 0.8},
   border_thickness = 4,

   drawable = nil,
   drawable_width = 0,
   drawable_height = 0,
   drawable_offset_x = 0,
   drawable_offset_y = 0,
   center_drawable = false
}

function Vkeybutton:new(o)
   assert(o and type(o) == "table")
   assert(o.drawable or (o.text and o.font))

   setmetatable(o, self)
   self.__index = self

   o:init()
   return o
end

function Vkeybutton:init()
   -- If text & font given, we create our own drawable
   if self.text then
      self.drawable = lg.newText(self.font, self.text)
      self.drawable_width = self.drawable:getWidth()
      self.drawable_width = self.drawable:getHeight()
   end

   if self.center_drawable then
      self.drawable_offset_x = (self.width - self.drawable_width) / 2
      self.drawable_offset_y = (self.height - self.drawable_height) / 2
   end
end

function Vkeybutton:draw()
   -- Button border
   lg.setColor(self.border_color)
   lg.rectangle(
      "fill",
      self.x,
      self.y,
      self.width,
      self.height,
      self.corner_radius,
      self.corner_radius
   )

   -- Button inside
   lg.setColor(self.color)
   lg.rectangle(
      "fill",
      self.x + self.border_thickness,
      self.y + self.border_thickness,
      self.width - self.border_thickness * 2,
      self.height - self.border_thickness * 2,
      self.corner_radius,
      self.corner_radius
   )

   -- Drawable inside the button
   lg.setColor(self.text_color)
   lg.draw(
      self.drawable,
      self.x + self.drawable_offset_x,
      self.y + self.drawable_offset_y
   )
end

function Vkeybutton:update(dt)

end

return Vkeybutton
