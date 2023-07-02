-- Various helpers for geometric stuff

-- Returns 'b', which is the coordinate of the line 'blen' centered inside line
-- 'a' that has a length of 'alen'
function center_1D(a, alen, blen)
   return a + (alen - blen) / 2
end
