data:extend({
  {
    type = "bool-setting",
    name = "planet-market-auto-spawn",
    setting_type = "runtime-global",
    default_value = true,
    order = "a",
  },
  {
    type = "int-setting",
    name = "planet-market-coin-amount",
    setting_type = "runtime-global",
    default_value = 1,
    minimum_value = 0,
    maximum_value = 1000,
    order = "b",
  },
  {
    type = "bool-setting",
    name = "planet-market-disable-techs",
    setting_type = "startup",
    default_value = false,
    order = "c",
  },
  {
    type = "bool-setting",
    name = "planet-market-speed-tweaks",
    setting_type = "startup",
    default_value = false,
    order = "d",
  },
})
