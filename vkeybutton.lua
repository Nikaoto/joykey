local lg = love.graphics

local Collider = require("collider")

local Vkeybutton = {
   x = 0,
   y = 0,
   z = 2,
   width = 110,
   height = 110,
   collider = nil,
   scale_x = 1,
   scale_y = 1,
   normal_scale_x = 1,
   normal_scale_y = 1,
   hovered_scale_x = 1.4,
   hovered_scale_y = 1.4,
   selected_scale_x = 1.8,
   selected_scale_y = 1.1,
   accepted_scale_x = 1.7,
   accepted_scale_y = 1.9,
   normal_z = 2,
   hovered_z = 3,
   selected_z = 4,
   accepted_z = 5,

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

   states = {
      ["idle"] = {
         transitions = {
            ["hovered"] = function(self)
               self.z = self.hovered_z
               self.collider.z = self.hovered_z
               self.tweens.scale = tween.new(0.2, self, {
                  scale_x = self.hovered_scale_x,
                  scale_y = self.hovered_scale_y,
               }, "outQuad")
            end
         },
      },
      ["hovered"] = {
         transitions = {
            ["selected"] = function(self)
               self.z = self.selected_z
               self.collider.z = self.selected_z
               self.tweens.scale = tween.new(0.5, self, {
                  scale_x = self.selected_scale_x,
                  scale_y = self.selected_scale_y,
               }, "outElastic")
            end,
            ["idle"] = function(self)
               self.z = self.normal_z
               self.collider.z = self.normal_z
               self.tweens.scale = tween.new(0.2, self, {
                  scale_x = self.normal_scale_x,
                  scale_y = self.normal_scale_y,
               }, "outCubic")
            end
         },
      },
      ["selected"] = {
         transitions = {
            ["accepted"] = function(self)
               self.z = self.accepted_z
               self.collider.z = self.accepted_z
               self.tweens.scale = tween.new(0.2, self, {
                  scale_x = self.accepted_scale_x,
                  scale_y = self.accepted_scale_y,
               }, "outElastic", function(self)
                  self:set_state("hovered")
               end)
            end,
            ["idle"] = function(self)
               self.z = self.normal_z
               self.collider.z = self.normal_z
               self.tweens.scale = tween.new(0.1, self, {
                  scale_x = self.normal_scale_x,
                  scale_y = self.normal_scale_y,
               }, "outCubic")
            end,
         }
      },
      ["accepted"] = {
         transitions = {
            ["idle"] = function(self)
               self.z = self.normal_z
               self.collider.z = self.normal_z
               self.tweens.scale = tween.new(0.08, self, {
                  scale_x = self.normal_scale_x,
                  scale_y = self.normal_scale_y,
               }, "outCubic")
            end,
            ["hovered"] = function(self)
               self.z = self.hovered_z
               self.collider.z = self.hovered_z
               self.tweens.scale = tween.new(0.2, self, {
                  scale_x = self.hovered_scale_x,
                  scale_y = self.hovered_scale_y,
               }, "outQuad")
            end,
         },
      },
      ["false_accepted"] = { transitions = {}},
   },
   state = "idle",
   canvas = nil,
   tweens = nil,
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
   self.collider.x = self.x
   self.collider.y = self.y
   self.collider.width = self.width
   self.collider.height = self.height
end

function Vkeybutton:init()
   self.z = self.normal_z
   self.tweens = { scale = nil }

   self.collider = Collider:new({
      parent = self,
      z = self.z
   })
   self:resize_collider()

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

      if self.draw_drawable_footprint or global_conf.debug_mode then
         lg.setColor(1, 0, 0, 0.4)
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
         self.scale_x,
         self.scale_y,
         self.width/2,
         self.height/2
      )
   end
   lg.setBlendMode("alpha")

   if self.print_state or global_conf.debug_mode then
      lg.print(self.state, self.x, self.y)
   end
end

function Vkeybutton:draw()
   deep.queue(self.z, self.draw_actual, self)

   self.collider:draw()
end

function Vkeybutton:update_collider()
   self.collider.x = self.x - (self.scale_x - 1)/2 * self.width
   self.collider.y = self.y - (self.scale_y - 1)/2 * self.height
   self.collider.width = self.width * self.scale_x
   self.collider.height = self.height * self.scale_y
end

function Vkeybutton:set_state(new_state)
   if self.state == new_state then return end

   local trans = self.states[self.state].transitions[new_state]
   if trans then trans(self) end
   self.state = new_state
end

function Vkeybutton:update(dt)
   -- Update collider
   self:update_collider()

   -- Update tweens
   if self.tweens.scale then
      self.tweens.scale:update(dt)
   end

   -- State machine
   local s = self.states[self.state]
   if s and s.update then
      s.update(dt)
   end
end

return Vkeybutton
