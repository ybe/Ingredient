--[[****************************************************************
	Ingredient v1.02

	Author: Evil Duck
	****************************************************************

	For the game World of Warcraft

	Display if an item can be used for any of your known crafting profession
	recipes.

	At item mouse-over, a text will be added to the tooltip if the item
	can be used to craft something by your character.
	Gray, green, yellow and orange color coded recipes are counted separately.

	Chat command: "/ingr reset" - Do this if you abandon a profession.

	****************************************************************]]

-- 1.02 bug-fix for not forgetting tooltip item
-- 1.00 First version: "Recipes: orange/yellow/green/gray/red", shift-list
--		with all ingredients

SLASH_INGREDIENT1 = "/ingr";
SLASH_INGREDIENT2 = "/ingredient";
IngredientRegistry={ };		-- per character
local ihf,_,reg,skillMatch=CreateFrame("Frame");
ihf:RegisterEvent("ADDON_LOADED"); ihf:RegisterEvent("CHAT_MSG_SKILL");
ihf:RegisterEvent("TRADE_SKILL_SHOW"); ihf:RegisterEvent("TRADE_SKILL_CLOSE"); ihf:RegisterEvent("TRADE_SKILL_UPDATE");
local base,dif="|cFFAAFFAA",{"|cFF909090","|cFF00FF00","|cFFFFFF00","|cFFE04224","|cFFFF0000"};

function ihf.TRADE_SKILL_CLOSE() ihf.TRADE_SKILL_SHOWactive=nil; end
function ihf.TRADE_SKILL_UPDATE() ihf.TRADE_SKILL_SHOW_scanner(); end
function ihf.CHAT_MSG_SKILL(text) if (text:match(skillMatch)) then ihf.TRADE_SKILL_SHOW_scanner(); end end
function ihf.TRADE_SKILL_SHOW()
	if (not reg.Reagents) then
		print(base.."==>> Ingredient: Thank you. You may now play as normal until you abandon a profession.");
		print(base.."==>> Ingredient: When you mouse over an item, I will show you the number of recipes you have that can utilize that item and their respective experience color coding.");
	end
	ihf.TRADE_SKILL_SHOWactive=true;
	ihf.TRADE_SKILL_SHOW_scanner();
end

function ihf.ADDON_LOADED(addon)
	if (addon~="Ingredient") then return; end
	reg=IngredientRegistry;
	ihf.TT_SetBagItem=GameTooltip.SetBagItem; GameTooltip.SetBagItem=ihf.hookBagItem;
	ihf.TT_SetGuildBankItem=GameTooltip.SetGuildBankItem; GameTooltip.SetGuildBankItem=ihf.hookGuildBankItem;
	skillMatch=string.format("%s(.+)%s(%%d+)%s",ERR_SKILL_UP_SI:format("PROFTEXT",12345):match("^(.*)PROFTEXT(.*)12345(.*)$"));
	if (not reg.Reagents) then
		print(base.."==>>===>>====>>");
		print(base.."==>> Ingredient: To show your new addon what you can do, open your profession windows once per profession.");
	end
end

local function onEvent(_,event,...) if (ihf[event]) then ihf[event](...); return; end end
ihf:SetScript("OnEvent",onEvent);

local function onUpdate()
	if (not GameTooltip or not GameTooltip:IsVisible()) then ihf.hookBag=nil; ihf.hookTab=nil; return; end
	if (ihf.showExpanded==IsShiftKeyDown()) then return; end
	ihf.showExpanded=IsShiftKeyDown();
	if (ihf.hookBag) then ihf.hookBagItem(GameTooltip,ihf.hookBag,ihf.hookSlot); end
	if (ihf.hookTab) then ihf.hookGuildBankItem(GameTooltip,ihf.hookTab,ihf.hookSlot); end
end
ihf:SetScript("OnUpdate",onUpdate);

function ihf.TRADE_SKILL_SHOW_scanner()
	if (not ihf.TRADE_SKILL_SHOWactive or IsTradeSkillLinked()) then return; end
	local skill,rank,maxlevel=GetTradeSkillLine(); if (skill=="UNKNOWN") then return; end
	reg.Reagents=reg.Reagents or {};
	reg.Recipes=reg.Recipes or {};
	for i=1,GetNumTradeSkills() do
		local recipe,difficulty=GetTradeSkillInfo(i);
		reg.Recipes[recipe]=reg.Recipes[recipe] or {}; wipe(reg.Recipes[recipe]);
		if (difficulty=="trivial") then difficulty=0; elseif (difficulty=="easy") then difficulty=1;
		elseif (difficulty=="medium") then difficulty=2; elseif (difficulty=="optimal") then difficulty=3; end
		if (type(difficulty)=="number") then
			for j=1,GetTradeSkillNumReagents(i) do
				local item=GetTradeSkillReagentItemLink(i,j);
				if (item) then
					item=ihf:GetID(item);
 					reg.Reagents[item]=reg.Reagents[item] or {};
					reg.Reagents[item][recipe]=difficulty;
					reg.Recipes[recipe][item]=reg.Recipes[recipe][item] or {}; wipe(reg.Recipes[recipe][item]);
					reg.Recipes[recipe][item].Name,reg.Recipes[recipe][item].Icon,reg.Recipes[recipe][item].Count=GetTradeSkillReagentInfo(i,j);
	end end end end
end

function ihf:GetID(link) return tostring(link):match("(item:%p?%d+:%p?%d+:%p?%d+:%p?%d+:%p?%d+:%p?%d+:%p?%d+)"); end

function ihf.hookBagItem(tt,bag,slot)
	ihf.hookBag=bag; ihf.hookSlot=slot; ihf.hookTab=nil; local cd,rc=ihf.TT_SetBagItem(tt,bag,slot);
	local _,item=tt:GetItem(); item=ihf:GetID(item); ihf.AddReagentInfo(tt,item); return cd,rc;
end

function ihf.hookGuildBankItem(tt,tab,slot)
	ihf.hookBag=nil; ihf.hookSlot=slot; ihf.hookTab=tab; ihf.TT_SetGuildBankItem(tt,tab,slot);
	local _,item=tt:GetItem(); item=ihf:GetID(item); ihf.AddReagentInfo(tt,item);
end

function ihf.AddReagentInfo(tt,item)
	if (not reg.Reagents or not reg.Reagents[item] or not next(reg.Reagents[item])) then return; end
	local gray,green,yellow,orange,red=0,0,0,0,0;
	for k,v in pairs(reg.Reagents[item]) do
		if (v==0) then gray=gray+1; elseif (v==1) then green=green+1; elseif (v==2) then yellow=yellow+1; elseif (v==3) then orange=orange+1; else red=red+1; end
	end
	local text="";
	if (orange>0) then text=text..dif[4]..orange..base.."/"; end
	if (yellow>0) then text=text..dif[3]..yellow..base.."/"; end
	if (green>0) then text=text..dif[2]..green..base.."/"; end
	if (gray>0) then text=text..dif[1]..gray..base.."/"; end
	if (red>0) then text=text..dif[5]..red..base.."/"; end
	if (text:len()<2) then return; end
	tt:AddLine(base.."Recipes: "..text:sub(1,-2)..dif[1].." (shift)");
	if (ihf.showExpanded) then
		local shown=0;
		for k,v in pairs(reg.Reagents[item]) do if (v==3 and shown<10) then ihf.AddRecipeInfo(tt,dif[v+1],k); shown=shown+1; end end
		for k,v in pairs(reg.Reagents[item]) do if (v==2 and shown<10) then ihf.AddRecipeInfo(tt,dif[v+1],k); shown=shown+1; end end
		for k,v in pairs(reg.Reagents[item]) do if (v==1 and shown<10) then ihf.AddRecipeInfo(tt,dif[v+1],k); shown=shown+1; end end
		for k,v in pairs(reg.Reagents[item]) do if (v==0 and shown<10) then ihf.AddRecipeInfo(tt,dif[v+1],k); shown=shown+1; end end
		if (red+orange+yellow+green+gray>10) then tt:AddDoubleLine(" ",base..((red+orange+yellow+green+gray)-10).." more"); end
	end
	tt:Show();
end

function ihf.AddRecipeInfo(tt,color,recipe)
	local items="";
	if (reg.Recipes[recipe]) then
		for k,v in pairs(reg.Recipes[recipe]) do
			if (items:len()>0) then items=items..base..", "; end
			local count=GetItemCount(k,true);
			items=items.."|T"..v.Icon..":0|t ";
			if (count>=v.Count) then items=items..dif[2]; else items=items..dif[5]; end
			items=items..count.."/"..v.Count;
		end
		if (items:len()>0) then items=base..items.." - "; end
	end
	tt:AddDoubleLine(" ",items..color..recipe);
end

local function Slasher(msg)
	if (msg:lower()=="reset") then
		wipe(IngredientRegistry);
		print(base.."==>> Ingredient: All professions forgotten.");
		print(base.."==>> Ingredient: Open any profession window you want me to know about.");
	end
end
SlashCmdList.INGREDIENT=Slasher;
