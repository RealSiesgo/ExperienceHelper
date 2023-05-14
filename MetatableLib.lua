--> For any questions or bugs please contact the Creator (@SyntaxMenace, SyntaxMenace#8832)

local debugInsts	= {}
local MetatableLib	= {}

_=[[		MetatableLib		]]

--[[
another useless metatable library

provides functions such as
lockMT(Table, Key) --> Lock a table's metatable with a key. (can be unlocked later)
unlockMT(Table, Key) --> Unlock a previously locked table's metatable with the key.
isMTlocked(Table) --> Quick and accurate way of checking if table has a metatable (__metatable = {} exists so getmetatable is not something you'd quite trust)

Locking metatables are cool!

If you are using this code or a snippet of this code you are required to also provide the copyright notice.

Check the MIT license (MetatableLIB uses this) here!
https://github.com/RealSiesgo/ExperienceHelper/blob/main/LICENSE

Soon Update Ideas:
	Special Metatables that support properties (for a sandbox environment?) just like roblox's!
]]

function selectArg(index, ... : any)
	local Tbl = {...}
	
	return Tbl[index]
end

function MetatableLib:isMTlocked(Table : {}) : boolean
	--> Check if a metatable is locked.
	
	return not selectArg(1, pcall(table.clone,Table)), select(2, pcall(getmetatable,Table))
end

local function QuikHash(Text)
	local Output = "";

	for _, Byte in next, {Text:byte(1, -1)} do
		local Val = bit32.bxor(Byte, bit32.bxor(Text:len()), Text:len() / 2);
		Output ..= ("%x"):format(Val)
	end

	if #Output > 64 then
		Output = Output:sub(2, 65);
	else
		for _, Byte in next, {Text:rep(2):byte(1, -1)} do
			Byte = Byte - 1 * 2 ^ 2 / 6;

			Output ..= ("%x"):format(Byte);

			if #Output >= 64 then Output = Output:sub(1, 64) break end
		end
	end

	return Output
end

function MetatableLib:lockMT(Table : {}, key : string) : ({}, error)
	--> Lock a table's metatable which can be unlocked later.
	local hashed_key = QuikHash(tostring(key))
	
	assert(MetatableLib:isMTlocked(Table) == false,"The metatable is already locked.")
	
	local old_MT = getmetatable(Table) or {}
	
	local new_MT = {
		__metatable = function(gethash,value)
			if gethash then
				return hashed_key
			end
			
			if value == hashed_key then
				old_MT.__metatable = nil; --> disable mt
				
				local newtbl = {}
				
				for index,value in next, Table do
					newtbl[index] = value
				end
				
				setmetatable(newtbl,old_MT)
				
				return newtbl
			else
				error("[MetatableLib]: Invalid key.", 0)
				
				return false
			end
		end
	}
	
	for i,v in next, old_MT do
		new_MT[i] = v
	end
	
	setmetatable(Table,new_MT)
	
	return Table
end

function MetatableLib:unlockMT(Table : {}, key : string) : ({} , error)
	--> get the table's metatable unlocked version with the key.
	assert(MetatableLib:isMTlocked(Table),"This metatable is not locked.")
	
	assert(type(getmetatable(Table)) == "function","This metatable was not locked with MetatableLib.")
	
	local hashed_key = getmetatable(Table)(true)
	
	if hashed_key == QuikHash(key) then
		return getmetatable(Table)(nil,QuikHash(key))
	end
	
	return error("[MetatableLib]: Given key could not unlock the metatable.",0)
end

function MetatableLib:GetDebugId(instance : Instance) : string --> returns a string which can be used to check if instances are the same.
	-- Must be called from the same module.
	-- If the method is called from different metatablelib modules then the output will be different.
	
	if debugInsts[instance] then
		return debugInsts[instance]
	else
		debugInsts[instance] = QuikHash(instance.Name..math.random(9e8),5)
	end
end

table.freeze(MetatableLib)

return MetatableLib
