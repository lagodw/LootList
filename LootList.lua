local addonname, addontable = ...
_G.LootList = LibStub("AceAddon-3.0"):NewAddon(addontable,addonname, "AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0", "AceSerializer-3.0", "AceHook-3.0", "AceTimer-3.0");

local loadframe = CreateFrame("FRAME"); -- Need a frame to respond to events
loadframe:RegisterEvent("ADDON_LOADED"); -- Fired when saved variables are loaded
loadframe:RegisterEvent("PLAYER_LOGOUT"); -- Fired when about to log out
local AceGUI = LibStub("AceGUI-3.0")

function loadframe:OnEvent(event, arg1)
	if event == "ADDON_LOADED" and arg1 == "LootList" then
		if lootlist_history == nil then 
			lootlist_history = {} 
		end
		if list == nil then
			list = {}
			list['MC'] = {}
			list['MC'][1] = "Boss shared loot"
			list['MC'][2] = {"Wool Cloth" , "Kalaeynz: 49", "Aliancespy: 49", "Test: 47"}
			list['MC'][3] = {"Linen Cloth" , "Kalaeynz: 49", "Aliancespy: 47", "Test: 47"}
			list['MC'][4] = {"Flask of Oil", "Kalaeynz: 50", "Kalayn: 50", "Zepthane: 50", "Qase: 45"}
			list['MC'][5] = {"Light Feather", "Kalaeynz: 50", "Kalayn: 50", "Zepthane: 50", "Qase: 45"}
		end
	end
end
loadframe:SetScript("OnEvent", loadframe.OnEvent)

local lootlist_rollframe = {} --used to manage multiple loot roll windows
local counter = 1 --used to keep track of how many open loot rolls exist

local lootlist_baseframe = CreateFrame('Frame', 'LootList_Frame', UIParent, "BasicFrameTemplateWithInset")
lootlist_baseframe:RegisterEvent("START_LOOT_ROLL")
lootlist_baseframe:RegisterEvent("CHAT_MSG_RAID")
lootlist_baseframe:RegisterEvent("CHAT_MSG_RAID_LEADER")
lootlist_baseframe:SetScript("OnEvent", function(self, event, ...) 
	if event == "START_LOOT_ROLL" then 
		local texture, itemName, count, quality = GetLootRollItemInfo(...)
		lootlist_itemlookup(itemName)
	elseif event == "CHAT_MSG_RAID" or event == "CHAT_MSG_RAID_LEADER" then
		msg = ...
		if strsub (msg, 1, 1) == '|' then 
		local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType,
		itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(msg)
		lootlist_itemlookup(itemName, itemLink)
		end
	end
end)


function lootlist_itemlookup(itemName, itemLink)
	local item_match = 0
	local item_row = 0

	for instance, value in pairs(list) do
		for row=1, #value do
			if value[row][1] == itemName then 
				item_match = 1 
				item_row = row
				current_instance = instance
			end
		end
	end
	
	if item_match == 1 then
		local players = list[current_instance][item_row]
		
		lootlist_rollframe[counter] = CreateFrame('Frame', 'LootList_Frame_Roll' .. counter, UIParent, "BasicFrameTemplateWithInset")
		print(itemName)
		MakeMovable(lootlist_rollframe[counter])
		if counter == 1 then
			lootlist_rollframe[counter]:SetPoint('CENTER', UIParent, "CENTER", -200, 200)
		else 
			lootlist_rollframe[counter]:SetPoint("TOPLEFT", lootlist_rollframe[counter - 1], "BOTTOMLEFT")
		end
		lootlist_rollframe[counter].title = lootlist_rollframe[counter]:CreateFontString(nil, "TEST")
		lootlist_rollframe[counter].title:SetFontObject("GameFontHighlight")
		lootlist_rollframe[counter].title:SetPoint("CENTER", lootlist_rollframe[counter].TitleBg, "CENTER", 5, 0)
		lootlist_rollframe[counter]:HookScript("OnHide", function() 
			counter = counter - 1 
			lootlist_rollframe[counter]:UnregisterAllEvents()
		end)
		
		lootlist_rollframe[counter].title:SetText(itemName)

		if #players == 1 then
			local freeroll_indicator = 1
			list[current_instance][item_row][2] = 'FREEROLL: 0'
		end
		
		current_passers = {}
		
		if (UnitIsGroupLeader('player')) then
			create_lootframe_buttons(itemLink, item_row, current_instance, lootlist_rollframe[counter])
			handle_raidchat(itemLink, item_row, current_instance, lootlist_rollframe[counter])
		end
		
		counter = counter + 1
		if freeroll_indicator == 1 then list[item_row][2] = nil end
	end
end




function create_lootframe_buttons(itemLink, item_row, current_instance, local_frame)
	local players = list[current_instance][item_row]
	local framesize = (#players - 1)*100
	lootlist_rollframe[counter]:SetSize(framesize, 50)
	
	local frames = {}
	local accept_button = {}
	local pass_button = {}
	for i=2, #players do
		frames[i]=CreateFrame('Button', 'tmpframe', lootlist_rollframe[counter], "UIPanelButtonTemplate")
		frames[i].i=i
		frames[i]:SetSize(100, 30)
		if i == 2 then 
			frames[i]:SetPoint('TOPLEFT', lootlist_rollframe[counter], 'TOPLEFT', 0, -20)				
		else 
			frames[i]:SetPoint('TOPLEFT', frames[i-1], 'TOPRIGHT')		
		end
		frames[i]['clicked'] = 0
		frames[i]:SetText(players[i])	
		frames[i]:SetScript("OnClick", function()
			if frames[i]['clicked'] == 0 then
				accept_button[i] = CreateFrame('Button', 'accept_button', frames[i], "UIPanelButtonTemplate")
				accept_button[i]:SetSize(50, 20)
				accept_button[i]:SetPoint('BOTTOMLEFT', frames[i], 'TOPLEFT')
				accept_button[i]:SetText('Accept')
				accept_button[i]:SetScript("OnClick", function()
					lootlist_history[#lootlist_history + 1] = {}
					lootlist_history[#lootlist_history]['date'] = date()
					lootlist_history[#lootlist_history]['item'] = itemLink
					lootlist_history[#lootlist_history]['instance'] = current_instance
					lootlist_history[#lootlist_history]['player'] = strip_colon_player(players[i])
				
					pass_button[i]:Hide()
					accept_button[i]:Hide()
					lootlist_rollframe[counter - 1]:Hide()
					frames[i]['clicked'] = 0
					
				end)

				pass_button[i] = CreateFrame('Button', 'pass_button', frames[i], "UIPanelButtonTemplate")
				pass_button[i]:SetSize(50, 20)
				pass_button[i]:SetPoint('BOTTOMRIGHT', frames[i], 'TOPRIGHT')
				pass_button[i]:SetText('Pass')
				pass_button[i]:SetScript("OnClick", function()
					current_passers[#current_passers + 1] = strip_colon_player(players[i])
					local new_player = get_player_up(item_row, current_passers, current_instance)
					if new_player == 1 then
						send_raid_message(itemLink)
					end
					pass_button[i]:Hide()
					accept_button[i]:Hide()
					frames[i]['clicked'] = 0
				end)
				frames[i]['clicked'] = 1
			else
				frames[i]['clicked'] = 0
				pass_button[i]:Hide()
				accept_button[i]:Hide()
			end
		end)
	end
end


function handle_raidchat(itemLink, item_row, current_instance, local_frame)
	current_player_up_number = 2
	current_player_up = {strip_colon_player(list[current_instance][item_row][current_player_up_number])}
	
	if #list[current_instance][item_row] > current_player_up_number then 
		local next_ranking = strip_colon_rank(list[current_instance][item_row][current_player_up_number + 1]) 
		while next_ranking == strip_colon_rank(list[current_instance][item_row][current_player_up_number]) do
			current_player_up_number = current_player_up_number + 1
			current_player_up[#current_player_up + 1] = strip_colon_player(list[current_instance][item_row][current_player_up_number])
			current_ranking = strip_colon_rank(list[current_instance][item_row][current_player_up_number])
			if #list[current_instance][item_row] > current_player_up_number then
				next_ranking = strip_colon_rank(list[current_instance][item_row][current_player_up_number + 1])
			else 
				next_ranking = 0
			end
		end
	end
	
	send_raid_message(itemLink)
	
	local_frame:RegisterEvent("CHAT_MSG_RAID")
	local_frame:RegisterEvent("CHAT_MSG_RAID_LEADER")
	local_frame:SetScript("OnEvent", function(self, event, ...)
		local msg, playerName = ...
		playerName = strsub(playerName, 1, strfind(playerName, "-") - 1)
		local pass_flag = 0
		if msg:lower() == 'pass' then
			for player=1, #current_player_up do
				if playerName == current_player_up[player] then pass_flag = 1 end
			end
		end
		
		if msg:lower() == 'pass' and pass_flag == 1 then
			pass_flag = 0
			current_passers[#current_passers + 1] = playerName
			local new_player = get_player_up(item_row, current_passers, current_instance)
			if new_player == 1 then
				send_raid_message(itemLink)
			end
		end
	end)
end

function strip_colon_player(player_string)
	return(strsub(player_string, 1, strfind(player_string, ":") - 1))
end

function strip_colon_rank(player_string)
	return(strsub(player_string, strfind(player_string, ":"),  #player_string))
end

function get_player_up(item_row, current_passers_func, current_instance)
	
	local new_player = 0
	
	for i = 1, #list[current_instance][item_row] * #current_passers_func do
		if #current_player_up == 0 then
			new_player = 1
		end
		if #current_player_up == 0 and #list[current_instance][item_row] > current_player_up_number then
			current_player_up_number = current_player_up_number + 1
			current_player_up = {strip_colon_player(list[current_instance][item_row][current_player_up_number])}
		end

		if #list[current_instance][item_row] > current_player_up_number then 
			local next_ranking = strip_colon_rank(list[current_instance][item_row][current_player_up_number + 1]) 
			while next_ranking == strip_colon_rank(list[current_instance][item_row][current_player_up_number]) do
				current_player_up_number = current_player_up_number + 1
				current_player_up[#current_player_up + 1] = strip_colon_player(list[current_instance][item_row][current_player_up_number])
				current_ranking = strip_colon_rank(list[current_instance][item_row][current_player_up_number])
				if #list[current_instance][item_row] > current_player_up_number then
					next_ranking = strip_colon_rank(list[current_instance][item_row][current_player_up_number + 1])
				else 
					next_ranking = 0
				end
			end
		end
		
		for player=1, #current_player_up do
			for passer=1, #current_passers_func do
				if current_player_up[player] == current_passers_func[passer] then
					current_player_up[player] = nil
					current_passers_func[passer] = nil
				end
			end
		end
	end
	
	return(new_player)
end


function send_raid_message(itemLink)

	if #current_player_up == 0 then
		SendChatMessage(" " .. itemLink .. " FREEROLL ", "RAID")
	elseif #current_player_up == 1 then
		SendChatMessage(" " .. itemLink .. " goes to " .. current_player_up[1], "RAID")
		SendChatMessage("You are up for " .. itemLink .. ". Roll need or type pass in chat.", "WHISPER", nil, current_player_up[1])
	else 
		local output_string = ''
		for roller=1, #current_player_up do
			if current_player_up[roller] ~= nil then 
				if #output_string > 0 then output_string = output_string .. ", " .. current_player_up[roller] 
				else output_string = current_player_up[roller]  end
			end
			if current_player_up[roller] then 
				SendChatMessage("You are up for " .. itemLink .. ". Roll need or type pass in chat.", "WHISPER", nil, current_player_up[roller])
			end
		end
		output_string = output_string .. " rolling"
		SendChatMessage(" " .. itemLink .. " " .. output_string, "RAID")
	end
end


function MakeMovable(frame)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	
	--option to resize but would need to get it to also scale buttons
	--[[
	frame:SetResizable(true)
	frame:SetMinResize(100, 30)
	local resizebutton = CreateFrame("Button", "ResizeButton", frame)
	resizebutton:SetPoint("BOTTOMRIGHT", -6, 7)
	resizebutton:SetSize(16, 16)
	
	resizebutton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
	resizebutton:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
	resizebutton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
	
	resizebutton:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" then
			frame:StartSizing("BOTTOMRIGHT")
			self:GetHighlightTexture():Hide() -- more noticeable
		end
	end)
	resizebutton:SetScript("OnMouseUp", function(self, button)
		frame:StopMovingOrSizing()
		self:GetHighlightTexture():Show()
	end)
	--]]	
end
