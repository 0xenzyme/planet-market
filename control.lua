local PLANET_SURFACE_NAMES = {
  nauvis = true,
  vulcanus = true,
  gleba = true,
  fulgora = true,
  aquilo = true,
}

local BASE_OFFERS = {
  {price = 1, item = "modular-armor", count = 1},
  {price = 3, item = "power-armor", count = 1},
  {price = 20, item = "power-armor-mk2", count = 1},
  {price = 1, item = "solar-panel-equipment", count = 10},
  {price = 10, item = "fission-reactor-equipment", count = 1},
  {price = 1, item = "battery-equipment", count = 1},
  {price = 8, item = "battery-mk2-equipment", count = 1},
  {price = 1, item = "construction-robot", count = 2},
  {price = 1, item = "personal-roboport-equipment", count = 1},
  {price = 20, item = "personal-roboport-mk2-equipment", count = 1},
  {price = 100, item = "personal-roboport-mk2-equipment", count = 1, quality = "legendary"},
  {price = 3, item = "exoskeleton-equipment", count = 1},
  {price = 15, item = "exoskeleton-equipment", count = 1, quality = "legendary"},
  {price = 1, item = "belt-immunity-equipment", count = 1},
  {price = 1, item = "night-vision-equipment", count = 1},
  {price = 1, item = "energy-shield-equipment", count = 1},
  {price = 5, item = "energy-shield-mk2-equipment", count = 1},
  {price = 25, item = "energy-shield-mk2-equipment", count = 1, quality = "legendary"},
  {price = 10, item = "personal-laser-defense-equipment", count = 1},
  {price = 10, item = "speed-module-3", count = 1},
  {price = 10, item = "productivity-module-3", count = 1},
  {price = 10, item = "efficiency-module-3", count = 1},
  {price = 10, item = "quality-module-3", count = 1},
}

local SPACE_AGE_OFFERS = {
  {price = 5, item = "toolbelt-equipment", count = 1},
  {price = 25, item = "toolbelt-equipment", count = 1, quality = "legendary"},
  {price = 100, item = "mech-armor", count = 1},
  {price = 50, item = "fusion-reactor-equipment", count = 1},
  {price = 30, item = "battery-mk3-equipment", count = 1},
  {price = 500, item = "mech-armor", count = 1, quality = "legendary"},
  {price = 250, item = "fusion-reactor-equipment", count = 1, quality = "legendary"},
  {price = 150, item = "battery-mk3-equipment", count = 1, quality = "legendary"},
  {price = 100, item = "captive-biter-spawner", count = 1},
  {price = 5, item = "pentapod-egg", count = 1},
}

local DISABLED_TECHS_BASE = {
  "follower-robot-count-1",
  "follower-robot-count-2",
  "follower-robot-count-3",
  "follower-robot-count-4",
  "follower-robot-count-5",
}

local DISABLED_TECHS_SPACE_AGE = {
  "artillery",
  "artillery-shell-damage-1",
  "artillery-shell-range-1",
  "artillery-shell-speed-1",
  "mech-armor",
  "fusion-reactor-equipment",
  "battery-mk3-equipment",
}

local function is_planet_surface(surface)
  if not surface or not surface.valid then
    return false
  end
  if surface.planet then
    return true
  end
  return PLANET_SURFACE_NAMES[surface.name] == true
end

local function add_offer(market, offer_data)
  if not prototypes.item[offer_data.item] then
    return
  end
  if offer_data.quality then
    if not script.active_mods["quality"] then
      return
    end
    if not prototypes.quality[offer_data.quality] then
      return
    end
  end
  local modifier = {
    type = "give-item",
    item = offer_data.item,
    count = offer_data.count or 1,
  }
  if offer_data.quality then
    modifier.quality = offer_data.quality
  end
  market.add_market_item{
    price = {{name = "coin", count = offer_data.price}},
    offer = modifier,
  }
end

local function fill_offers(market)
  market.clear_market_items()
  for i = 1, #BASE_OFFERS do
    add_offer(market, BASE_OFFERS[i])
  end
  if script.active_mods["space-age"] then
    for i = 1, #SPACE_AGE_OFFERS do
      add_offer(market, SPACE_AGE_OFFERS[i])
    end
  end
end

local function draw_coin_marker(market)
  rendering.draw_sprite{
    sprite = "item/coin",
    target = market,
    surface = market.surface,
    x_scale = 1.5,
    y_scale = 1.5,
  }
end

local function add_map_tag(market)
  local force = game.forces.player
  local surface = market.surface
  local position = market.position
  force.chart(surface, {
    {position.x - 16, position.y - 16},
    {position.x + 16, position.y + 16},
  })
  local existing = force.find_chart_tags(surface, {
    {position.x - 2, position.y - 2},
    {position.x + 2, position.y + 2},
  })
  if existing and #existing > 0 then
    return
  end
  force.add_chart_tag(surface, {
    position = position,
    icon = {type = "item", name = "coin"},
    text = "市场",
  })
end

local function mark_setup(market)
  storage.setup_markets = storage.setup_markets or {}
  if market.unit_number then
    storage.setup_markets[market.unit_number] = true
  end
end

local function already_setup(market)
  storage.setup_markets = storage.setup_markets or {}
  return market.unit_number and storage.setup_markets[market.unit_number] == true
end

local function setup_market(market, immortal)
  if not market or not market.valid or market.name ~= "market" then
    return nil
  end
  fill_offers(market)
  if immortal then
    market.destructible = false
    market.minable_flag = false
  end
  if not already_setup(market) then
    draw_coin_marker(market)
    add_map_tag(market)
    mark_setup(market)
  end
  return market
end

local function create_market(surface, position, immortal)
  if not surface or not surface.valid then
    return nil
  end
  position = position or {x = 5, y = 0}
  local place_at = surface.find_non_colliding_position("market", position, 64, 1) or position
  local market = surface.create_entity{
    name = "market",
    position = place_at,
    force = "player",
    create_build_effect_smoke = false,
    raise_built = false,
  }
  if not market then
    return nil
  end
  return setup_market(market, immortal ~= false)
end

local function auto_spawn_position(surface)
  local spawn = {x = 0, y = 0}
  local force = game.forces.player
  if force then
    spawn = force.get_spawn_position(surface)
  end
  return {x = spawn.x + 5, y = spawn.y}
end

local function surface_has_market_near(surface, position)
  local found = surface.find_entities_filtered{
    name = "market",
    position = position,
    radius = 12,
  }
  return found[1] ~= nil
end

local function ensure_market_on_surface(surface)
  if not settings.global["planet-market-auto-spawn"].value then
    return
  end
  if not is_planet_surface(surface) then
    return
  end
  local position = auto_spawn_position(surface)
  if surface_has_market_near(surface, position) then
    return
  end
  create_market(surface, position, true)
end

local function ensure_all_markets()
  for _, surface in pairs(game.surfaces) do
    ensure_market_on_surface(surface)
  end
end

local function disable_techs()
  if not settings.startup["planet-market-disable-techs"].value then
    return
  end
  local force = game.forces.player
  for i = 1, #DISABLED_TECHS_BASE do
    local tech = force.technologies[DISABLED_TECHS_BASE[i]]
    if tech then
      tech.enabled = false
    end
  end
  if script.active_mods["space-age"] then
    for i = 1, #DISABLED_TECHS_SPACE_AGE do
      local tech = force.technologies[DISABLED_TECHS_SPACE_AGE[i]]
      if tech then
        tech.enabled = false
      end
    end
  end
end

local function apply_speed_tweaks()
  if not settings.startup["planet-market-speed-tweaks"].value then
    return
  end
  local force = game.forces.player
  force.worker_robots_speed_modifier = 1.0
  force.character_running_speed_modifier = 0.8
  force.manual_crafting_speed_modifier = 4.0
end

local function on_init()
  storage.setup_markets = storage.setup_markets or {}
  disable_techs()
  apply_speed_tweaks()
  ensure_all_markets()
end

local function refresh_all_market_offers()
  for _, surface in pairs(game.surfaces) do
    local markets = surface.find_entities_filtered{name = "market"}
    for i = 1, #markets do
      if markets[i].valid then
        fill_offers(markets[i])
      end
    end
  end
end

local function on_configuration_changed()
  storage.setup_markets = storage.setup_markets or {}
  disable_techs()
  apply_speed_tweaks()
  ensure_all_markets()
  refresh_all_market_offers()
end

script.on_init(on_init)
script.on_configuration_changed(on_configuration_changed)

script.on_event(defines.events.on_surface_created, function(event)
  local surface = game.get_surface(event.surface_index)
  ensure_market_on_surface(surface)
end)

local built_events = {
  defines.events.on_built_entity,
  defines.events.on_robot_built_entity,
  defines.events.script_raised_built,
  defines.events.script_raised_revive,
  defines.events.on_entity_cloned,
}

if defines.events.on_space_platform_built_entity then
  built_events[#built_events + 1] = defines.events.on_space_platform_built_entity
end

script.on_event(built_events, function(event)
  local entity = event.entity or event.destination
  if entity and entity.valid and entity.name == "market" then
    setup_market(entity, false)
  end
end)

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
  if event.setting == "planet-market-auto-spawn" and settings.global["planet-market-auto-spawn"].value then
    ensure_all_markets()
  end
end)

script.on_nth_tick(3600, function()
  local amount = settings.global["planet-market-coin-amount"].value
  if amount <= 0 then
    return
  end
  for _, player in pairs(game.connected_players) do
    player.insert{name = "coin", count = amount}
  end
end)

local function require_admin(command)
  local player = command.player_index and game.get_player(command.player_index)
  if not player then
    return nil
  end
  if not player.admin then
    player.print({"planet-market.need-admin"})
    return nil
  end
  return player
end

commands.add_command("spawn-market", {"planet-market.command-spawn-help"}, function(command)
  local player = require_admin(command)
  if not player then
    return
  end
  local position
  if command.parameter and command.parameter ~= "" then
    local x, y = string.match(command.parameter, "^%s*([%-]?%d+%.?%d*)%s+([%-]?%d+%.?%d*)%s*$")
    if not x then
      player.print({"planet-market.command-spawn-help"})
      return
    end
    position = {x = tonumber(x), y = tonumber(y)}
  else
    position = {x = player.position.x, y = player.position.y}
  end
  local market = create_market(player.surface, position, true)
  if market then
    player.print({"planet-market.spawned"})
  else
    player.print({"planet-market.spawn-failed"})
  end
end)

commands.add_command("give-market", {"planet-market.command-give-help"}, function(command)
  local player = require_admin(command)
  if not player then
    return
  end
  if not player.can_insert{name = "market", count = 1} then
    player.print({"planet-market.give-failed"})
    return
  end
  player.insert{name = "market", count = 1}
  player.print({"planet-market.given"})
end)

remote.add_interface("planet-market", {
  create_market = function(surface_index, x, y, immortal)
    local surface = game.get_surface(surface_index)
    if not surface then
      return nil
    end
    local market = create_market(surface, {x = x, y = y}, immortal ~= false)
    if market then
      return market.unit_number
    end
    return nil
  end,
})
