local lg = love.graphics

local Vkeybutton = {
   x = 0,       collider_x = 0,
   y = 0,       collider_y = 0,
   width = 100,  collider_width = 60,
   height = 130, collider_height = 80,
   scale_x = 1,
   scale_y = 1,

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
   center_drawable = false,
   fit_collider = true,

   canvas = nil,
   is_colliding = false,
   was_colliding = false,
   tweens = {
      scale = nil,
      scale_done = true,
   },
}

function Vkeybutton:new(o)
   assert(o and type(o) == "table")
   assert(o.drawable or (o.text and o.font))

   setmetatable(o, self)
   self.__index = self

   o:init()
   return o
end

function Vkeybutton:resize_collider()
   self.collider_x = self.x
   self.collider_y = self.y
   self.collider_width = self.width
   self.collider_height = self.height
end

function Vkeybutton:init()
   if self.fit_collider then
      self:resize_collider()
   end

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

   if self.canvas == nil then
      self.canvas = lg.newCanvas(self.width, self.height)
   end

   -- Predraw onto canvas
   lg.setCanvas(self.canvas)
   do
      lg.clear(0, 0, 0, 0)
      lg.setBlendMode("alpha")

      -- Button border
      lg.setColor(self.border_color)
      lg.rectangle(
         "fill",
         0, 0,
         self.width,
         self.height,
         self.corner_radius,
         self.corner_radius
      )

      -- Button inside
      lg.setColor(self.color)
      lg.rectangle(
         "fill",
         self.border_thickness,
         self.border_thickness,
         self.width - self.border_thickness * 2,
         self.height - self.border_thickness * 2,
         self.corner_radius,
         self.corner_radius
      )

      -- Drawable inside the button
      lg.setColor(self.text_color)
      lg.draw(
         self.drawable,
         self.drawable_offset_x,
         self.drawable_offset_y
      )
   end
   lg.setCanvas()
end

function Vkeybutton:draw()
   lg.setColor(1, 1, 1, 1)
   lg.setBlendMode("alpha", "premultiplied")
   lg.draw(
      self.canvas,
      self.x + self.width/2,
      self.y + self.height/2,
      0,
      self.scale_x,
      self.scale_y,
      self.width/2,
      self.height/2
   )
   lg.setBlendMode("alpha")

   lg.setColor(0, 0, 1, 1)
   lg.rectangle("line", self.collider_x, self.collider_y, self.collider_width, self.collider_height)
end

function Vkeybutton:update(dt)
   -- Check collision enter
   if not self.was_colliding and self.is_colliding then
      local cw = self.collider_width * 1.3
      local ch = self.collider_height * 1.3
      self.tweens.scale = tween.new(0.1, self, {
         scale_x = 1.5,
         scale_y = 1.5,
         -- TODO:
         -- collider_width = cw,
         -- collider_height = ch,
         tweens = { scale = nil },
      }, "outQuad")
   elseif self.was_colliding and not self.is_colliding then
      -- Check collision exit
      self.tweens.scale = tween.new(0.2, self, {
         scale_x = 1,
         scale_y = 1,
         tweens = { scale = nil },
      }, "outCubic")
   end

   if self.tweens.scale then
      self.tweens.scale:update(dt)
   end

   if not self.is_colliding then
      self.was_colliding = true
   else
      self.was_colliding = false
   end
end

return Vkeybutton
