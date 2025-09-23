local types = {}

export type ShopItem = {
	Id: number?,
	Name: string?,
	ShopFunction: string?,
	PriceMoney: number?,
	PriceRobux: number?,
	ImageId: string?,
}

export type Action = {
	ActionId: number,
	OwnedAmount: number,
}

return types
