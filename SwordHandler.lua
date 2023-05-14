-- SwordHandler module uses LuaU.

local _VERSION = "V1.0 [PRE-RELEASE]"

--[[
  A customizable up-to-date SwordHandler module for sword fighting games.

  This module is currently being used in these games:
  	https://www.roblox.com/games/8832438757/pvp-sword-fighting
  
  If you find any errors / issues / bugs then please create an issue at https://github.com/RealSiesgo/ExperienceHelper/ with the file name.

  The script that uses this module for handling a sword might look something like:
    local Tool = require(game:GetService("ServerStorage").ToolHandler).new(script.Parent :: Tool);
    local Handle = Tool:WaitForChild("Handle");

    Tool.Activated:Connect(function()
  	  Tool:Activate();
    end)
  
    Handle.Touched:Connect(function(Part: BasePart)
    	return Tool:Hit(Part);
    end)
    
    
  !!READ BEFORE USE!!
  	This module requires you to call module:INIT(OnKillfunction <optional>) right before any player joins.
	Make sure you have a script that does module:INIT() at serverscriptservice or anywhere else before using this module.
]]

local Errors = {
	[0x1A] = "OnKill is a callback member of SwordHandler; you can only set the callback value, get is not available";
	[0x1B] = "Attempt to set OnKill as type %s, the allowed value for this key is \"function\"";
}

local module = {
	Settings = {
		HitExpire = 5;

		Default_Damages = {
			BaseDamage = 7.5;
			SlashDamage = 20;
			LungeDamage = 40;
		}
	}	
};
local Players: Players = game:GetService("Players");
local SwordFunctionality: {f:()->any} = {}; 
local RunService: RunService = game:GetService("RunService")
local HitDictionary: {[string]: string} = {};
local OnKillFunction: (Player, KilledPlayer) -> nil = function()end;

--// Internal
local SetupComplete;

export type NewSword =  {
	Damages: {
		BaseDamage: number;
		SlashDamage: number;
		LungeDamage: number;
	},
	Animations: {
		R15Slash: number;
		R15Lunge: number;
	},
	Grips: {
		Up: CFrame;
		Out: CFrame;
	},

	IsEquipped: (self) -> boolean;
	Activate: (self) -> "Activates the sword";
	Hit: (self, Part: BasePart) -> "Should be called with the part thats been hit when sword hits a part";
	OnKill: (Function: (Murderer, Victim, Sword) -> nil) -> "Set a function to this. Called when a player kills another player with a sword."; 
}

function module.new(Sword: Tool, DmgData: {BaseDamage: number, SlashDamage: number, LungeDamage: number}?): Tool & NewSword
	local self = {
		Tool = Sword;
		HeldBy = Players:GetPlayerFromCharacter(Sword.Parent) or false;

		Damages = {
			BaseDamage = DmgData and DmgData.BaseDamage and DmgData.BaseDamage or module.Settings.Default_Damages.BaseDamage;
			SlashDamage = DmgData and DmgData.SlashDamage and DmgData.SlashDamage or module.Settings.Default_Damages.SlashDamage;
			LungeDamage = DmgData and DmgData.LungeDamage and DmgData.LungeDamage or module.Settings.Default_Damages.LungeDamage;
		},
		Grips = {
			Up = CFrame.new(0, 0, -1.70000005, 0, 0, 1, 1, 0, 0, 0, 1, 0);
			Out = CFrame.new(0, 0, -1.70000005, 0, 1, 0, 1, -0, 0, 0, 0, -1);
		},
		Sounds = {
			Slash = Sword.Handle:WaitForChild("SwordSlash"),
			Lunge = Sword.Handle:WaitForChild("SwordLunge"),
			Unsheath = Sword.Handle:WaitForChild("Unsheath")
		},
		_InternalData = {
			LastActivate = 0;
			LastAttack = 0;
			HitDamage = 0;
		}
	}

	self._InternalData.HitDamage = self.Damages.BaseDamage;

	Sword.Unequipped:Connect(function()
		Sword.Grip = self.Grips.Up;
	end)

	Sword.Equipped:Connect(function()
		local Handle: BasePart = Sword:FindFirstChild("Handle");
		local Humanoid: Humanoid = Sword.Parent and Sword.Parent:FindFirstChildWhichIsA("Humanoid");
		local RightArm: BasePart = Sword.Parent and Sword.Parent:FindFirstChild("Right Arm");
		local LocalPlayer: Player = Players:GetPlayerFromCharacter(Sword.Parent);

		if not RightArm or not Handle or not LocalPlayer then
			return Handle:Destroy();
		elseif not Humanoid or Humanoid.Health <= 0 then
			--warn("Cannot play sound with dead Humanoid.")
			return;
		end

		self.HeldBy = LocalPlayer;
		self.Sounds.Unsheath:Play();
	end)

	setmetatable(self, {
		__index = function(self, index)
			--warn("__index debug:", "indexing "..tostring(index), debug.traceback());

			if SwordFunctionality[index] then
				return function(s, ...)
					return SwordFunctionality[index](self, ...);
				end
			elseif type(Sword[index]) == "function" then
				return function(self, ...)
					return Sword[index](Sword, ...);
				end
			end

			return Sword[index];
		end
	})

	return self;
end

function module:INIT(OnKill)
	if OnKill then OnKillFunction = OnKill end;
	if not SetupComplete then SetupComplete = true else return OnKill end;

	Players.PlayerAdded:Connect(function(Player)
		--print("PlayerAdded", Player.Name)
		Player.CharacterAdded:Connect(function(Character)
			--print("CharacterAdded", Character.Name)
			local Humanoid: Humanoid = Character:WaitForChild("Humanoid");

			Humanoid.Died:Connect(function()
				--print("HumanoidDied", Player.Name)
				local HitData = HitDictionary[Player.Name];

				if HitData and (HitData.ExpiresAt <= tick() or not HitData.Hit:IsDescendantOf(game))  then
					HitData.Hit = nil;
				elseif not HitData then
					HitData = {};
				end;

				task.spawn(OnKillFunction, HitData.Hit, Player, HitData.Sword);

				HitDictionary[Player.Name] = nil;
			end)
		end)
	end)
end

function SwordFunctionality:IsEquipped()
	return not not Players:FindFirstChild(self.Parent:IsA("Model") and self.Parent.Name);
end

function SwordFunctionality:Activate()
	if not self.Tool.Enabled or not self:IsEquipped() then return end; --> debounce

	self.Tool.Enabled = false;
	--> set to disabled for activate debounce so we dont get spammy lunges and slashes.

	if tick() - self._InternalData.LastActivate <= 0.2 then
		--> Lunge
		self._InternalData.HitDamage = self.Damages.LungeDamage

		self.Sounds.Lunge:Play();

		local Anim = Instance.new("StringValue");
		Anim.Name = "toolanim";
		Anim.Value = "Lunge";
		Anim.Parent = self.Tool;


		task.wait(0.2);
		self.Tool.Grip = self.Grips.Out;
		task.wait(0.6);
		self.Tool.Grip = self.Grips.Up;
	else
		--> Slash
		self._InternalData.HitDamage = self.Damages.SlashDamage

		self.Sounds.Slash:Play();

		local Anim = Instance.new("StringValue");
		Anim.Name = "toolanim";
		Anim.Value = "Slash";
		Anim.Parent = self.Tool;

		wait()
	end

	task.wait(); --> delay

	self._InternalData.HitDamage = self.Damages.BaseDamage;

	self._InternalData.LastActivate = tick();
	self.Tool.Enabled = true;
end

local function getDist(Part1, Part2)
	return (Part1.Position - Part2.Position).Magnitude;
end

function SwordFunctionality:Hit(Part: BasePart)
	local Humanoid: Humanoid = Part.Parent:FindFirstChildWhichIsA("Humanoid");
	local HasFF: Instance | nil = Part.Parent:FindFirstChildWhichIsA("ForceField");
	local IHaveFF: Instance | nil = self.HeldBy and self.HeldBy.Character and self.HeldBy.Character:FindFirstChildWhichIsA("ForceField");
	local LocalHumanoid = self.HeldBy and self.HeldBy.Character and self.HeldBy.Character:FindFirstChildWhichIsA("Humanoid")
	local HitPlayer: Player = Players:FindFirstChild(Part.Parent.Name) or {Name="Dummy"};

	if not LocalHumanoid or LocalHumanoid.Health == 0 or IHaveFF or self.HeldBy == HitPlayer or not Humanoid or not HitPlayer or Humanoid.Health <= 0 or HasFF or getDist(Part, self.Handle) > 9 or (tick()-self._InternalData.LastAttack) < .005 then
		return --> Do not register the hit if the conditions met.
	end;

	if Humanoid.Health < self._InternalData.HitDamage then
		HitDictionary[HitPlayer.Name] = {
			ExpiresAt = tick() + module.Settings.HitExpire;
			Sword = self.Tool;
			Hit = self.HeldBy;
		};
		
		Humanoid.Health = 0;

		wait();

		HitDictionary[HitPlayer.Name] = nil;
	else
		HitDictionary[HitPlayer.Name] = {
			ExpiresAt = math.floor(tick() + module.Settings.HitExpire);
			Hit = self.HeldBy;
		};

		Humanoid:TakeDamage(self._InternalData.HitDamage);
	end

	self._InternalData.LastAttack = tick();
end

setmetatable(module, {
	__index = function(self, index)
		if index:match("^[Oo]?nKill") then
			return error(Errors[0x1A]); --> Get unavailable
		end
	end,
	__newindex = function(self, index, value)
		if index:match("^[Oo]?nKill") then
			assert(typeof(value) == "function", Errors[0x1B]:format(typeof(value))); --> Only allowed value is "function".
			
			OnKillFunction = value;
		end
	end,
})

return module
