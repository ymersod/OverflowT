local Player = game:GetService("Players").LocalPlayer
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local tags = require(ReplicatedStorage.Shared.tags)
local enums = require(ReplicatedStorage.Shared.enums)
local types = require(ReplicatedStorage.Shared.types)

local getShopItemsEvents = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("Events")
	:WaitForChild("ShopEvents")
	:WaitForChild("GetShopItems")
local getOwnedShopItems = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("Events")
	:WaitForChild("ShopEvents")
	:WaitForChild("GetOwnedShopItems")
local buyShopItems = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("Events")
	:WaitForChild("ShopEvents")
	:WaitForChild("BuyShopItem")
local equipShopItem = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("Events")
	:WaitForChild("ShopEvents")
	:WaitForChild("EquipShopItem")

-- UI Elements
local shopItemPrefab = ReplicatedStorage:WaitForChild("DynamicUI"):WaitForChild("ShopItem")

local StaterGUI = Player:WaitForChild("PlayerGui")
local ScreenGUI = StaterGUI:WaitForChild("ScreenGui")
local shopFrame: Frame = ScreenGUI:WaitForChild("Shop")
local scrollingFrame = shopFrame:FindFirstChildOfClass("ScrollingFrame")
local closeButton = shopFrame:FindFirstChildOfClass("ImageButton")

local filteredShopItems: { types.ShopItem } = {}
local ownedShopItems: { number } = {}

local updateGUI

local function SetupOpenCloseConnections()
	-- Open Connection
	local shop = CollectionService:GetTagged(tags.SHOP_PROXIMITY)[1]

	if not shop:IsA("ProximityPrompt") then
		warn("Somehow this is not a proximity prompt, something when wrong here")
		return
	end

	shop.Triggered:Connect(function()
		shopFrame.Visible = true
	end)

	-- Close Connection
	closeButton.MouseButton1Down:Connect(function()
		shopFrame.Visible = false
	end)
end

local function GetOwnedShopObjects()
	ownedShopItems = getOwnedShopItems:InvokeServer(Player)

	if #ownedShopItems == 0 then
		ownedShopItems = buyShopItems:InvokeServer(Player, 1)
	end
end
local buttonConnections = {} -- [button] = connection

local function SetupButton(button: ImageButton, mode: "GroupClaim" | "Buy" | "Equip", id: number)
	if buttonConnections[button] then
		buttonConnections[button]:Disconnect()
		buttonConnections[button] = nil
	end
	local conn
	if mode == "GroupClaim" then
		conn = button.MouseButton1Click:Connect(function()
			print("GroupClaim clicked")
		end)
	elseif mode == "Equip" then
		conn = button.MouseButton1Click:Connect(function()
			equipShopItem:InvokeServer(id)
		end)
	elseif mode == "Buy" then
		conn = button.MouseButton1Click:Connect(function()
			ownedShopItems = buyShopItems:InvokeServer(id)
			updateGUI()
		end)
	end
	buttonConnections[button] = conn
end

updateGUI = function()
	for _, shopItem in ipairs(filteredShopItems) do
		-- TODO: Image also needed
		local shopItemPrefabClone = shopItemPrefab:Clone()
		local price: TextLabel = shopItemPrefabClone:FindFirstChild("Price")
		local title: TextLabel = shopItemPrefabClone:FindFirstChild("Title")
		local actionButton: ImageButton = shopItemPrefabClone:FindFirstChildOfClass("ImageButton")
		local actionButtonText = actionButton:FindFirstChildOfClass("TextLabel")

		if table.find(ownedShopItems, shopItem.Id) then
			actionButtonText.Text = "Equip"
			SetupButton(actionButton, "Equip", shopItem.Id)
		elseif shopItem.ShopFunction == enums.ShopItemType.GroupJoin then
			actionButtonText.Text = "Claim!"
			SetupButton(actionButton, "GroupClaim", shopItem.Id)
		else
			actionButtonText.Text = "Buy"
			SetupButton(actionButton, "Buy", shopItem.Id)
		end

		price.Text = shopItem.PriceMoney
		price.Visible = true
		title.Text = shopItem.Name

		shopItemPrefabClone.Parent = scrollingFrame
	end
end

local function SetupShop()
	filteredShopItems = getShopItemsEvents:InvokeServer(Player)
	updateGUI()
end

local function start()
	SetupOpenCloseConnections()
	GetOwnedShopObjects()
	SetupShop()
end
start()
