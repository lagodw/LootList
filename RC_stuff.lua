local addonname,addon = ...
LootList = LibStub("AceAddon-3.0"):NewAddon(addon,addonname, "AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0", "AceSerializer-3.0", "AceHook-3.0", "AceTimer-3.0");
local LLHistory = addon:NewModule("LLHistory")
local AceGUI = LibStub("AceGUI-3.0")
local dungeon_list = {"MC", "BWL", "AQ", "Naxx"}

function draw_list_tab_buttons(groupScrollFrame, dungeon)

	local dungeon_flag = 0
	for dung, val in pairs(list) do
		if dung == dungeon then dungeon_flag = 1 end
	end

	tmp = {}
	if dungeon_flag == 1 then
		for row=1, #list[dungeon] do
			if list[dungeon][row][1] then
				tmp[row] = {}
				for col=1, #list[dungeon][row] do
					tmp[row][col] = AceGUI:Create("Button")
					tmp[row][col]:SetWidth(150)
					tmp[row][col]:SetHeight(30)
					tmp[row][col]:SetText(list[dungeon][row][col])
					groupScrollFrame:AddChild(tmp[row][col])
				end
				local desc = AceGUI:Create("Label")
				desc:SetText("\n")
				desc:SetFullWidth(true)
				groupScrollFrame:AddChild(desc)
			end
		end
	end

end

local function DrawListTab(container, dungeon)

	local scrollcontainer = AceGUI:Create("SimpleGroup") -- "InlineGroup" is also good
	scrollcontainer:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)
	scrollcontainer:SetFullWidth(true)
	scrollcontainer:SetFullHeight(true) -- probably?
	scrollcontainer:SetLayout("Fill") -- important!
	
	container:AddChild(scrollcontainer)

	local groupScrollFrame = AceGUI:Create("ScrollFrame")
	groupScrollFrame:SetFullWidth(true)
	groupScrollFrame:SetLayout("Flow")
	scrollcontainer:AddChild(groupScrollFrame)
	
	draw_list_tab_buttons(groupScrollFrame, dungeon)

end


local function SelectListTab(container, event, group)
   container:ReleaseChildren()
   if group == "MC" then
		DrawListTab(container, "MC")
   elseif group == "BWL" then
		DrawListTab(container, "BWL")
	elseif group == 'AQ' then
		DrawListTab(container, "AQ")
	elseif group == 'Naxx' then
		DrawListTab(container, "Naxx")
	elseif group == 'Import' then
		DrawImportTab(container)
   end
end

function DrawLootLists(container)
	local tab =  AceGUI:Create("TreeGroup")
	tab:SetLayout("Flow")
	tab:SetTree({{text="MC", value="MC"}, {text="BWL", value="BWL"}, {text="AQ", value="AQ"}, {text="Naxx", value="Naxx"}
	, {text = "Import", value = "Import"}})
	tab:SetCallback("OnGroupSelected", SelectListTab)
	
	container:AddChild(tab)
end

function frame_test()

	local function DrawGroup1(container)	
		local frame = AceGUI:Create("SimpleGroup")
		frame:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)
		frame:SetLayout("Fill")
		frame:SetFullHeight(true)
		frame:SetFullWidth(true)
		container:AddChild(frame)

		DrawLootLists(frame)
	end

	local function DrawGroup2(container)
	  local desc = AceGUI:Create("Label")
	  desc:SetText("This is Tab 2")
	  desc:SetFullWidth(true)
	  container:AddChild(desc)
	  
	  local button = AceGUI:Create("Button")
	  button:SetText("Tab 2 Button")
	  button:SetWidth(200)
	  container:AddChild(button)
	end
	
	local function DrawGroup3(container)
	end

	local function SelectGroup(container, event, group)
	   container:ReleaseChildren()
	   if group == "tab1" then
			DrawGroup1(container)
	   elseif group == "tab2" then
			DrawGroup2(container)
		elseif group == 'tab3' then
			DrawGroup3(container)
	   end
	end

	local frame = AceGUI:Create("Frame")
	frame:SetTitle("Loot List")
	frame:SetWidth(1500)
	frame:SetHeight(600)
	frame:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)
	frame:SetLayout("Fill")

	local tab =  AceGUI:Create("TabGroup")
	tab:SetLayout("Flow")
	tab:SetTabs({{text="Loot Lists", value="tab1"}, {text="History", value="tab2"}, {text="Settings", value="tab3"}})
	tab:SetCallback("OnGroupSelected", SelectGroup)
	tab:SelectTab("tab1")

	frame:AddChild(tab)

    _G["MyGlobalFrameName"] = frame.frame
    -- Register the global variable `MyGlobalFrameName` as a "special frame"
    -- so that it is closed when the escape key is pressed.
    tinsert(UISpecialFrames, "MyGlobalFrameName")
	
end

function import_lootlist(input_text, dungeon)
	list[dungeon] = {}
	for line in string.gmatch(input_text, "[^\n]+") do
		list[dungeon][#list[dungeon] + 1] = mysplit(line, ',')
	end
end

function mysplit(inputstr, sep)
        if sep == nil then
                sep = "%s"
        end
        local t={}
        for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
                table.insert(t, str)
        end
        return t
end

function DrawImportTab(container)

	local scrollcontainer = AceGUI:Create("SimpleGroup") -- "InlineGroup" is also good
	scrollcontainer:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)
	scrollcontainer:SetFullWidth(true)
	scrollcontainer:SetFullHeight(true) -- probably?
	scrollcontainer:SetLayout("Fill") -- important!
	
	container:AddChild(scrollcontainer)

	local groupDropdown = AceGUI:Create("DropdownGroup")
	groupDropdown:SetFullWidth(true)
	groupDropdown:SetLayout("Flow")
	groupDropdown:SetTitle("Dungeon")
	groupDropdown:SetDropdownWidth(200)
	groupDropdown:SetGroupList(dungeon_list)

	local starting_group = 4
	groupDropdown:SetGroup(starting_group)
	local dungeon = dungeon_list[starting_group]
	groupDropdown:SetCallback("OnGroupSelected", function(obj,event,key) dungeon = dungeon_list[key]	end)
	scrollcontainer:AddChild(groupDropdown)

	--[[
	local import_button = AceGUI:Create("Button")
	import_button:SetWidth(300)
	import_button:SetHeight(60)
	import_button:SetText("Import List")
	groupDropdown:AddChild(import_button)
	
	import_button:SetCallback("OnClick", function() import_list(groupDropdown, dungeon) end)
	--]]
	
	local imp = AceGUI:Create("Window")
	imp:SetLayout("Flow")
	imp:SetTitle("Loot List Import")
	imp:SetFullWidth(true)
	imp:SetFullHeight(true)
	groupDropdown:AddChild(imp)

	edit = AceGUI:Create("MultiLineEditBox")
	edit:SetNumLines(20)
	edit:SetFullWidth(true)
	edit:SetFullHeight(true)
	
	imp:AddChild(edit)

	-- Credit to WeakAura2
	-- Import editbox only shows first 2500 bytes to avoid freezing the game.
	-- Use 'OnChar' event to store other characters in a text buffer
	local textBuffer, i, lastPaste = {}, 0, 0
	local pasted = ""
	edit.editBox:SetScript("OnShow", function(self)
		self:SetText("")
		pasted = ""
	end)
	local function clearBuffer(self)
		self:SetScript('OnUpdate', nil)
		pasted = strtrim(table.concat(textBuffer))
		edit.editBox:ClearFocus()
	end
	edit.editBox:SetScript('OnChar', function(self, c)
		if lastPaste ~= GetTime() then
			textBuffer, i, lastPaste = {}, 0, GetTime()
			self:SetScript('OnUpdate', clearBuffer)
		end
		i = i + 1
		textBuffer[i] = c
	end)
	edit.editBox:SetMaxBytes(2500)
	edit.editBox:SetScript("OnMouseUp", nil);

	edit:SetCallback("OnEnterPressed", function(widget, event, text)
		
		import_lootlist(text, dungeon)
		imp:Hide()
	end)
end





SLASH_LOOTLISTHISTORY1 = '/llh'
SlashCmdList["LOOTLISTHISTORY"] = frame_test
