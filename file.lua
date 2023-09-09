--!strict
--[[ Small table kit made by Reflinders (Github) ]]
-- Version 1.1
--/ ...
local tablepack = {
	Cache = {
		remove = 't:&r'
	},
	CF = {}
}
-- [[ Types ]]
type mystery = any
type mysteryTable = {[mystery]: mystery}
type tab<v> = {[any & v]: any?}
export type array = tab<number>
export type dictionary = tab<string>
export type metatable = typeof(setmetatable({}, {}))
-- [[ Conversions ]]
--[[
	@ `linger` : practically a queue for values to be added 
]]
function tablepack.linger(t: mysteryTable)
	local compiler = {}
	return function(v: any?)
		if v then
			table.insert(compiler, v)
		else
			for _,v in ipairs(compiler) do
				table.insert(t, v)
			end
		end
	end
end
--[[
	@ `toArray` : converts a dictionary into an array
	second argument (can be) used to determine the index
]]
function tablepack.toArray(dict: dictionary, apiece: (any, number) -> (number?, any)) : array
	local t = {}; local linger = tablepack.linger(t)
	--[[ . . . ]]
	for i, v in next, dict do
		local xi, xv; if apiece then
			xi, xv = apiece(v, i)
		end
		if xi then
			t[xi] = xv or v
		else
			-- if an index is not given
			-- it will be added at the end of computation
			linger(xv or v)
		end
	end
	linger()
	return t
end
--[[
	@ `toDict` : converts an array into a dictionary
	second argument (should be) used to determine the index (and the new value?)
]]
function tablepack.toDict(array: array, apiece: (any, any) -> (any, any?)) : dictionary
	local t = {}; for i, v in next, array do
		local k, xv = apiece(v, i)
		if k then
			t[k] = xv or v
		end
	end
	return t
end
--[[
	@ `isDict` : returns whether a table is a dictionary
]]
function tablepack.isDict(t: mysteryTable) : boolean
	for k in next, t do
		if typeof(k) ~= `number` then
			return true
		end
	end
	return false
end
--[[
	@ `decompile` : returns the raw table of a modified table 
	along with the metatable
]]
function tablepack.decompile(metatable: metatable) : (tab<any>, tab<any>)
	local r = {}; for k, v in next, metatable do
		r[k] = v
	end
	return r, getmetatable(metatable)
end
--[[
	@ `combine__ind` : returns an __index method with multiple tables (or functions) as a backbone
]]
function tablepack.combine__ind(...)
	local ts = {...}; return function(t, k)
		local gotten; for _,v in next, ts do
			if typeof(v) == 'table' then
				-- table
				gotten = rawget(v, k); if gotten then
					return gotten
				end
			else
				-- function
				gotten = v(); if gotten then
					return gotten
				end
			end
		end 
		return
	end
end
-- [[ . . . ]]
--[[
	@ `twofold` : returns whether or not both given values are tables
]]
function tablepack.twofold(x, y) : boolean
	return (typeof(x) == typeof(y))
		and (typeof(x) == 'table')
end
--[[
	@ `isTable` : returns whether given value is table or not
]]
function tablepack.isTable(v: any) : boolean
	return (typeof(v) == 'table')
end
--[[
	@ `nested` : returns whether given table has a nested table
]]
function tablepack.nested(t: mysteryTable) : boolean
	for _, v in next, t do
		if tablepack.isTable(v) then
			return true
		end
	end
	return false
end
--[[
	@ `len` : returns # of items within given table
	the normal __len method of a table (#) will only return items indexed by a number
]]
function tablepack.len(t: mysteryTable) : number
	local len = 0; for i, v in next, t do
		len += 1
	end
	return len
end
--[[
	@ `copy` : returns a full copy of a table
	will copy all variables & tables
]]
function tablepack.copy<T>(t: T & mysteryTable) : T
	local c = {}; for i, v in next, t do
		if tablepack.isTable(v) then
			if v ~= t then
				c[i] = tablepack.copy(v)
			end
		else
			c[i] = v
		end
	end
	return c :: T & mysteryTable
end
--[[
	@ `seek` : finds the value in the table
]]
function tablepack.seek<i, v>(t: { [i]: v }, find: any) : i?
	for i, v in next, t do
		if v == find then
			return i
		end
	end
	return
end
--[[
	@ `merge` : returns new table that is a merging of the first table and all other given tables
	will not overwrite already existing values
]]
function tablepack.merge(t: mysteryTable, ...)
	local n = tablepack.copy(t); for _, xt in next, {...} do
		for i, v in next, xt do
			if not n[i] then
				n[i] = v
			end
		end
	end
	return n
end
--[[
	@ `mergemeta` : same thing as merge, but will modify the clone to have metamethods
]]
function tablepack.mergemeta(t: mysteryTable, meta: mysteryTable, ...)
	local n = tablepack.merge(t, ...)
	setmetatable(n, meta); return n
end
--[[
	@ `mergeind` : similar to mergemeta, except will set the __index to the new table
	also, it will not be binded to a metatable
]]
function tablepack.mergeind(...)
	local n = tablepack.merge(...)
	n.__index = n
	return n
end
--[[
	@ `equals` : will return whether the two values given are equal
	made specifically for tables, but will operate under any other values
	i believe the `==` method is not completely accurate on tables
	which is why this function exists
]]
function tablepack.equals(x, y)
	local synonymous = typeof(x) == typeof(y)
	if synonymous then
		if tablepack.isTable(x) then
			local diff = tablepack.len(tablepack.differ(x, y))
			if diff < 1 then
				return true
			end
		else
			return x == y
		end
	end
	return false
end
--[[
	@ `differ` : returns the differences between the new and old table
	this will use the new table as a base
	so values will not be compared from the old tables unless used to 
	determine whether a value was removed
]]
function tablepack.differ(new, old: {[any]: any})
	-- Get difference between t1 and t2
	local diff = {}
	for i, v in next, new do
		if old[i] == nil then
			-- @ If value is not existing in old-t, add the whole value to diff-t
			diff[i] = v
		else
			local not_eq = not tablepack.equals(v, old[i])
			if not_eq then
				-- @ If the data is not equal, index it in diff-t
				local twofold = tablepack.twofold(v, old[i])
				if twofold then
					-- @ If both are tables, find the differences between them
					diff[i] = tablepack.differ(v, old[i])
				else
					-- @ If not, then just add the whole value
					diff[i] = v
				end
			end
		end
	end
	for i, v in next, old do
		if new[i] == nil then
			-- @ If value does not exist in the new, add it as a removal
			diff[i] = tablepack.Cache.remove
		end
	end
	return diff
end
--[[
	@ `applyDiffer` : applies the differences (returned by `differ`) to (a clone of) the old table
]]
function tablepack.applyDiffer(old: {[any]: any}, diff) : mysteryTable
	local new = tablepack.copy(old)
	for i, v in next, diff do
		if v ~= tablepack.Cache.remove then
			-- @
			local twofold = tablepack.twofold(old[i], v)
			if twofold then
				-- @ If both values are tables, apply differences
				new[i] = tablepack.applyDiffer(old[i], v)
			else
				-- @ If one value is an arbitrary type compared to one another (or they just aren't tables),
				-- set it whole
				new[i] = v
			end
		else
			-- @ Remove the item
			new[i] = nil
		end
	end
	return new
end
-- [[ CF Utils ]]
function tablepack.CF.toCFrame<deg>(x, y, z, rx, ry, rz)
	return CFrame.new(x or 0, y or 0, z or 0) * CFrame.Angles(rx or 0, ry or 0, rz or 0)
end
function tablepack.CF.getAngles(rot: CFrame, rad: boolean?) : (number, number, number)
	local deg, x, y, z = math.deg, rot:ToEulerAnglesXYZ()
	if rad then
		return x, y, z
	else
		return deg(x), deg(y), deg(z)
	end
end
function tablepack.CF.rotAt(base: Vector3, rot: Vector3) : CFrame
	local x, y, z = tablepack.CF.getAngles(CFrame.lookAt(base, rot))
	return CFrame.Angles(x, y, z)
end
function tablepack.CF.getComponents()
	return CFrame, Vector3, CFrame.new, Vector3.new, CFrame.Angles,
	math.rad, math.sin, math.asin
end
--
return table.freeze(tablepack.merge(tablepack, table))
:: typeof(tablepack) & typeof(table)
