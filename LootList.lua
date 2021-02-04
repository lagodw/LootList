list = {}
list[1] = "Boss shared loot"
list[2] = {"Wool Cloth" , "Stangg: 49", "Iviikel: 47", "Test: 30"}
list[3] = {"Linen Cloth"}

SLASH_LOOTLIST1 = '/ll'
SlashCmdList["LOOTLIST"] = KethoEditBox_Show

counter = 1 --used to keep track of how many open loot rolls exist
lootlist_rollframe = {} --used to manage multiple loot roll windows


function KethoEditBox_Show(text)
    if not KethoEditBox then
        local f = CreateFrame("Frame", "KethoEditBox", UIParent, "DialogBoxFrame")
        f:SetPoint("CENTER")
        f:SetSize(600, 500)
        
        f:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\PVPFrame\\UI-Character-PVP-Highlight", -- this one is neat
            edgeSize = 16,
            insets = { left = 8, right = 6, top = 8, bottom = 8 },
        })
        f:SetBackdropBorderColor(0, .44, .87, 0.5) -- darkblue
        
        -- Movable
        f:SetMovable(true)
        f:SetClampedToScreen(true)
        f:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then
                self:StartMoving()
            end
        end)
        f:SetScript("OnMouseUp", f.StopMovingOrSizing)
        
        -- ScrollFrame
        local sf = CreateFrame("ScrollFrame", "KethoEditBoxScrollFrame", KethoEditBox, "UIPanelScrollFrameTemplate")
        sf:SetPoint("LEFT", 16, 0)
        sf:SetPoint("RIGHT", -32, 0)
        sf:SetPoint("TOP", 0, -16)
        sf:SetPoint("BOTTOM", KethoEditBoxButton, "TOP", 0, 0)
        
        -- EditBox
        local eb = CreateFrame("EditBox", "KethoEditBoxEditBox", KethoEditBoxScrollFrame)
        eb:SetSize(sf:GetSize())
        eb:SetMultiLine(true)
        eb:SetAutoFocus(false) -- dont automatically focus
        eb:SetFontObject("ChatFontNormal")
        eb:SetScript("OnEscapePressed", function() f:Hide() end)
        sf:SetScrollChild(eb)
        
        -- Resizable
        f:SetResizable(true)
        f:SetMinResize(150, 100)
        
        local rb = CreateFrame("Button", "KethoEditBoxResizeButton", KethoEditBox)
        rb:SetPoint("BOTTOMRIGHT", -6, 7)
        rb:SetSize(16, 16)
        
        rb:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        rb:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
        rb:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
        
        rb:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then
                f:StartSizing("BOTTOMRIGHT")
                self:GetHighlightTexture():Hide() -- more noticeable
            end
        end)
        rb:SetScript("OnMouseUp", function(self, button)
            f:StopMovingOrSizing()
            self:GetHighlightTexture():Show()
            eb:SetWidth(sf:GetWidth())
        end)
        f:Show()
    end
    
    if text then
        KethoEditBoxEditBox:SetText(text)
    end
		
	KethoEditBoxButton:HookScript("OnClick", function(self)
		import_lootlist(KethoEditBoxEditBox:GetText())
	end)

    KethoEditBox:Show()
end

function import_lootlist(input_text)
	for line in string.gmatch(input_text, "[^\n]+") do
		list[#list + 1] = mysplit(line, ',')
	end
end

function mysplit (inputstr, sep)
        if sep == nil then
                sep = "%s"
        end
        local t={}
        for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
                table.insert(t, str)
        end
        return t
end


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
		players = list[item_row]
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
			lootlist_rollframe[counter]:SetSize(100, 50)
			frames=CreateFrame('Button', 'tmpframe', lootlist_rollframe[counter], "UIPanelButtonTemplate")
			frames:SetSize(100, 30)
			frames:SetPoint('TOPLEFT', lootlist_rollframe[counter], 'TOPLEFT', 0, -20)
			frames:SetText('FREEROLL')
		else
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
			
			if #list[item_row] > 1 then
				local current_player_up = list[item_row][2]
				local current_player_up_number = 2
				
				SendChatMessage(itemName .. " goes to " .. strsub(current_player_up, 1, strfind(current_player_up, ":") - 1), "RAID")
				
				lootlist_rollframe[counter]:RegisterEvent("CHAT_MSG_RAID")
				lootlist_rollframe[counter]:RegisterEvent("CHAT_MSG_RAID_LEADER")

				lootlist_rollframe[counter]:SetScript("OnEvent", function(self, event, ...)
					local msg = ...
					if msg:lower() == 'pass' then
						if current_player_up_number < #list[item_row] then
							current_player_up_number = current_player_up_number + 1
							
							current_player_up = list[item_row][current_player_up_number]
							SendChatMessage(itemName .. " goes to " .. strsub(current_player_up, 1, strfind(current_player_up, ":") - 1), "RAID")
						else
							SendChatMessage(itemName .. " FREEROLL", "RAID")
						end
					end
				end)
			else
			SendChatMessage(itemName .. " FREEROLL", "RAID")
			end
		end
		
		lootlist_rollframe[counter]:HookScript("OnHide", function() 
			counter = counter - 1 
		end)
		counter = counter + 1
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


function handle_raidchat(itemName, item_row)
	if #list[item_row] > 1 then
		local current_player_up = list[item_row][2]
		local current_player_up_number = 2
		
		SendChatMessage(itemName .. " goes to " .. strsub(current_player_up, 1, strfind(current_player_up, ":") - 1), "RAID")
		
		blankframe = CreateFrame('Frame', 'blankframe', UIParent)
		blankframe:RegisterEvent("CHAT_MSG_RAID")
		blankframe:RegisterEvent("CHAT_MSG_RAID_LEADER")

		blankframe:SetScript("OnEvent", function(self, event, ...)
			local msg = ...
			if msg:lower() == 'pass' then
				if current_player_up_number < #list[item_row] then
					current_player_up_number = current_player_up_number + 1
					
					current_player_up = list[item_row][current_player_up_number]
					SendChatMessage(itemName .. " goes to " .. strsub(current_player_up, 1, strfind(current_player_up, ":") - 1), "RAID")
				else
					SendChatMessage(itemName .. " FREEROLL", "RAID")
				end
			end
		end)
	else
	SendChatMessage(itemName .. " FREEROLL", "RAID")
	end
end