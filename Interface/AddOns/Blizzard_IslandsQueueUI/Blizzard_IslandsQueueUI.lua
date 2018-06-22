local ISLANDS_QUEUE_WIDGET_SET_ID = 127; 
local ISLANDS_QUEUE_LEFT_CARD_ROTATION = math.rad(4.91);
local ISLANDS_QUEUE_CENTER_CARD_ROTATION = math.rad(-3.16);
local ISLANDS_QUEUE_RIGHT_CARD_ROTATION = math.rad(-1.15); 

IslandsQueueWeeklyQuestMixin = { }; 

local ButtonTooltips = 
{
	PLAYER_DIFFICULTY1,
	PLAYER_DIFFICULTY2,
	PLAYER_DIFFICULTY6,
	PVP_FLAG,	
};

local ButtonPressedSounds = 
{
	SOUNDKIT.UI_80_ISLANDS_TABLE_SELECT_DIFFICULTY,
	SOUNDKIT.UI_80_ISLANDS_TABLE_SELECT_DIFFICULTY,
	SOUNDKIT.UI_80_ISLANDS_TABLE_SELECT_DIFFICULTY,
	SOUNDKIT.UI_80_ISLANDS_TABLE_FIND_GROUP_PVP,
};

function IslandsQueueWeeklyQuestMixin:OnEvent(event, ...)
	if (event == "QUEST_LOG_UPDATE") then
		self:Refresh();
	end
end

function IslandsQueueWeeklyQuestMixin:OnShow()
	self:RegisterEvent("QUEST_LOG_UPDATE"); 
	self.questID = C_IslandsQueue.GetIslandsWeeklyQuestID();
	self.QuestReward.questID = self.questID;
	self:Refresh(); 
end

function IslandsQueueWeeklyQuestMixin:OnHide()
	self:UnregisterEvent("QUEST_LOG_UPDATE"); 
	self.OverlayFrame.Spark:Hide(); 
end

function IslandsQueueWeeklyQuestMixin:UpdateRewardInformation()
	local numQuestCurrencies = GetNumQuestLogRewardCurrencies(self.questID);
	for i = 1, numQuestCurrencies do
		local name, texture, quantity, currencyID = GetQuestLogRewardCurrencyInfo(i, self.questID);
		local quality = select(8, GetCurrencyInfo(currencyID));
		name, texture, quantity, quality = CurrencyContainerUtil.GetCurrencyContainerInfo(currencyID, quantity, name, texture, quality);
		self.QuestReward.Icon:SetTexture(texture);
	end
end

function IslandsQueueWeeklyQuestMixin:UpdateQuestProgressBar()
	local objectiveText, objectiveType, finished, numFulfilled, numRequired = GetQuestObjectiveInfo(self.questID, 1, false);
	
	self.StatusBar:SetMinMaxValues(0, numRequired); 
	self.StatusBar:SetValue(numFulfilled); 
	self.OverlayFrame.Text:SetText(ISLANDS_QUEUE_WEEKLY_QUEST_PROGRESS:format(numFulfilled, numRequired));
	
	self.objectiveText = objectiveText;
	if (numFulfilled > 0) then 
		local sparkSet = math.max((numFulfilled  / numRequired) * (self.StatusBar:GetWidth()), 0);
		self.OverlayFrame.Spark:ClearAllPoints();
		self.OverlayFrame.Spark:SetPoint("CENTER", self.StatusBar, "LEFT", sparkSet, 2);
		self.OverlayFrame.Spark:Show(); 
	else
		self.OverlayFrame.Spark:Hide();
	end
	
	self.QuestReward.CompletedCheck:SetShown(numFulfilled >= numRequired);
	self.QuestReward.Completed = self.QuestReward.CompletedCheck:IsShown();
end

function IslandsQueueWeeklyQuestMixin:Refresh()
	if (HaveQuestData(self.questID) and HaveQuestRewardData(self.questID)) then 
		self:UpdateRewardInformation(); 
		self:UpdateQuestProgressBar(); 
	end
end

IslandsQueueFrameMixin = { }; 

local function SetWidgetFrameAnchors(frame, anchorFrame)
	frame:SetPoint("CENTER", anchorFrame.Background, "CENTER", 0,0); 
	frame.Text:SetPoint("CENTER", anchorFrame.TitleScroll, "CENTER", 0, 0);
	frame:SetFrameLevel(anchorFrame:GetFrameLevel() +10);
end

local function WidgetsLayout(widgetContainer, sortedWidgets)
	for index, widgetFrame in ipairs(sortedWidgets) do	
		if ( index == 1 ) then
			widgetFrame.Background:SetRotation(ISLANDS_QUEUE_LEFT_CARD_ROTATION);
			widgetFrame.Portrait:SetRotation(ISLANDS_QUEUE_LEFT_CARD_ROTATION);
			SetWidgetFrameAnchors(widgetFrame, widgetContainer.LeftCard)
		elseif ( index == 2 ) then 
			widgetFrame.Background:SetRotation(ISLANDS_QUEUE_CENTER_CARD_ROTATION); 
			widgetFrame.Portrait:SetRotation(ISLANDS_QUEUE_CENTER_CARD_ROTATION);
			SetWidgetFrameAnchors(widgetFrame, widgetContainer.CenterCard)
		elseif ( index == 3 ) then 
			widgetFrame.Background:SetRotation(ISLANDS_QUEUE_RIGHT_CARD_ROTATION); 
			widgetFrame.Portrait:SetRotation(ISLANDS_QUEUE_RIGHT_CARD_ROTATION);
			SetWidgetFrameAnchors(widgetFrame, widgetContainer.RightCard)
		end
	end
end

function IslandsQueueFrameMixin:OnLoad()
	self.portrait:Hide(); 
	SetPortraitToTexture(self.ArtOverlayFrame.portrait, "Interface\\Icons\\icon_treasuremap");
	UIWidgetManager:RegisterWidgetSetContainer(ISLANDS_QUEUE_WIDGET_SET_ID, self.IslandCardsFrame, WidgetsLayout);
	self:RegisterEvent("ISLANDS_QUEUE_CLOSE"); 
end

function IslandsQueueFrameMixin:OnEvent(event, ...) 
	if (event == "ISLANDS_QUEUE_CLOSE") then
		HideUIPanel(self);
	end
end

function IslandsQueueFrameMixin:OnShow()
	PlaySound(SOUNDKIT.UI_80_ISLANDS_TABLE_OPEN);
	self.DifficultySelectorFrame:SetInitialDifficulty(); 
	self.DifficultySelectorFrame:UpdateQueueText();
	
	if (not GetCVarBitfield("closedInfoFrames", LE_FRAME_TUTORIAL_ISLANDS_QUEUE_INFO_FRAME)) then
		self.TutorialFrame:Show();
	end
	
	if(UnitLevel("player") >= GetMaxLevelForExpansionLevel(LE_EXPANSION_BATTLE_FOR_AZEROTH)) then	
		self.WeeklyQuest:Show(); 
	else 
		self.WeeklyQuest:Hide();
	end
end

function IslandsQueueFrameMixin:OnHide()
	PlaySound(SOUNDKIT.UI_80_ISLANDS_TABLE_CLOSE);
	C_IslandsQueue.CloseIslandsQueueScreen();
end

IslandsQueueFrameDifficultyMixin = { }; 

function IslandsQueueFrameDifficultyMixin:OnQueueClick()
	C_IslandsQueue.QueueForIsland(self:GetActiveDifficulty());
	SetCVarBitfield("closedInfoFrames", LE_FRAME_TUTORIAL_ISLANDS_QUEUE_BUTTON, true);
	self.QueueButton.FlashAnim:Stop(); 
	self.QueueButton.Flash:Hide();
end

function IslandsQueueFrameDifficultyMixin:QueueButtonSetState(isEnabled)
	if (isEnabled) then 
		self.QueueButton:Enable(); 
		self.QueueButton.TooltipText = nil
	else 
		self.QueueButton:Disable(); 
		self.QueueButton.TooltipText = ISLANDS_QUEUE_CANNOT_QUEUE_ERROR:format(C_IslandsQueue.GetIslandsMaxGroupSize()); 
	end
end

function IslandsQueueFrameDifficultyMixin:UpdateQueueText()
	if (C_IslandsQueue.GetIslandsMaxGroupSize() == GetNumGroupMembers()) then 
		self.QueueButton:SetText(ISLANDS_QUEUE_SET_SAIL); 
	else 
		self.QueueButton:SetText(ISLANDS_QUEUE_FIND_CREW);
	end
end

function IslandsQueueFrameDifficultyMixin:OnShow()
	self:UpdateQueueText(); 
	if (not GetCVarBitfield("closedInfoFrames", LE_FRAME_TUTORIAL_ISLANDS_QUEUE_BUTTON)) then
		self.QueueButton.Flash:Show();
		self.QueueButton.FlashAnim:Play();
	end
end

function IslandsQueueFrameDifficultyMixin:OnLoad()
	self.difficultyPool = CreateFramePool("BUTTON", self, "IslandsQueueFrameDifficultyButtonTemplate");
	self:RegisterEvent("GROUP_ROSTER_UPDATE");
end

function IslandsQueueFrameDifficultyMixin:OnEvent(event, ...)
	if (event == "GROUP_ROSTER_UPDATE") then 
		self:RefreshDifficultyButtons(); 
		self:UpdateQueueText();
	end
end

function IslandsQueueFrameDifficultyMixin:SetInitialDifficulty()
	self:RefreshDifficultyButtons(); 
	if (self.firstDifficulty) then
		self:SetActiveDifficulty(self.firstDifficulty); 
	end
end

function IslandsQueueFrameDifficultyMixin:RefreshDifficultyButtons()
	local islandDifficultyIds = C_IslandsQueue.GetIslandDifficultyIds();
	self.difficultyPool:ReleaseAll(); 
	
	for buttonIndex, islandDifficultyId in ipairs(islandDifficultyIds) do
		local button = self.difficultyPool:Acquire();		
		if (buttonIndex == 1) then 
			self.firstDifficulty = button; 
			button:SetPoint("CENTER", self.Background, "CENTER", -63, 15); 
		else
			button:SetPoint("RIGHT", self.previousDifficulty, "RIGHT", 42, 0);
		end
		button.NormalTexture:SetAtlas("islands-queue-difficultyselector-"..buttonIndex);
		self.previousDifficulty = button; 
		button.difficulty = islandDifficultyId;
		button.tooltipText = ButtonTooltips[buttonIndex]; 
		local isAvailable, _, _, totalGroupSizeRequired = IsLFGDungeonJoinable(button.difficulty);
		
		if (not isAvailable) then 
			button.notAvailableText = LFGConstructDeclinedMessage(button.difficulty); 
			button.NormalTexture:SetDesaturated(true);
			button:SetAlpha(.5); 
			button:SetEnabled(false); 
			button.CanQueue = false; 
		elseif (totalGroupSizeRequired) then
			if (totalGroupSizeRequired ~= GetNumGroupMembers()) then
				button.notAvailableText = ISLANDS_QUEUE_PARTY_REQUIREMENTS:format(totalGroupSizeRequired);  
				button.CanQueue = false; 
			else 
				button.notAvailableText = nil;
				button.CanQueue = true;
			end
			button:SetEnabled(true); 
		else 
			button.notAvailableText = nil;
			button.NormalTexture:SetDesaturated(false);
			button:SetEnabled(true);
			button.CanQueue = true;
		end
		button.soundkitID = ButtonPressedSounds[buttonIndex];
		button:Show(); 
	end
end

function IslandsQueueFrameDifficultyMixin:SetActiveDifficulty(difficultyButton)
	self.activeDifficulty = difficultyButton.difficulty;
	
	for button in self.difficultyPool:EnumerateActive() do
		if (button.difficulty == self.activeDifficulty) then 
			button.SelectedTexture:SetShown(true);
			self:QueueButtonSetState(button.CanQueue); 
		else
			button.SelectedTexture:SetShown(false);
		end
	end
end

function IslandsQueueFrameDifficultyMixin:GetActiveDifficulty()
	return self.activeDifficulty; 
end