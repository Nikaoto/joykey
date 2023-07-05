-- Extension functions saved in the 'love' namespace

-- The border is on the inside. Like doing 'box-sizing: border-box' in css
function love.graphics.bordered_rectangle(x, y, w, h, t, c, bc, r)
   -- Draw the border
   love.graphics.setColor(bc)
   for i=0, t, 1 do
      love.graphics.rectangle("line", x+i, y+i, w-i*2, h-i*2, r, r)
   end

   -- Draw the inside rectangle
   local t2 = t * 2
   love.graphics.setColor(c)
   love.graphics.rectangle(
      "fill",
      x + t,  y + t,
      w - t2, h - t2,
      r,      r
   )
end
