counter = 1 --used to keep track of how many open loot rolls exist
lootlist_rollframe = {} --used to manage multiple loot roll windows


function lootlist_itemlookup(itemName)
	local item_match = ''
	local item_row = 0
	
	for row=1, #list do
		if list[row][1] == itemName then 
			item_match = itemName 
			item_row = row
		end
	end
	
	if item_match ~= '' then
		local players = list[item_row]
		lootlist_rollframe[counter] = CreateFrame('Frame', 'LootList_Frame_Roll', UIParent, "BasicFrameTemplateWithInset")
		
		lootlist_rollframe[counter].title = lootlist_rollframe[counter]:CreateFontString(nil, "TEST")
		lootlist_rollframe[counter].title:SetFontObject("GameFontHighlight")
		lootlist_rollframe[counter].title:SetPoint("CENTER", lootlist_rollframe[counter].TitleBg, "CENTER", 5, 0)
		lootlist_rollframe[counter].title:SetText(itemName)
		
		if counter == 1 then
			lootlist_rollframe[counter]:SetPoint('CENTER', UIParent, "CENTER", -200, 200)
		else 
			lootlist_rollframe[counter]:SetPoint("TOPLEFT", lootlist_rollframe[counter - 1], "BOTTOMLEFT")
		end

		if #players == 1 then
			local freeroll_indicator = 1
			list[item_row][2] = 'FREEROLL: 0'
		end
		
		if (UnitIsGroupLeader('player')) then
			create_lootframe_buttons(itemName, item_row, lootlist_rollframe[counter])
			handle_raidchat(itemName, item_row, lootlist_rollframe[counter])
		end
		
		lootlist_rollframe[counter]:HookScript("OnHide", function() 
			counter = counter - 1 
		end)
		counter = counter + 1
		if freeroll_indicator == 1 then list[item_row][2] = nil end
	end
end


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
		lootlist_itemlookup(itemName)
		end
	end
end)


function create_lootframe_buttons(itemName, item_row, local_frame)
	local players = list[item_row]
	local framesize = (#players - 1)*100
	lootlist_rollframe[counter]:SetSize(framesize, 50)
	
	local frames = {}
	for i=2, #players do
		frames[i]=CreateFrame('Button', 'tmpframe', lootlist_rollframe[counter], "UIPanelButtonTemplate")
		frames[i].i=i
		frames[i]:SetSize(100, 30)
		if i == 2 then 
			frames[i]:SetPoint('TOPLEFT', lootlist_rollframe[counter], 'TOPLEFT', 0, -20)				
		else 
			frames[i]:SetPoint('TOPLEFT', frames[i-1], 'TOPRIGHT')		
		end
		frames[i]:SetText(players[i])	
		frames[i]:SetScript("OnClick", function()
			print(players[i])
		end)
	end
end


function handle_raidchat(itemName, item_row, local_frame)
	local current_player_up_number = 2
	local current_player_up = {list[item_row][current_player_up_number]}
	
	if #list[item_row] > 2 then 
		local next_ranking = strsub(list[item_row][current_player_up_number + 1], 
		strfind(list[item_row][current_player_up_number + 1], ":"),  #list[item_row][current_player_up_number + 1])
		while next_ranking == strsub(list[item_row][current_player_up_number], 
		strfind(list[item_row][current_player_up_number], ":"),  #list[item_row][current_player_up_number]) do
			current_player_up[current_player_up_number - 1] = list[item_row][current_player_up_number]
			current_player_up_number = current_player_up_number + 1
			current_ranking = strsub(list[item_row][current_player_up_number], 
			strfind(list[item_row][current_player_up_number], ":"),  #list[item_row][current_player_up_number])
		end
	end
	
	if #current_player_up == 1 then
		SendChatMessage(itemName .. " goes to " .. strsub(current_player_up[1], 1, strfind(current_player_up[1], ":") - 1), "RAID")
	else 
		local output_string = strsub(current_player_up[1], 1, strfind(current_player_up[1], ":") - 1)
		for roller=2, #current_player_up do
			output_string = output_string .. ", " .. strsub(current_player_up[roller], 1, strfind(current_player_up[roller], ":") - 1)
		end
		output_string = output_string .. " all rolling"
		SendChatMessage(itemName .. " " .. output_string, "RAID")
	end
	
	current_player_up_number = 2
	local_frame:RegisterEvent("CHAT_MSG_RAID")
	local_frame:RegisterEvent("CHAT_MSG_RAID_LEADER")
	local_frame:SetScript("OnEvent", function(self, event, ...)
		local msg, playerName = ...
		playerName = strsub(playerName, 1, strfind(playerName, "-") - 1)
		if msg:lower() == 'pass' then
			if current_player_up_number < #list[item_row] then
				current_player_up_number = current_player_up_number + 1
				
				local current_player_up_up = list[item_row][current_player_up_number]
				SendChatMessage(itemName .. " goes to " .. strsub(current_player_up_up, 1, strfind(current_player_up_up, ":") - 1), "RAID")
			else
				SendChatMessage(itemName .. " goes to FREEROLL", "RAID")
			end
		end
	end)
end


function get_player_up(item_row, current_passers)

	local current_player_up_number = 2
	local current_player_up = {list[item_row][current_player_up_number]}
	
	while #current_passers > 0 do
	
		if #list[item_row] > 2 then 
			local next_ranking = strsub(list[item_row][current_player_up_number + 1], 
			strfind(list[item_row][current_player_up_number + 1], ":"),  #list[item_row][current_player_up_number + 1])
			while next_ranking == strsub(list[item_row][current_player_up_number], 
			strfind(list[item_row][current_player_up_number], ":"),  #list[item_row][current_player_up_number]) do
				current_player_up[current_player_up_number - 1] = list[item_row][current_player_up_number]
				current_player_up_number = current_player_up_number + 1
				current_ranking = strsub(list[item_row][current_player_up_number], 
				strfind(list[item_row][current_player_up_number], ":"),  #list[item_row][current_player_up_number])
			end
		end
		
		for player=1, #current_player_up do
			for passer=1, #current_passers do
				if current_player_up[player] == current_passers[passer] then
					current_player_up[player] = nil
					current_passers[passer] = nil
				end
			end
		end
	end

	return(item_row)
end
