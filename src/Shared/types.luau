local types = {}

export type ShopItem = {
	Id: number?,
	Name: string?,
	ShopFunction: string?,
	PriceMoney: number?,
	PriceRobux: number?,
	ImageId: string?,
	ItemPlacement: "Particle" | "Model",
}

export type Action = {
	ActionId: string,
	OwnedAmount: number,
}

return types
