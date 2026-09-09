local market = data.raw["market"]["market"]
if market then
  market.hidden = false
  market.minable = {mining_time = 0.5, result = "market"}
  market.flags = {"placeable-neutral", "player-creation", "not-rotatable"}
end

if not data.raw.item.market then
  data:extend({
    {
      type = "item",
      name = "market",
      icon = "__base__/graphics/icons/market.png",
      subgroup = "storage",
      order = "z[market]",
      place_result = "market",
      stack_size = 10,
    },
  })
end
