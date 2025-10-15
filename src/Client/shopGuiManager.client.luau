local Player = game:GetService("Players").LocalPlayer
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local tags = require(ReplicatedStorage.Shared.tags)
local enums = require(ReplicatedStorage.Shared.enums)
local types = require(ReplicatedStorage.Shared.types)
local RunService = game:GetService("RunService")
local clientUitls = require(ReplicatedStorage.Shared.clientUitls)

local shopEvents = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Events"):WaitForChild("ShopEvents")
local getShopItemsEvents = shopEvents:WaitForChild("GetShopItems")
local getOwnedShopItems = shopEvents:WaitForChild("GetOwnedShopItems")
local buyShopItems = shopEvents:WaitForChild("BuyShopItem")
local equipShopItem = shopEvents:WaitForChild("EquipShopItem")
local shopFunnel =
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Events"):WaitForChild("Funnel"):WaitForChild("Shop")

local promptRobuxPurchaseEvents = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("Events")
	:WaitForChild("MonetizationEvents")
	:WaitForChild("PromptBuy")
local processPurchaseEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("Events")
	:WaitForChild("MonetizationEvents")
	:WaitForChild("ProcessPurchase")

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

local function ShopVisibility(toEnable: boolean)
	shopFrame.Visible = toEnable
	if toEnable then
		shopFunnel:FireServer(enums.Analytics.Shop.Opened.Name)
	else
		shopFunnel:FireServer(enums.Analytics.Shop.Closed.Name)
	end
end

local function SetupOpenCloseConnections()
	-- Open Connection

	if not shop:IsA("ProximityPrompt") then
		warn("Somehow this is not a proximity prompt, something when wrong here")
		return
	end

	shop.Triggered:Connect(function()
		ShopVisibility(true)
	end)

	-- Close Connection
	closeButton.MouseButton1Down:Connect(function()
		ShopVisibility(false)
	end)

	-- Open flush effects
	flushEffectsOpen.MouseButton1Down:Connect(function()
		topText.Text = "Flush effects!"
		scrollingFrameParticles.Visible = true
		scrollingFrameModels.Visible = false
		shopFunnel:FireServer(enums.Analytics.Shop.SwitchOverview.Name)
	end)

	-- Open models
	modelsOpen.MouseButton1Down:Connect(function()
		topText.Text = "Toilet variants!"
		scrollingFrameParticles.Visible = false
		scrollingFrameModels.Visible = true
		shopFunnel:FireServer(enums.Analytics.Shop.SwitchOverview.Name)
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
	equipButton: ImageButton,
	buyButton: ImageButton,
	buyRobuxButton: ImageButton,
	mode: "GroupClaim" | "Buy" | "Equip" | "BuyRobux",
	id: number,
	price: TextLabel,
	cost: number,
	equipMode: "Model" | "Particle",
	extraMoney: number,
	robuxCost: number?,
	buttonText: TextLabel?
)
	local conn
	if mode == "GroupClaim" then
		-- actionButtonText.Text = "Claim!"
		-- conn = button.MouseButton1Click:Connect(function()
		-- 	DoPulse(button)
		-- 	print("GroupClaim clicked")
		-- end)
		warn("Group huh")
	elseif mode == "Equip" then
		price.Visible = false
		equipButton.Visible = true

		buyButton.Visible = false
		if buttonConnections[buyButton] then
			buttonConnections[buyButton]:Disconnect()
			buttonConnections[buyButton] = nil
		end
		buyRobuxButton.Visible = false
		if buttonConnections[buyRobuxButton] then
			buttonConnections[buyRobuxButton]:Disconnect()
			buttonConnections[buyRobuxButton] = nil
		end

		conn = equipButton.MouseButton1Click:Connect(function()
			DoPulse(equipButton)
			equipShopItem:InvokeServer(id, extraMoney, equipMode)
		end)
		buttonConnections[equipButton] = conn
	elseif mode == "Buy" then
		price.Text = "$" .. cost
		price.Visible = true
		buyButton.Visible = true

		equipButton.Visible = false
		if buttonConnections[equipButton] then
			buttonConnections[equipButton]:Disconnect()
			buttonConnections[equipButton] = nil
		end

		conn = buyButton.MouseButton1Click:Connect(function()
			DoPulse(buyButton)
			ownedShopItems = buyShopItems:InvokeServer(id, equipMode)
			if table.find(ownedShopItems, id) then
				SetupButton(equipButton, buyButton, buyRobuxButton, "Equip", id, price, cost, equipMode, extraMoney)
			end
		end)
		buttonConnections[buyButton] = conn
	elseif mode == "BuyRobux" then
		equipButton.Visible = false
		buyRobuxButton.Visible = true
		if robuxCost and buttonText then
			buttonText.Text = `\u{E002}{robuxCost}`
		end

		if buttonConnections[equipButton] then
			buttonConnections[equipButton]:Disconnect()
			buttonConnections[equipButton] = nil
		end

		conn = buyRobuxButton.MouseButton1Click:Connect(function()
			DoPulse(buyRobuxButton)
			promptRobuxPurchaseEvents:FireServer(equipMode, tostring(id)) -- Purchase is handles in an event sent from server
		end)
	end
end

local cache: {
	[number]: {
		item: Frame,
		equipButtonRef: ImageButton,
		buyButtonRef: ImageButton,
		buyRobuxButtonRef: ImageButton,
		priceRef: TextLabel,
	},
} =
	{}
updateGUI = function()
	for _, shopItem in ipairs(filteredShopItems) do
		local shopItemPrefabClone = shopItemPrefab:Clone() :: Frame
		local price: TextLabel = shopItemPrefabClone:FindFirstChild("Price")
		local title: TextLabel = shopItemPrefabClone:FindFirstChild("Title")
		local extraMoney: TextLabel = shopItemPrefabClone:FindFirstChild("ExtraMoney")
		local equipButton: ImageButton = shopItemPrefabClone:FindFirstChild("Equip")
		local buyButton: ImageButton = shopItemPrefabClone:FindFirstChild("Buy")
		local buyRobuxButton: ImageButton = shopItemPrefabClone:FindFirstChild("BuyRobux")
		local buyRobuxButtonText: TextLabel = buyRobuxButton and buyRobuxButton:FindFirstChildOfClass("TextLabel")
		local imageLabel: ImageLabel = shopItemPrefabClone:FindFirstChildOfClass("ImageLabel")

		cache[shopItem.Id] = {
			item = shopItemPrefabClone,
			equipButtonRef = equipButton,
			buyButtonRef = buyButton,
			buyRobuxButtonRef = buyRobuxButton,
			priceRef = price,
		}

		if table.find(ownedShopItems, shopItem.Id) then
			SetupButton(
				equipButton,
				buyButton,
				buyRobuxButton,
				"Equip",
				shopItem.Id,
				price,
				shopItem.PriceMoney,
				shopItem.ItemPlacement,
				shopItem.ExtraMoney
			)
		elseif shopItem.ShopFunction == enums.ShopItemType.EasterEgg then
			shopItemPrefabClone.Visible = false
		elseif shopItem.ShopFunction == enums.ShopItemType.RobuxAndMoney then
			SetupButton(
				equipButton,
				buyButton,
				buyRobuxButton,
				"Buy",
				shopItem.Id,
				price,
				shopItem.PriceMoney,
				shopItem.ItemPlacement,
				shopItem.ExtraMoney
			)
			SetupButton(
				equipButton,
				buyButton,
				buyRobuxButton,
				"BuyRobux",
				shopItem.Id,
				price,
				shopItem.PriceMoney,
				shopItem.ItemPlacement,
				shopItem.ExtraMoney,
				shopItem.PriceRobux,
				buyRobuxButtonText
			)
		end

		title.Text = shopItem.Name
		imageLabel.Image = shopItem.ImageId
		extraMoney.Text = string.format("%.1f× $", shopItem.ExtraMoney)

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

local equippedParticles: Frame? = nil
local equippedToilet: Frame? = nil
local function SetEquipped(toEquip: Frame, mode: "Particles" | "Model")
	local prevEquippedStroke: UIStroke?
	local newStroke: UIStroke?
	if mode == "Model" then
		if equippedToilet then
			prevEquippedStroke = equippedToilet:WaitForChild("EquippedFrame"):FindFirstChild("Equipped") :: UIStroke?
		end
		equippedToilet = toEquip
	end
	if mode == "Particles" then
		if equippedParticles then
			prevEquippedStroke = equippedParticles:WaitForChild("EquippedFrame"):FindFirstChild("Equipped") :: UIStroke?
		end
		equippedParticles = toEquip
	end
	newStroke = toEquip:WaitForChild("EquippedFrame"):FindFirstChild("Equipped") :: UIStroke?

	if prevEquippedStroke then
		prevEquippedStroke.Transparency = 1
	end
	if newStroke then
		newStroke.Transparency = 0
	end
end
local function SetupEquipped()
	local localStats = Player:FindFirstChild("localstats")
	local equippedParticlesIntValue: IntValue? = localStats:FindFirstChild("EquippedParticles")
	local equippedToiletIntValue: IntValue? = localStats:FindFirstChild("EquippedToilet")

	if equippedParticlesIntValue and equippedToiletIntValue then
		local function Splitter(val: number, mode: "Particles" | "Model")
			if mode == "Particles" then
				local pShopItem = cache[val].item
				if pShopItem then
					SetEquipped(pShopItem, "Particles")
				end
			end
			if mode == "Model" then
				local tShopItem = cache[val].item
				if tShopItem then
					SetEquipped(tShopItem, "Model")
				end
			end
		end
		Splitter(equippedParticlesIntValue.Value, "Particles")
		Splitter(equippedToiletIntValue.Value, "Model")

		equippedParticlesIntValue.Changed:Connect(function(val)
			Splitter(val, "Particles")
		end)
		equippedToiletIntValue.Changed:Connect(function(val)
			Splitter(val, "Model")
		end)
	end
end

local function start()
	SetupOpenCloseConnections()
	GetOwnedShopObjects()
	SetupShop()
	SetupEquipped()
end
start()

processPurchaseEvent.OnClientEvent:Connect(function(id: number, typename: "Model" | "Particle")
	local shopItemToUpdate = cache[id]

	if shopItemToUpdate then
		if not shopItemToUpdate.item.Visible then
			shopItemToUpdate.item.Visible = true
		end

		SetupButton(
			shopItemToUpdate.equipButtonRef,
			shopItemToUpdate.buyButtonRef,
			shopItemToUpdate.buyRobuxButtonRef,
			"Equip",
			id,
			shopItemToUpdate.priceRef,
			0,
			typename,
			1.5
		)
		print("update after purchse")
	end
end)

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
					ShopVisibility(false)
				end
			end
		end
	end
end)
