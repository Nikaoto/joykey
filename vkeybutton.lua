local lg = love.graphics

local Vkeybutton = {
   x = 0,       collider_x = 0,
   y = 0,       collider_y = 0,
   z = 2,
   width = 110,  collider_width = 110,
   height = 110, collider_height = 110,
   scale = 1,
   normal_scale = 1,
   hovered_scale = 1.4,
   normal_z = 2,
   hovered_z = 3,

   color = {0.2, 0.2, 0.2, 1},
   text_color = {1, 1, 1, 1},
   text = nil,
   font = nil,
   data = nil,

   corner_radius = 0,
   border_color = {0.8, 0.8, 0.8, 1},
   border_thickness = 4,

   drawable = nil,
   drawable_width = 0,
   drawable_height = 0,
   drawable_offset_x = 0,
   drawable_offset_y = 0,
   drawable_adjust_offset_y = 4,
   center_drawable = true,
   fit_collider = true,
   draw_collider = false,
   draw_drawable_footprint = false,

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
   self.z = self.normal_z

   if self.fit_collider then
      self:resize_collider()
   end

   -- If text & font given, we create our own drawable
   if self.text then
      self.drawable = lg.newText(self.font, self.text)
      self.drawable_width = self.drawable:getWidth()
      self.drawable_height = self.drawable:getHeight()
   end

   if self.center_drawable then
      self.drawable_offset_x = (self.width - self.drawable_width) / 2
      self.drawable_offset_y = (self.height - self.drawable_height) / 2
   end

   if self.canvas == nil then
      self.canvas = lg.newCanvas(self.width, self.height)
      --self.canvas:setFilter("nearest")
   end

   -- Predraw onto canvas
   lg.setCanvas(self.canvas)
   do
      lg.clear(0, 0, 0, 0)
      lg.setBlendMode("alpha")
      lg.bordered_rectangle(
         0,          0,
         self.width, self.height,
         self.border_thickness,
         self.color,
         self.border_color,
         self.corner_radius
      )

      -- Drawable (text) inside the button
      lg.setColor(self.text_color)
      lg.draw(
         self.drawable,
         self.drawable_offset_x,
         self.drawable_offset_y + self.drawable_adjust_offset_y
      )

      if self.draw_drawable_footprint then
         lg.setColor(1, 0, 0, 0.1)
         lg.rectangle(
            "fill",
            self.drawable_offset_x,
            self.drawable_offset_y + self.drawable_adjust_offset_y,
            self.drawable_width,
            self.drawable_height
         )
      end
   end
   lg.setCanvas()
end

function Vkeybutton:draw_actual()
   lg.setColor(1, 1, 1, 1)
   lg.setBlendMode("alpha", "premultiplied")
   do
      lg.draw(
         self.canvas,
         self.x + self.width/2,
         self.y + self.height/2,
         0,
         self.scale,
         self.scale,
         self.width/2,
         self.height/2
      )
   end
   lg.setBlendMode("alpha")

   -- Draw collider
   if self.draw_collider then
      lg.setColor(0, 0, 1, 1)
      lg.rectangle(
         "line",
         self.collider_x,
         self.collider_y,
         self.collider_width,
         self.collider_height
      )
   end
end

function Vkeybutton:draw()
   deep.queue(self.z, self.draw_actual, self)
end

function Vkeybutton:update_collider()
   self.collider_x = self.x - (self.scale - 1)/2 * self.width
   self.collider_y = self.y - (self.scale - 1)/2 * self.height
   self.collider_width = self.width * self.scale
   self.collider_height = self.height * self.scale
end

function Vkeybutton:update(dt)
   -- Update collider
   self:update_collider()

   -- Check collision enter
   if not self.was_colliding and self.is_colliding then
      self.z = self.hovered_z
      self.tweens.scale = tween.new(0.1, self, {
         scale = self.hovered_scale,
         tweens = { scale = nil },
      }, "outQuad")
   elseif self.was_colliding and not self.is_colliding then
      -- Check collision exit
      self.z = self.normal_z
      self.tweens.scale = tween.new(0.2, self, {
         scale = self.normal_scale,
         tweens = { scale = nil },
      }, "outCubic")
   end

   -- Update tweens
   if self.tweens.scale then
      self.tweens.scale:update(dt)
   end

   -- Save collision state for next frame
   if not self.is_colliding then
      self.was_colliding = true
   else
      self.was_colliding = false
   end
end

return Vkeybutton
