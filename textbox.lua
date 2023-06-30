local lg = love.graphics

local Textbox = {
   x = 0,
   y = 0,
   z = 0,
   width = 0,
   height = nil,

   text_x = nil,
   text_y = nil,
   text_offset_y = 3,
   text_padding = 20,
   text_margin_left = 16,
   text_str = nil,
   text_obj = nil,
   font = nil,
   text_color = {1, 1, 1, 1},

   caret_x = nil,
   caret_y = nil,
   caret_width = 4,
   caret_height = nil,
   caret_color = {1, 1, 1, 1},
   caret_margin_left = 5,
   caret_extra_height = 2,

   container_canvas = nil,

   container_border_thickness = 3,
   container_border_color = {0.8, 0.8, 0.8, 1},
   container_border_corner_radius = 0,
   container_color = {0.125, 0.125, 0.125, 0.8},
   container_corner_radius = 0,
}

function Textbox:new(o)
   assert(o and type(o) == "table")
   assert(o.font)
   setmetatable(o, self)
   self.__index = self

   o:init()
   return o
end

function Textbox:init()
   self.text_obj = lg.newText(self.font, self.text_str or " ")

   if self.height == nil then
      self.height = self.text_obj:getHeight() + self.text_padding * 2
   end

   self.container_canvas = lg.newCanvas()
   lg.setCanvas(self.container_canvas)
   do
      lg.bordered_rectangle(
         0, 0, self.width, self.height,
         self.container_border_thickness,
         self.container_color,
         self.container_border_color,
         self.container_corner_radius
      )
   end
   lg.setCanvas()

   self:refresh()
end

function Textbox:refresh()
   self.text_obj:set(self.text_str or " ")
   local text_height = self.text_obj:getHeight()
   local text_width = self.text_str and self.text_obj:getWidth() or 0

   self.text_x = self.x + self.text_margin_left
   self.text_y = self.y + (self.height - text_height) / 2 + self.text_offset_y

   self.caret_height = text_height + self.caret_extra_height
   self.caret_x = self.text_x + text_width + self.caret_margin_left
   self.caret_y = self.y + (self.height - self.caret_height) / 2
end

function Textbox:append_text(str)
   if not self.text_str then
      self.text_str = str
   else
      self.text_str = self.text_str .. str
   end
   self:refresh()
end

function Textbox:delete_last_char()
   if not self.text_str then
      return
   end

   if #self.text_str == 1 then
      self.text_str = nil
      self:refresh()
      return
   end

   self.text_str = self.text_str:sub(1, #self.text_str-1)
   self:refresh()
end

function Textbox:draw_actual()
   lg.setColor(1, 1, 1, 1)
   lg.setBlendMode("alpha", "premultiplied")
   lg.draw(self.container_canvas, self.x, self.y)
   lg.setBlendMode("alpha")

   -- Draw the caret
   lg.setColor(self.caret_color)
   lg.rectangle(
      "fill",
      self.caret_x,
      self.caret_y,
      self.caret_width,
      self.caret_height
   )

   -- Draw the text
   if self.text_str then
      lg.setColor(self.text_color)
      lg.draw(self.text_obj, self.text_x, self.text_y)
   end
end

function Textbox:draw()
   deep.queue(self.z, self.draw_actual, self)
end

return Textbox
