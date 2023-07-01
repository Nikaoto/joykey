function reduce_arr(arr, init, fn)
   local acc = init
   for i, v in ipairs(arr) do
      acc = fn(acc, v, i, arr)
   end
   return acc
end

function map_str(str, fn)
   local ret = {}
   for i=1, #str do
      local c = str:sub(i, i)
      table.insert(ret, fn(c, i, str))
   end
   return ret
end

function map_arr(arr, fn)
   local ret = {}
   for i=1, #arr do
      table.insert(ret, fn(arr[i], i, arr) or arr[i])
   end
   return ret
end

function max_in_arr(arr, fn)
   if fn == nil then
      local max = arr[1]
      for i=2, #arr do
         if arr[i] > max then max = arr[i] end
      end
      return max
   else
      local max = fn(arr[1])
      for i=2, #arr do
         local curr = fn(arr[i])
         if curr > max then max = curr end
      end
      return max
   end
end
