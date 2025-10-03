local Player = game:GetService("Players").LocalPlayer
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local tags = require(ReplicatedStorage.Shared.tags)
local enums = require(ReplicatedStorage.Shared.enums)
local types = require(ReplicatedStorage.Shared.types)
local RunService = game:GetService("RunService")
local clientUitls = require(ReplicatedStorage.Shared.clientUitls)

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
local topText = shopFrame:FindFirstChildOfClass("TextLabel")
local scrollingFrameParticles = shopFrame:WaitForChild("ScrollingFrameParticles") :: ScrollingFrame
local scrollingFrameModels = shopFrame:WaitForChild("ScrollingFrameModels") :: ScrollingFrame
local closeButton = shopFrame:FindFirstChildOfClass("ImageButton")

local topBar = shopFrame:WaitForChild("TopBar")
local flushEffectsOpen: ImageButton = topBar:WaitForChild("FlushEffectsOpen")
local modelsOpen: ImageButton = topBar:WaitForChild("ModelsOpen")

local shop = CollectionService:GetTagged(tags.SHOP_PROXIMITY)[1]
if not shop then
	shop = CollectionService:GetInstanceAddedSignal(tags.SHOP_PROXIMITY):Wait()
end

local filteredShopItems: { types.ShopItem } = {}
local ownedShopItems: { number } = {}

local DISTANCE_THRESHOLD = 20

local updateGUI

local function SetupOpenCloseConnections()
	-- Open Connection

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

	-- Open flush effects
	flushEffectsOpen.MouseButton1Down:Connect(function()
		topText.Text = "Flush effects!"
		scrollingFrameParticles.Visible = true
		scrollingFrameModels.Visible = false
	end)

	-- Open models
	modelsOpen.MouseButton1Down:Connect(function()
		topText.Text = "Toilet variants!"
		scrollingFrameParticles.Visible = false
		scrollingFrameModels.Visible = true
	end)
end

local function GetOwnedShopObjects()
	ownedShopItems = getOwnedShopItems:InvokeServer()
	if #ownedShopItems == 0 then
		ownedShopItems = buyShopItems:InvokeServer(1) -- Buy water particles
		ownedShopItems = buyShopItems:InvokeServer(100) -- Buy white toilet
	end
end

local buttonConnections = {} -- [button] = connection

local function DoPulse(parent)
	clientUitls.PulseFrame(
		parent,
		clientUitls.standardPulse.scale,
		clientUitls.standardPulse.durUp,
		clientUitls.standardPulse.waitDur,
		clientUitls.standardPulse.durDown
	)
end

local function SetupButton(
	button: ImageButton,
	actionButtonText: TextLabel,
	mode: "GroupClaim" | "Buy" | "Equip",
	id: number,
	price: TextLabel,
	cost: number,
	equipMode: "Model" | "Particle"
)
	if buttonConnections[button] then
		buttonConnections[button]:Disconnect()
		buttonConnections[button] = nil
	end
	local conn
	if mode == "GroupClaim" then
		actionButtonText.Text = "Claim!"
		conn = button.MouseButton1Click:Connect(function()
			DoPulse(button)
			print("GroupClaim clicked")
		end)
	elseif mode == "Equip" then
		price.Visible = false
		actionButtonText.Text = "Equip"
		conn = button.MouseButton1Click:Connect(function()
			DoPulse(button)
			equipShopItem:InvokeServer(id, equipMode)
		end)
	elseif mode == "Buy" then
		actionButtonText.Text = "Buy"
		price.Text = "$" .. cost
		price.Visible = true
		conn = button.MouseButton1Click:Connect(function()
			DoPulse(button)
			ownedShopItems = buyShopItems:InvokeServer(id)
			if table.find(ownedShopItems, id) then
				SetupButton(button, actionButtonText, "Equip", id, price, cost, equipMode)
			end
		end)
	end
	buttonConnections[button] = conn
end

updateGUI = function()
	for _, shopItem in ipairs(filteredShopItems) do
		local shopItemPrefabClone = shopItemPrefab:Clone()
		local price: TextLabel = shopItemPrefabClone:FindFirstChild("Price")
		local title: TextLabel = shopItemPrefabClone:FindFirstChild("Title")
		local actionButton: ImageButton = shopItemPrefabClone:FindFirstChildOfClass("ImageButton")
		local actionButtonText = actionButton:FindFirstChildOfClass("TextLabel")
		local imageLabel: ImageLabel = shopItemPrefabClone:FindFirstChildOfClass("ImageLabel")

		if table.find(ownedShopItems, shopItem.Id) then
			SetupButton(
				actionButton,
				actionButtonText,
				"Equip",
				shopItem.Id,
				price,
				shopItem.PriceMoney,
				shopItem.ItemPlacement
			)
		elseif shopItem.ShopFunction == enums.ShopItemType.GroupJoin then
			SetupButton(
				actionButton,
				actionButtonText,
				"GroupClaim",
				shopItem.Id,
				price,
				shopItem.PriceMoney,
				shopItem.ItemPlacement
			)
		else
			SetupButton(
				actionButton,
				actionButtonText,
				"Buy",
				shopItem.Id,
				price,
				shopItem.PriceMoney,
				shopItem.ItemPlacement
			)
		end

		title.Text = shopItem.Name
		imageLabel.Image = shopItem.ImageId

		if shopItem.ItemPlacement == "Model" then
			shopItemPrefabClone.Parent = scrollingFrameModels
		else -- Is "Particle"
			shopItemPrefabClone.Parent = scrollingFrameParticles
		end
	end
end

local function SetupShop()
	filteredShopItems = getShopItemsEvents:InvokeServer()
	updateGUI()
end

local function start()
	SetupOpenCloseConnections()
	GetOwnedShopObjects()
	SetupShop()
end
start()

-- Close Connection (distance-based)
RunService.Heartbeat:Connect(function()
	if shopFrame.Visible then
		local character = Player.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")

		if hrp and shop and shop.Parent then
			local shopPos = shop.Parent:IsA("BasePart") and shop.Parent.Position
				or shop.Parent.PrimaryPart and shop.Parent.PrimaryPart.Position

			if shopPos then
				local distance = (hrp.Position - shopPos).Magnitude
				if distance > DISTANCE_THRESHOLD then
					shopFrame.Visible = false
				end
			end
		end
	end
end)
