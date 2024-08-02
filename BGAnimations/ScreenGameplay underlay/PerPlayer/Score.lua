local player = ...
local pn = ToEnumShortString(player)

local mods = SL[pn].ActiveModifiers
local IsUltraWide = (GetScreenAspectRatio() > 21/9)
local NumPlayers = #GAMESTATE:GetHumanPlayers()
local IsEX = SL[pn].ActiveModifiers.ShowEXScore

-- -----------------------------------------------------------------------
-- first, check for conditions where we might not draw the score actor at all

if mods.HideScore then return end

if NumPlayers > 1
and mods.NPSGraphAtTop
and not IsUltraWide
then
	return
end

-- -----------------------------------------------------------------------
-- set up some preliminary variables and calculations for positioning and zooming

local styletype = ToEnumShortString(GAMESTATE:GetCurrentStyle():GetStyleType())

-- scores are not aligned symmetrically around screen.cx for aesthetic reasons
-- and this is the cause of many code-induced headaches
local pos = {
	[PLAYER_1] = { x=(_screen.cx - clamp(_screen.w, 640, 854)/4.3),  y=56 },
	[PLAYER_2] = { x=(_screen.cx + clamp(_screen.w, 640, 854)/2.75), y=56 },
}

local pss = STATSMAN:GetCurStageStats():GetPlayerStageStats(player)

local StepsOrTrail = (GAMESTATE:IsCourseMode() and GAMESTATE:GetCurrentTrail(player)) or GAMESTATE:GetCurrentSteps(player)
local total_tapnotes = StepsOrTrail:GetRadarValues(player):GetValue( "RadarCategory_TapsAndHolds" ) + StepsOrTrail:GetRadarValues(player):GetValue( "RadarCategory_Holds" ) + StepsOrTrail:GetRadarValues(player):GetValue( "RadarCategory_Rolls" )

-- determine how many digits are needed to express the number of notes in base-10
local digits = (math.floor(math.log10(total_tapnotes)) + 1)
-- subtract 4 from the digit count; we're only really interested in how many digits past 4
-- this stepcount is so we can use it to align the score actor in the StepStats pane if needed
-- aligned-with-4-digits is the default
digits = clamp(math.max(4, digits) - 4, 0, 3)

local NoteFieldIsCentered = (GetNotefieldX(player) == _screen.cx)

local ar_scale = {
	sixteen_ten  = 0.825,
	sixteen_nine = 1
}
local zoom_factor = clamp(scale(GetScreenAspectRatio(), 16/10, 16/9, ar_scale.sixteen_ten, ar_scale.sixteen_nine), 0, 1.125)

-- -----------------------------------------------------------------------

return LoadFont("Wendy/_wendy monospace numbers")..{
	Text="0",
	Name=pn.."Score",
	InitCommand=function(self)
		self:valign(1):horizalign(right)
		self:zoom(0.5)
		if IsEX then
			-- If EX Score, let's diffuse it to be the same as the FA+ top window.
			-- This will make it consistent with the EX Score Pane.
			self:diffuse(SL.JudgmentColors["FA+"][1])
		end
	end,

	BeginCommand=function(self)
		-----------------------------------------------------------------
		-- ultrawide with both players joined is really its own layout
		-- hardcode some numbers for now, return early, and call it a day
		-- until 21:9 displays become more popular
		if IsUltraWide and #GAMESTATE:GetHumanPlayers() > 1 then
			if player==PLAYER_1 then
				self:x(134)
			else
				self:x(_screen.w - 4)
			end

			self:y( 238 )
			return
		end
		-----------------------------------------------------------------

		-- assume "normal" score positioning first, but there are many reasons it will need to be moved
		self:xy( pos[player].x, pos[player].y )

		if mods.NPSGraphAtTop and styletype ~= "OnePlayerTwoSides" then
			-- if NPSGraphAtTop and Step Statistics and not double,
			-- move the score down into the stepstats pane under
			-- the judgment breakdown
			if mods.DataVisualizations=="Step Statistics" then
				local step_stats = self:GetParent():GetChild("StepStatsPane"..pn)

				-- Step Statistics might be true in the SL table from a previous game session
				-- but current conditions might be such that it won't actually appear.
				-- Ensure the StepStats ActorFrame is present before trying to traverse it.
				if step_stats then
					if player==PLAYER_1 then
						if NoteFieldIsCentered then
							self:x( pos[ OtherPlayer[player] ].x + SL_WideScale( 94, 112.5) )
						else
							self:x( pos[ OtherPlayer[player] ].x - SL_WideScale(-84, -60) )
						end

					-- PLAYER_2
					else
						if NoteFieldIsCentered then
							self:x( pos[ OtherPlayer[player] ].x - 65.5 )
						else
							self:x( pos[ OtherPlayer[player] ].x - SL_WideScale(-6, -2))
						end
					end

					self:y( 282 )
				end

			-- if NPSGraphAtTop but not Step Statistics
			else
				-- if not Center1Player, move the score right or left
				-- within the normal gameplay header to where the
				-- other player's score would be if this were versus
				if not NoteFieldIsCentered then
					self:x( pos[ OtherPlayer[player] ].x )
					self:y( pos[ OtherPlayer[player] ].y )
				end
				-- if NoteFieldIsCentered, no need to move the score
			end
		end
	end,
	JudgmentMessageCommand=function(self)
		self:queuecommand("RedrawScore")
	end,
	RedrawScoreCommand=function(self)
		if not IsEX then
			local w1=pss:GetTapNoteScores('TapNoteScore_W1')
			local w2=pss:GetTapNoteScores('TapNoteScore_W2')
			local w3=pss:GetTapNoteScores('TapNoteScore_W3')
			local hd=pss:GetHoldNoteScores('HoldNoteScore_Held')
			if PREFSMAN:GetPreference("AllowW1")~="AllowW1_Everywhere" then
				w1=w1+w2
				w2=0
			end

			self:settext((math.round( (w1 + w2 + w3/2+hd)*100000/total_tapnotes-(w2 + w3))*10))
		end
	end,
	ExCountsChangedMessageCommand=function(self, params)
		if params.Player ~= player then return end

		if IsEX then
			local w1 = pss:GetTapNoteScores('TapNoteScore_W1');
			local w2 = pss:GetTapNoteScores('TapNoteScore_W2');
			local w3 = pss:GetTapNoteScores('TapNoteScore_W3');
			local hd = pss:GetHoldNoteScores('HoldNoteScore_Held');
			if params.HoldNoteScore == 'HoldNoteScore_Held' then
				hd = hd+1;
			elseif params.TapNoteScore == 'TapNoteScore_W1' then
				w1 = w1+1;
			elseif params.TapNoteScore == 'TapNoteScore_W2' then
				w2 = w2+1;
			elseif params.TapNoteScore == 'TapNoteScore_W3' then
				w3 = w3+1;
			end;
			self:settext(w1*3 + w2*2 + w3*1 + hd*3)
		end
	end,
}