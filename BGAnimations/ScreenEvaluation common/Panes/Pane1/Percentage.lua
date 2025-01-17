local player, controller = unpack(...)

local stats = STATSMAN:GetCurStageStats():GetPlayerStageStats(player)
local percent = 0

local StepsOrTrail = (GAMESTATE:IsCourseMode() and GAMESTATE:GetCurrentTrail(player)) or GAMESTATE:GetCurrentSteps(player)

local total_tapnotes = StepsOrTrail:GetRadarValues(player):GetValue( "RadarCategory_TapsAndHolds" ) + StepsOrTrail:GetRadarValues(player):GetValue( "RadarCategory_Holds" ) + StepsOrTrail:GetRadarValues(player):GetValue( "RadarCategory_Rolls" )
local w1=stats:GetTapNoteScores('TapNoteScore_W1');
local w2=stats:GetTapNoteScores('TapNoteScore_W2');
local w3=stats:GetTapNoteScores('TapNoteScore_W3');
local w4=stats:GetTapNoteScores('TapNoteScore_W4');
local hd=stats:GetHoldNoteScores('HoldNoteScore_Held');
percent = (math.round((w1 + w2 + w3*(0.6) + w4*(0.2) + hd) * 100000/total_tapnotes-(w2 + w3 + w4))*10);

return Def.ActorFrame{
	Name="PercentageContainer"..ToEnumShortString(player),
	OnCommand=function(self)
		self:y( _screen.cy-26 )
	end,

	-- dark background quad behind player percent score
	Def.Quad{
		InitCommand=function(self)
			self:diffuse(color("#101519")):zoomto(158.5, SL.Global.GameMode == "FA+" and 88 or 60)
			self:horizalign(controller==PLAYER_1 and left or right)
			self:x(150 * (controller == PLAYER_1 and -1 or 1))
			if SL.Global.GameMode == "FA+" then
				self:y(14)
			end
			if ThemePrefs.Get("VisualStyle") == "Technique" then
				self:diffusealpha(0.5)
			end
		end
	},

	LoadFont("Wendy/_wendy white")..{
		Name="Percent",
		Text=percent,
		InitCommand=function(self)
			self:horizalign(right):zoom(0.45)
			self:x( (controller == PLAYER_1 and 1.5 or 141))
		end
	}
}
