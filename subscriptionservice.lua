--[[ 
For GITHUB users,
Please read the official DevForum Category. https://devforum.roblox.com/t/subscriptionservice/2096477/15

Note that the SubscriptionPrompt and SubscriptionChanged are not avaiable here, since IDK if it's possible
to upload childs in GitHub without Rojo.

https://devforum.roblox.com/t/subscriptionservice/2096477
]]

--[[

.▄▄ · ▄• ▄▌▄▄▄▄· .▄▄ · 
▐█ ▀. █▪██▌▐█ ▀█▪▐█ ▀. 
▄▀▀▀█▄█▌▐█▌▐█▀▀█▄▄▀▀▀█▄
▐█▄▪▐█▐█▄█▌██▄▪▐█▐█▄▪▐█
 ▀▀▀▀  ▀▀▀ ·▀▀▀▀  ▀▀▀▀ 
 
 subscription-service
 easy subscriptions for your game

]]

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local db = DataStoreService:GetDataStore("users-subs-data")
-- ⚠️ NOTE THAT IF YOU CHANGE "db" ALL CURRENT SUBSCRIPTIONS FOR USERS WILL BE DELETED

local dt = {
	_subs = {},
	_total = 0,
	_drtps = {},

	version = "1.0_Subscription",
}


local subscriptionsService = {}

local function getSubscriptionByProductID(productid)
	local subscriptionPurchased

	for key, value in pairs(dt["_subs"]) do
		if value._id == productid then
			subscriptionPurchased = value
			break
		end
	end

	return subscriptionPurchased
end

function duration_to_timestamp(duration_string)
	local value, unit = string.match(duration_string, "(%d+)(%a+)")
	value = tonumber(value)
	unit = string.lower(unit)

	local seconds = 0
	if unit == "d" then
		seconds = value * 86400
	elseif unit == "min" then
		seconds = value * 60
	elseif unit == "s" then
		seconds = value
	elseif unit == "w" then
		seconds = value * 604800
	elseif unit == "m" then
		seconds = value * 2592000
	elseif unit == "h" then
		seconds = value * 3600
	elseif unit == "y" then
		seconds = value * 31536000
	end

	local current_timestamp = os.time()
	local future_timestamp = current_timestamp + seconds
	return future_timestamp
end

function duration_to_human(duration_string)
	local value, unit = string.match(duration_string, "(%d+)(%a+)")
	value = tonumber(value)
	unit = string.lower(unit)

	local human = ""
	if unit == "d" then -- days
		human = "day"
	elseif unit == "w" then
		human = "week"
	elseif unit == "min" then
		human = "minute"
	elseif unit == "m" then -- months
		human = "month"
	elseif unit == "s" then
		human = "second"
	elseif unit == "y" then -- years
		human = "year"
	end

	if value >= 2 then
		human = human .. "s"
	end

	return value >= 2 and value .. " " or "" .. human
end

function getImportantPart(sentence)
	local words = {}
	local keywords = {"more", "increase", "gain", "add", "improve", "boost", "upgrade", "enhance", "augment", "amplify", "greater", "higher", "larger", "stronger", "better", "faster", "quicker", "smarter", "new","improved", "advanced", "enhanced", "upgraded", "amplified", "augmented", "extra"}
	for word in string.gmatch(sentence, "%S+") do
		table.insert(words, word)
	end

	local index = -1
	for i, word in ipairs(words) do
		for j, key in ipairs(keywords) do
			if word:match(key) then
				index = i
				break
			end
		end
		if index ~= -1 then
			break
		end
	end
	
	if index == -1 then
		return sentence
	end

	local importantPart = ""
	for i = index, #words do
		importantPart = importantPart .. words[i] .. " "
	end

	importantPart = "<font size=\"30\"><b>" .. importantPart .. "</b></font>"

	local newSentence = ""
	for i = 1, index - 1 do
		newSentence = newSentence .. words[i] .. " "
	end
	newSentence = newSentence .. importantPart

	return newSentence
end

function subscriptionsService:getSubscriptionForUserIdAsync(userId)
	local currentSubscription
	if typeof(userId) == "Player" then
		currentSubscription = db:GetAsync("subs-" .. userId.UserId)
	else
		currentSubscription = db:GetAsync("subs-" .. userId)
	end

	return currentSubscription ~= nil and currentSubscription or {subscription = "NONE", userHavesSubscription = false}
end

local function createGui(player, price, sub, bullets, subEnded, id)
	local plzbuy

	if player.PlayerGui:FindFirstChild("subscriptionPayment") then
		plzbuy = player.PlayerGui:FindFirstChild("subscriptionPayment")
	else
		plzbuy = script.subscriptionPayment:Clone()
		plzbuy.subscriptionPurchase.Position = UDim2.new(.5, 0, -.5, 0)
		
		plzbuy.hide.OnServerEvent:Connect(function(playr)
			if (player == playr) then
				TweenService:Create(plzbuy.subscriptionPurchase, TweenInfo.new(0.85, Enum.EasingStyle.Exponential), {
					Position = UDim2.new(.5, 0, -.5, 0)
				}):Play()
			end
		end)
	end

	if plzbuy.subscriptionPurchase.Position.Y.Scale == -0.5 then
		
		local newBulletListText = plzbuy.subscriptionPurchase.BackgroundImage.Content.MiddlContent.Content.BulletListText.Text:gsub("<subscription_name>", "<b>" .. sub .. "</b>")
		local newBuyText = (plzbuy.subscriptionPurchase.BackgroundImage.Content.Buttons.purchase["1"].Text.Text:gsub("<rbx>", price)):gsub("<fr>", duration_to_human(dt["_subs"][sub:lower()]._expire))

		local dis1 = plzbuy.subscriptionPurchase.BackgroundImage.Content.MiddlContent.Content.Disclosure.Text:gsub("rbx", price)
		local dis2 = dis1:gsub("fr", duration_to_human(dt["_subs"][sub:lower()]._expire))
		local DisclosureText = dis2:gsub("sub_name", sub)

		plzbuy.subscriptionPurchase.BackgroundImage.Content.MiddlContent.Content.Disclosure.Text = DisclosureText
		plzbuy.subscriptionPurchase.BackgroundImage.TitleContainer.Title.Text = subEnded and " Renew your subscription" or " Purchase a subscription"

		if subEnded then
			newBulletListText = "Your subscription ended. " .. newBulletListText
			db:SetAsync("subs-" .. player.UserId, {subscription = "NONE", userHavesSubscription = false})
			script.SubscriptionChanged:Fire(player, {subscription = "NONE", userHavesSubscription = false})
			player:SetAttribute("SubscriptionExpire", nil)
		end

		plzbuy.devid.Value = id

		--plzbuy.Name = HttpService:GenerateGUID(false)
		plzbuy.subscriptionPurchase.BackgroundImage.Content.MiddlContent.Content.BulletListText.Text = newBulletListText
		plzbuy.subscriptionPurchase.BackgroundImage.Content.Buttons.purchase["1"].Text.Text = newBuyText


		for i, v in pairs(bullets) do
			plzbuy.subscriptionPurchase.BackgroundImage.Content.MiddlContent.Content.BulletList["B" .. i].Text.Text = v == "{MORE}" and  "and <font size=\"30\">much more</font>!" or (v:match("</") and v or getImportantPart(v))
		end

		plzbuy.Parent = player.PlayerGui
		
		TweenService:Create(plzbuy.subscriptionPurchase, TweenInfo.new(0.85, Enum.EasingStyle.Exponential), {
			Position = UDim2.new(.5, 0, .5, 0)
		}):Play()
	end
end

function subscriptionsService:PromptRenewSubscription(info)
	local currentSubscription = db:GetAsync("subs-" .. info.target.UserId)
	local sub = ""

	if currentSubscription ~= nil then sub = currentSubscription.userHavesSubscription and currentSubscription.subscription or info.subscriptionName else sub = info.subscriptionName end

	if not (dt["_subs"][sub:lower()] ~= nil) then
		local success, err = pcall(function()
			sub = getSubscriptionByProductID(currentSubscription.userSubscriptionId)._name
		end)

		if not success then
			sub = dt["_subs"][1]
		end
	end

	local id = dt["_subs"][sub:lower()]["_id"]
	local price = MarketplaceService:GetProductInfo(id, Enum.InfoType.Product).PriceInRobux
	local bullets = dt["_subs"][sub:lower()]["_upgr"]

	if (currentSubscription ~= nil) then
		if (currentSubscription.userHavesSubscription) then
			if (os.time() >= currentSubscription.expiry) then
				createGui(info.target, price, sub, bullets, true, id)
			end
		end
	end

	if (currentSubscription ~= nil) then
		if (currentSubscription.userHavesSubscription == false) and (info.showIfNotPurchased) then
			createGui(info.target, price, sub, bullets, false, id)
		end
	else
		if (info.showIfNotPurchased) then
			createGui(info.target, price, sub, bullets, false, id)
		end
	end

end

function subscriptionsService:createSubscription(subsData)
	if subsData.SubscriptionName:match("^%s*$") then
		warn("You need to specify a SubscriptionName for your subscription.")
		return false
	end

	if not (subsData.DeveloperProductId ~= nil)  then
		warn("You need to specify a DeveloperProductId for your subscription.")
		return false
	end

	if subsData.SubscriptionExpire:match("^%s*$") then
		warn("You need to specify a SubscriptionExpire for your subscription.")
		return false
	end

	if not (subsData.upgrades ~= nil) or not (#subsData.upgrades == 3)  then
		warn("You need to specify a DeveloperProductId for your subscription.")
		return false
	end

	local subscription = {
		_name = "",
		_id = 0,
		_expire = "",
		_trial = {
			_en = false,
			_exp = ""
		},
		_upgr = {}
	}

	subscription._name = subsData.SubscriptionName
	subscription._id = subsData.DeveloperProductId
	subscription._expire = subsData.SubscriptionExpire
	subscription._trial = subsData.freeTrial
	subscription._upgr = subsData.upgrades

	dt["_subs"][subscription._name:lower()] = subscription

	warn((("Subscription => <sb> is created."):gsub("<sb>", subscription._name)))
end

subscriptionsService.promptSubscription = createGui

MarketplaceService.PromptProductPurchaseFinished:Connect(function(userid, productid, ispurchased)
	if not ispurchased then return end
	local plr = Players:GetPlayerByUserId(userid)
	local subscriptionPurchased = getSubscriptionByProductID(productid)
	local expiry = duration_to_timestamp(subscriptionPurchased._expire)
	db:SetAsync("subs-" .. userid, {subscription = subscriptionPurchased._name, userHavesSubscription = true, expiry = expiry, userSubscriptionId = productid})
	script.SubscriptionChanged:Fire(plr, {subscription = subscriptionPurchased._name, userHavesSubscription = true, expiry = expiry, userSubscriptionId = productid})

	plr:SetAttribute("SubscriptionExpire", expiry)
end)

Players.PlayerAdded:Connect(function(player)
	local activeSubscription = subscriptionsService:getSubscriptionForUserIdAsync(player.UserId)
	if (activeSubscription.userHavesSubscription) then
		player:SetAttribute("SubscriptionExpire", activeSubscription.expiry)
	end

	while wait(0.2) do
		pcall(function()
			if (activeSubscription.userHavesSubscription) then
				if (activeSubscription.expiry == os.time()) then
					subscriptionsService:PromptRenewSubscription({
						target = player,
						showIfNotPurchased = false,
						subscriptionName = activeSubscription.subscription,
					})

					activeSubscription = subscriptionsService:getSubscriptionForUserIdAsync(player.UserId)
				end
			end
		end)
	end

	script.SubscriptionChanged.Event:Connect(function(playr, subs)
		if playr == player then
			activeSubscription = subs
			if (subs.userHavesSubscription) then
				player:SetAttribute("SubscriptionExpire", subs.expiry)
			else
				player:SetAttribute("SubscriptionExpire", nil)
			end
		end
	end)
end)

subscriptionsService.subscriptionChanged = script.SubscriptionChanged.Event

return subscriptionsService
