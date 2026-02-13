-- load all otui files, order doesn't matter
local configName = modules.game_bot.contentsPanel.config:getCurrentOption().text

local configFiles = g_resources.listDirectoryFiles("/bot/" .. configName .. "/vBot", true, false)
for i, file in ipairs(configFiles) do
  local ext = file:split(".")
  if ext[#ext]:lower() == "ui" or ext[#ext]:lower() == "otui" then
    g_ui.importStyle(file)
  end
end

local function loadScript(name)
  return dofile("/vBot/" .. name .. ".lua")
end

-- here you can set manually order of scripts
-- libraries should be loaded first
local luaFiles = {
  "main",
  "items",
  "vlib",
  "new_cavebot_lib",
  "configs", -- do not change this and above
  "extras",
  "cavebot",    
  "alarms",
  -- "Conditions",
  -- "Equipper",    
  -- "HealBot",
  "new_healer",
  "AttackBot", -- last of major modules
  "ingame_editor",
  "Dropper",
  "Containers",
  "quiver_manager",
  "quiver_label",
  "tools",
  "antiRs",
  "depot_withdraw",
  "eat_food",
  "equip",
  "exeta",
  "analyzer",
  "spy_level",
  "supplies",
  "depositer_config",
  "npc_talk",
  "xeno_menu",
  "hold_target",
  "cavebot_control_panel"
}

for i, file in ipairs(luaFiles) do
  loadScript(file)
end

setDefaultTab("Main")
UI.Separator()
UI.Label("MOT Scripts:")
UI.Separator()

local user_scripts = "/bot/" .. configName .. "/user"
if not g_resources.directoryExists(user_scripts) then
  g_resources.makeDir(user_scripts)
end

local files = g_resources.listDirectoryFiles(user_scripts, false, false)
for i, file in ipairs(files) do
  local ext = file:split(".")
  if ext[#ext]:lower() == "lua" then
    dofile("/user/" .. file)
  end
end
