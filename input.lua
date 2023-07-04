local Input = {
   conf = nil,
   state = nil,
}

function Input:new(conf)
   local instance = { conf = conf }
   setmetatable(instance, self)
   self.__index = self

   instance:init()
   return instance
end

function Input:init()
   local conf = self.conf
   self.state = {}

   if conf.buttons then
      self.state.buttons = {}
      for btn_name, btn_conf in pairs(conf.buttons) do
         self.state.buttons[btn_name] = {
            is_down = false,
            was_down = false,
            just_released = false,
            just_pressed = false,
         }
      end
   end

   if conf.axii then
      self.state.axii = {}
      for axis_name, axis_conf in pairs(conf.axii) do
         self.state.axii[axis_name] = {
            value = 0,
         }
      end
   end
end

function Input:capture_all(src)
   local conf = self.conf
   local state = self.state

   if conf.buttons then
      for btn_name, btn_conf in pairs(conf.buttons) do
         local btn_state = state.buttons[btn_name]

         -- Was button down?
         -- (The state before capture inputs holds data from the previous frame)
         btn_state.was_down = btn_state.is_down

         -- Is button down?
         local capture_fn = btn_conf.capture_is_down or conf.capture_fns.is_button_down
         btn_state.is_down = capture_fn(self, btn_name, btn_conf, src)

         -- just_pressed
         if not btn_state.was_down and btn_state.is_down then
            btn_state.just_pressed = true
         else
            btn_state.just_pressed = false
         end

         -- just_released
         if btn_state.was_down and not btn_state.is_down then
            btn_state.just_released = true
         else
            btn_state.just_released = false
         end
      end
   end

   if conf.axii then
      for axis_name, axis_conf in pairs(conf.axii) do
         local axis_state = state.axii[axis_name]

         local capture_fn = axis_conf.capture_value or conf.capture_fns.get_axis
         axis_state.value = capture_fn(self, axis_name, axis_conf, src)
      end
   end
end

return Input
