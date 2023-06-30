-- Extension functions saved in the 'love' namespace

-- The border is on the inside. Like doing 'box-sizing: border-box' in css
function love.graphics.bordered_rectangle(x, y, w, h, t, c, bc, r)
   -- Draw the border
   local t2 = t * 2
   love.graphics.setColor(bc)
   love.graphics.rectangle("fill", x, y, w, h, r, r)

   -- Draw the inside rectangle
   local blend_mode = love.graphics.getBlendMode()
   love.graphics.setBlendMode("replace")
   do
      local t2 = t * 2
      love.graphics.setColor(c)
      love.graphics.rectangle(
         "fill",
         x + t,  y + t,
         w - t2, h - t2,
         r,      r
      )
   end
   love.graphics.setBlendMode(blend_mode)
end
