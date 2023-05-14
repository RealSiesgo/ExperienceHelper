--[[
		{COMPACT HASHING - ALGORITHM}

This hashing algorithm was made by SyntaxMenace (SyntaxMenace#8832).

License in github page:
https://github.com/RealSiesgo/ExperienceHelper

Warning: This script is poorly written, significantly outdated, and is not recommended for use in any public software.

]]

local Hex_Table={
	[2] = "A",
	[4] = "B",
	[6] = "C",
	[8] = "D",
	[9] = "E",
	[11]= "F",
	[13]= "T",
	[14]= "S",
	[15]= "N",
}

setmetatable(Hex_Table, {__index = function(self,i)
	if type(i) == "number" then
		return i ~= 0 and i or rawget(self, i + 8)
	else
		local num: number;
		
		for a,v in next, self do
			if v == i then
				return self[rawget(self,a-2) and a-2 or a+2];
			end
		end
		
		return nil;
	end
end})

local to_Hex = function(dec)
	assert(type(tonumber(dec)) == "number","[ToHex]: Number expected. Got "..type(dec)..".")
	
	local dec = math.floor(tonumber(dec))
	
	assert(dec > 0,"[ToHex]: Invalid Decimal Input.")
	
	if dec > 15 then
		local results = {}
		local next_num = dec
		
		while next_num > 15 do
			local result = math.floor(next_num%16)
			
			if result > 0 then
				table.insert(results, Hex_Table[result])
			end
			
			next_num = math.floor(next_num/16)
		end
		
		return table.concat(results):reverse()
	else
		return Hex_Table[dec]
	end
end

function hash(str, length)
	local ErrorText = "<CH-ALG>: Expected %s in argument #%i. Got %s.";
	
	assert(type(str) == "string" or type(str) == "number", ErrorText:format("String", 1, type(str)));
	
	str = tostring(str);
	
	if type(length) ~= "number" and length ~= nil then
		warn(ErrorText:format("Number", 2, type(length)));
	end
	
	local length = math.floor(type(length) == "number" and length or 25);
	local old_length = str:len();
	local abytes = {str:byte(1,-1)};
	local bbytes = {};
	local cbytes = 1;
	local newnum = "";
	local Traceback = debug.traceback():gsub(script:GetFullName():gsub("%-","%%-")..":%d+",""):gsub("\n","\32")
	
	if length < 5 then --> length min
		setfenv(function()
			warn(
				"<CH-ALG>: Hash output length must be 5 on minimum, given length was "..length..".",
				"\nCalculating hash with 5 output length...",
				"\nTraceback:",
				Traceback:sub(2, -1)
			)
		end, {warn=warn})()
		
		length = 5
	elseif length > 5000 then --> length max
		setfenv(function()
			warn(
				"<CH-ALG>: Hash output length must be 5000 on maximum, given length was "..length..".",
				"\nCalculating hash with 5000 output length...",
				"\nTraceback:",
				Traceback:sub(2, -1)
			)
		end, {warn=warn})()
		
		length = 5000;
	end
	
	for _, value in next,abytes do
		table.insert(bbytes, bit32.rshift(value ^ 5, math.pi));
	end
	
	for ind, value in next,bbytes do
		if old_length < 100 then
			if ind % 2 == 0 then
				cbytes *= math.sqrt(value/math.pi) / (old_length ^ 2);
			else
				cbytes /= math.sqrt(value / 0.7) / 7;
			end
		else
			if ind % 2 == 0 then
				cbytes += math.sqrt(value/math.pi) ^ 1.5;
			else
				cbytes -= math.sqrt(value/math.pi) / math.pi;
			end
		end
	end
	
	local bitexor = bit32.bxor(cbytes, str:len() + length ^ math.pi * 7);
	
	local function Hashify(input)
		local input = to_Hex(input * 36.019);
		local output = "";
		local nextnum = 0.7;
		
		if #input < length then
			repeat
				input = input:reverse() .. to_Hex(bitexor * nextnum):gsub("0",""); --> quick fix gsub but works

				nextnum *= math.pi;
			until #input >= length;
		end
		
		return input:sub(1, length);
	end
	
	local last_Letter = "";
	local output = Hashify(bitexor):gsub(".",function(string) --> quick string repetition fix (being lazy)
		if last_Letter == string then
			last_Letter = Hex_Table[tonumber(string) and #Hex_Table / tonumber(string) or string];
			
			return last_Letter;
		else
			last_Letter = string;
			
			return string;
		end
	end)
	
	return output
end

return hash
