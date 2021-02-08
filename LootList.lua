counter = 1 --used to keep track of how many open loot rolls exist
lootlist_rollframe = {} --used to manage multiple loot roll windows


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
		lootlist_rollframe[counter] = CreateFrame('Frame', 'LootList_Frame_Roll' .. counter, LootList_Frame, "BasicFrameTemplateWithInset")
		
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
		
		current_passers = {}
		
		if (UnitIsGroupLeader('player')) then
			create_lootframe_buttons(itemLink, item_row, lootlist_rollframe[counter])
			handle_raidchat(itemLink, item_row, lootlist_rollframe[counter])
		end
		
		lootlist_rollframe[counter]:HookScript("OnHide", function() 
			counter = counter - 1 
			lootlist_rollframe[counter]:UnregisterAllEvents()
		end)
		counter = counter + 1
		if freeroll_indicator == 1 then list[item_row][2] = nil end
	end
end




function create_lootframe_buttons(itemLink, item_row, local_frame)
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
			current_passers[#current_passers + 1] = strip_colon_player(players[i])
			local new_player = get_player_up(item_row, current_passers)
			if new_player == 1 then
				send_raid_message(itemLink)
			end
		end)
	end
end


function handle_raidchat(itemLink, item_row, local_frame)
	current_player_up_number = 2
	current_player_up = {strip_colon_player(list[item_row][current_player_up_number])}
	
	if #list[item_row] > current_player_up_number then 
		local next_ranking = strip_colon_rank(list[item_row][current_player_up_number + 1]) 
		while next_ranking == strip_colon_rank(list[item_row][current_player_up_number]) do
			current_player_up_number = current_player_up_number + 1
			current_player_up[#current_player_up + 1] = strip_colon_player(list[item_row][current_player_up_number])
			current_ranking = strip_colon_rank(list[item_row][current_player_up_number])
			if #list[item_row] > current_player_up_number then
				next_ranking = strip_colon_rank(list[item_row][current_player_up_number + 1])
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
			local new_player = get_player_up(item_row, current_passers)
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

function get_player_up(item_row, current_passers_func)
	
	local new_player = 0
	
	for i = 1, #list[item_row] * #current_passers_func do
		if #current_player_up == 0 then
			new_player = 1
		end
		if #current_player_up == 0 and #list[item_row] > current_player_up_number then
			current_player_up_number = current_player_up_number + 1
			current_player_up = {strip_colon_player(list[item_row][current_player_up_number])}
		end

		if #list[item_row] > current_player_up_number then 
			local next_ranking = strip_colon_rank(list[item_row][current_player_up_number + 1]) 
			while next_ranking == strip_colon_rank(list[item_row][current_player_up_number]) do
				current_player_up_number = current_player_up_number + 1
				current_player_up[#current_player_up + 1] = strip_colon_player(list[item_row][current_player_up_number])
				current_ranking = strip_colon_rank(list[item_row][current_player_up_number])
				if #list[item_row] > current_player_up_number then
					next_ranking = strip_colon_rank(list[item_row][current_player_up_number + 1])
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