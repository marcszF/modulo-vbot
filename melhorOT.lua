-- =====================================================
-- MELHOR OT - MENU SIMPLES (v1.3)
-- By: Fire
-- Data dessa versão: 20/01/2026

local rootWidget = modules.game_interface.getRootPanel()
-- =====================================================
-- ICONES
-- =====================================================
local ICONS = {
  CaveBot   = 51315,
  Target    = 55162,
  Sell      = 54995,
  Bank      = 54991,
  Stamina   = 36725,
  Bless     = 54981,
  Skill     = 54008,
  Buff      = 55350,
  Task      = 55493,
  BuffsEx   = 54457,
  Cooldown  = 54457,
  Fly       = 54457,
  MelhorOT  = 32918
}

-- =====================================================
-- CORES
-- =====================================================
local COLOR_BG     = "#000000"
local COLOR_BORDER = "#111111"
local COLOR_TEXT   = "#AAAAAA"
local COLOR_ON     = "#00FF00"

-- =====================================================
-- POSIÇÃO
-- =====================================================
local BASE_X = 410
local BASE_Y = 180
local WIDTH  = 140
local HEIGHT = 35
local GAP_Y  = 2

-- =====================================================
-- UTIL
-- =====================================================
local function bringToFront(w)
  if not w then return end
  w:raise()
  w:focus()
end

local function setState(hud, label, isOn)
  hud:setText(label .. ": " .. (isOn and "ON" or "OFF"))
  hud:setColor(isOn and COLOR_ON or COLOR_TEXT)
end

-- =====================================================
-- LIMPA HUDS ANTIGOS
-- =====================================================
for _, id in ipairs({
  "MelhorOT_Main",
  "MelhorOT_CaveBot",
  "MelhorOT_Target",
  "MelhorOT_Sell",
  "MelhorOT_Bank",
  "MelhorOT_Stamina",
  "MelhorOT_Bless",
  "MelhorOT_Skill",
  "MelhorOT_Buff",
  "MelhorOT_Task",
  "MelhorOT_BuffsExtra",
  "MelhorOT_Cooldown",
  "MelhorOT_Fly"
}) do
  local w = rootWidget:recursiveGetChildById(id)
  if w then w:destroy() end
end

-- =====================================================
-- MACROS (45 SEGUNDOS)
-- =====================================================
storage.autoStates = storage.autoStates or {
  sell = false,
  bank = false,
  stamina = false
}
local SELL_ITEM_ID    = 54995
local BANK_ITEM_ID    = 54991
local STAMINA_ITEM_ID = 36725  --  ajuste com o ID 

local sellMacro = macro(45000, function()
  use(SELL_ITEM_ID)
end)
sellMacro:setOff()

local bankMacro = macro(45000, function()
  use(BANK_ITEM_ID)
end)
bankMacro:setOff()

local staminaMacro = macro(2000, function()
  if player:getStamina() < 2401 then
    use(STAMINA_ITEM_ID)
  end
end)
staminaMacro:setOff()
-- BLESS
-- ========================
-- AUTO BLESS CONFIG (STORAGE)
-- ========================
local blessStorageName = "autoBlessItem"

if not storage[blessStorageName] then
    storage[blessStorageName] = {
        item = 54981 -- valor default
    }
end

function newBlessConfig(parent)
    local panelName = blessStorageName

    if not parent then
        parent = panel
    end

    local ui = g_ui.createWidget("DualScrollItemPanel", parent)
    ui:setId("AutoBlessConfig")

    -- SOMENTE CONFIGURAÇÃO
    ui.title:setText("Bless Item")
    ui.title:setOn(true) -- sempre ligado (não controla macro)

    ui.title.onClick = function() end -- desativa toggle

    -- ITEM
    ui.item.onItemChange = function(widget)
        storage[panelName].item = widget:getItemId()
        print("[AUTO BLESS] Bless configurada:", storage[panelName].item)
    end
    ui.item:setItemId(storage[panelName].item)

    -- VISUAL
    ui.scroll1:setVisible(false)
    ui.scroll2:setVisible(false)

    return ui
end

newBlessConfig()
-- LÓGICA DA BLESS
-- ========================
local COOLDOWN_TIME = 31 -- segundos

local blessDone = false
local waitingResponse = false
local lastUseTime = 0

-- ========================
-- SERVER LOG DETECTOR
-- ========================
onTextMessage(function(mode, text)
    local msg = text:lower()

    if msg:find("Você ja tem todas as blesses.")
    or msg:find("Agora você está 100% protegido com todas as blesses.") then
        print("[AUTO BLESS] Bless confirmada pelo servidor.")
        blessDone = true
        waitingResponse = false
    end
end)

-- ========================
-- MAIN MACRO
-- ========================
blessMacro = macro(1000, function()
    if blessDone then return end
    if not g_game.isOnline() then return end

    local blessItem = storage.autoBlessItem.item
    if not blessItem or blessItem == 0 then return end

    local now = os.time()

    if now - lastUseTime < COOLDOWN_TIME then return end
    if waitingResponse then return end

    print("[AUTO BLESS] Usando item de bless...")
    lastUseTime = now
    waitingResponse = true
    use(blessItem)

    schedule(3000, function()
        waitingResponse = false
    end)
end)
-- ========================
-- RESET AO DESLOGAR
-- ========================
macro(1000, function()
  if not g_game.isOnline() then
    blessDone = false
    waitingResponse = false
    lastUseTime = 0

  end
end)

------------------------------------------------------------------------------------------------------------
-- =====================================================
-- TASK
-- =====================================================
local taskOn = false
local taskCurrent = 0
local taskTotal = 0

local taskMacro = macro(1000, function()
  if not taskOn then return end
  say("!taskrenew")
end)
-- taskOn = taskMacro:isOn()
onTextMessage(function(mode, text)
  if not taskOn then return end
  if not text:lower():find("progresso") then return end

  local current, total = text:match("(%d+)%s*/%s*(%d+)")
  if current and total then
    taskCurrent = tonumber(current)
    taskTotal = tonumber(total)
  end
end)
-- =====================================================
-- CONFIGURAÇÃO DE SKILLS
-- =====================================================


local labelSpells = UI.Label("SPELLS")
  labelSpells:setColor("#FFFF00")
local spellOn = false
addTextEdit("Spell1", storage.Spell1 or "Digite a magia 1", function(widget, text)
    storage.Spell1 = text
end)

addTextEdit("Spell2", storage.Spell2 or "Digite a magia 2", function(widget, text)
    storage.Spell2 = text
end)
local spellMacro = macro(1000, function()    
    if not g_game.isAttacking() then return end

    if storage.Spell1 and storage.Spell1 ~= "" then
        say(storage.Spell1)
    end

    if storage.Spell2 and storage.Spell2 ~= "" then
        say(storage.Spell2)
    end    
end)

UI.Separator()
local labelBuffs = UI.Label("Buffs")
  labelBuffs:setColor("#FFFF00")
local buffOn = false

local buffMacro = macro(1100, function()
    if not g_game.isAttacking() then return end
    if not storage.BuffSpell or storage.BuffSpell == "" then return end

    say(storage.BuffSpell)
end)
addTextEdit("Buff Spell", storage.BuffSpell or "Digite o buff", function(widget, text)
    storage.BuffSpell = text
end)

-- =====================================================
-- HUD PRINCIPAL
-- =====================================================
local mainHud = g_ui.createWidget("UIButton", rootWidget)
mainHud:setId("MelhorOT_Main")
mainHud:setPosition({x=BASE_X, y=BASE_Y})
mainHud:setSize({width=WIDTH, height=HEIGHT})
mainHud:setText("MELHOR OT")
mainHud:setFont("terminus-14px-bold")
mainHud:setColor("#F3F500")
mainHud:setBackgroundColor(COLOR_BG)
mainHud:setBorderWidth(1)
mainHud:setBorderColor(COLOR_BORDER)
mainHud:setDraggable(true)

-- =====================================================
-- LOGO DO MENU
-- =====================================================

local logoBox = g_ui.createWidget("UIWidget", mainHud)
logoBox:setSize({ width = 36, height = 36 })
logoBox:setPosition({ x = 4, y = 2 })
logoBox:setFocusable(false)
logoBox:setPhantom(true)

local logoItem = g_ui.createWidget("UIItem", logoBox)
logoItem:setItemId(ICONS.MelhorOT)
logoItem:setSize({ width = 32, height = 32 })
logoItem:setPosition({ x = 2, y = 2 })
logoItem:setVirtual(true)


bringToFront(mainHud)

-- =====================================================
-- FUNÇÃO CRIAR HUD BOTÃO
-- =====================================================
local function createButton(id, label, iconId, index, onClick)
  local hud = g_ui.createWidget("UIButton", rootWidget)
  hud:setId(id)
  hud:setPosition({x=BASE_X, y=BASE_Y + (HEIGHT + GAP_Y) * index})
  hud:setSize({width=WIDTH, height=HEIGHT})
  hud:setFont("verdana-11px-rounded")
  hud:setBackgroundColor(COLOR_BG)
  hud:setBorderWidth(1)
  hud:setBorderColor(COLOR_BORDER)
  hud:setVisible(false)
  hud.onClick = onClick
  hud:setText(label) -- TEXTO NÃO MUDA

  -- CONTAINER DO ÍCONE (posição fixa)
  local iconBox = g_ui.createWidget("UIWidget", hud)
  iconBox:setSize({width = 36, height = 36})
  iconBox:setPosition({x = 4, y = 2})
  iconBox:setFocusable(false)
  iconBox:setPhantom(true) -- não captura clique

  -- ÍCONE
  local icon = g_ui.createWidget("UIItem", iconBox)
  icon:setItemId(iconId)
  icon:setSize({width = 32, height = 32})
  icon:setPosition({x = 2, y = 2})
  icon:setVirtual(true)

  return hud
end

-- =====================================================
-- CRIA BOTÕES
-- =====================================================
local caveHud = createButton("MelhorOT_CaveBot", "CaveBot", ICONS.CaveBot, 1, function()
  if CaveBot.isOn() then CaveBot.setOff() else CaveBot.setOn() end
end)

local targetHud = createButton("MelhorOT_Target", "Target", ICONS.Target, 2, function()
  if TargetBot.isOn() then TargetBot.setOff() else TargetBot.setOn() end
end)

local sellHud = createButton("MelhorOT_Sell", "Sell", ICONS.Sell, 3, function()
  if sellMacro:isOn() then
    sellMacro:setOff()
    storage.autoStates.sell = false
  else
    sellMacro:setOn()
    storage.autoStates.sell = true
  end
end)

local bankHud = createButton("MelhorOT_Bank", "Bank",ICONS.Bank, 4, function()
  if bankMacro:isOn() then
    bankMacro:setOff()
    storage.autoStates.bank = false
  else
    bankMacro:setOn()
    storage.autoStates.bank = true
  end
end)

local staminaHud = createButton("MelhorOT_Stamina", "Stamina", ICONS.Stamina, 5, function()
  if staminaMacro:isOn() then
    staminaMacro:setOff()
    storage.autoStates.stamina = false
  else
    staminaMacro:setOn()
    storage.autoStates.stamina = true
  end
end)

local blessHud = createButton("MelhorOT_Bless", "Bless", ICONS.Bless, 6, function()
  if blessMacro:isOn() then
    blessEnabled = false
    blessMacro:setOff()
    
    print("[AUTO BLESS] Desativado.")
  else
    blessEnabled = true
    blessMacro:setOn()
    
    executeAutoBless()
    print("[AUTO BLESS] Ativado.")
  end
end)

local skillHud = createButton("MelhorOT_Skill", "Skill", ICONS.Skill, 8, function()
  if spellMacro:isOn() then spellMacro:setOff() else spellMacro:setOn() end  
end)

local buffHudSpell = createButton("MelhorOT_Buff", "Buff", ICONS.Buff, 9, function()
    if buffMacro:isOn() then buffMacro:setOff() else buffMacro:setOn() end
end)

local taskHud = createButton("MelhorOT_Task", "Task", ICONS.Task, 7, function()
  taskOn = not taskOn
  taskMacro:setOn(taskOn)
end)

local buffsHud = createButton("MelhorOT_BuffsExtra", "Buffs Extra",ICONS.BuffsEx, 11, function()
  say("!buffsextra")
end)

local cooldownHud = createButton("MelhorOT_Cooldown", "Cooldown", ICONS.Cooldown, 12, function()
  say("!cooldown")
end)

local flyHud = createButton("MelhorOT_Fly", "Fly", ICONS.Fly, 10, function()
  say("!fly")
end)

macro(1000, function()
  if g_game.isOnline() then
    if storage.autoStates.sell and not sellMacro:isOn() then
      sellMacro:setOn()
    end

    if storage.autoStates.bank and not bankMacro:isOn() then
      bankMacro:setOn()
    end

    if storage.autoStates.stamina and not staminaMacro:isOn() then
      staminaMacro:setOn()
    end
  end
end)


-- =====================================================
-- SINCRONIZA TEXTO E COR
-- =====================================================
macro(1500, function()
  setState(caveHud,    "CaveBot",  CaveBot.isOn())
  setState(targetHud,  "Target",   TargetBot.isOn())
  setState(sellHud,    "Sell",     sellMacro:isOn())
  setState(bankHud,    "Bank",     bankMacro:isOn())
  setState(staminaHud, "Stamina",  staminaMacro:isOn())
  setState(blessHud,   "Bless",    blessMacro:isOn())
  if taskOn then
    taskHud:setText("Task: " .. taskCurrent .. "/" .. taskTotal)
    taskHud:setColor(COLOR_ON)
  else
    taskHud:setText("Task: OFF")
    taskHud:setColor(COLOR_TEXT)
  end
  setState(skillHud, "Skill", spellMacro:isOn())
  setState(buffHudSpell, "Buff", buffMacro:isOn())
    buffsHud:setText("Buffs Extra")
    buffsHud:setColor(COLOR_TEXT)

    cooldownHud:setText("Cooldown")
    cooldownHud:setColor(COLOR_TEXT)

    flyHud:setText("Fly")
    flyHud:setColor(COLOR_TEXT)

end)

-- =====================================================
-- TOGGLE MENU
-- =====================================================
local menuOpen = false

mainHud.onClick = function()
  menuOpen = not menuOpen

  caveHud:setVisible(menuOpen)
  targetHud:setVisible(menuOpen)
  sellHud:setVisible(menuOpen)
  bankHud:setVisible(menuOpen)
  staminaHud:setVisible(menuOpen)
  blessHud:setVisible(menuOpen)
  skillHud:setVisible(menuOpen)
  buffHudSpell:setVisible(menuOpen)
  taskHud:setVisible(menuOpen)
  buffsHud:setVisible(menuOpen)
  cooldownHud:setVisible(menuOpen)
  flyHud:setVisible(menuOpen)

  bringToFront(caveHud)
  bringToFront(targetHud)
  bringToFront(sellHud)
  bringToFront(bankHud)
  bringToFront(staminaHud)
  bringToFront(blessHud)
  bringToFront(skillHud)
  bringToFront(taskHud)
  bringToFront(buffsHud)
  bringToFront(cooldownHud)
  bringToFront(flyHud)

end
UI.Separator()
UI.Label("RUNES")
function newAttackItem(parent)
    local panelName = "newAttackItem"
    if not parent then
        parent = panel
    end

    local ui = g_ui.createWidget("DualScrollItemPanel", parent)
    ui:setId(panelName) 

    if not storage[panelName] then
        storage[panelName] = {
            item = 3155,
            enabled = false
        }
    end

    -- TOGGLE ON / OFF
    ui.title:setOn(storage[panelName].enabled)
    ui.title.onClick = function(widget)
        storage[panelName].enabled = not storage[panelName].enabled
        widget:setOn(storage[panelName].enabled)
    end

    -- ITEM
    ui.item.onItemChange = function(widget)
        storage[panelName].item = widget:getItemId()
    end
    ui.item:setItemId(storage[panelName].item)

    -- TEXTO FIXO
    ui.title:setText("Auto Rune")

    -- DESATIVA SCROLLS (opcional, visual)
    ui.scroll1:setVisible(false)
    ui.scroll2:setVisible(false)

    -- MACRO A CADA 1000ms
    macro(500, function()
        if not storage[panelName].enabled then
            return
        end

        local target = g_game.getAttackingCreature()
        if not target then
            return
        end

        useWith(storage[panelName].item, target)
    end)
end

newAttackItem()


-- ========================
-- HEALS
-- ========================
setDefaultTab("HP")
UI.Label("Heal Spells")
if type(storage.healing1) ~= "table" then
    storage.healing1 = {on=false, title="HP%", text="Digite sua magia", min=51, max=90}
end
if type(storage.healing2) ~= "table" then
  storage.healing2 = {on=false, title="HP%", text="exura vita", min=0, max=50}
end
for _, healingInfo in ipairs({storage.healing1, storage.healing2}) do
  local healingmacro = macro(500, function()
    local hp = player:getHealthPercent()
    if healingInfo.max >= hp and hp >= healingInfo.min then
      if TargetBot then 
        TargetBot.saySpell(healingInfo.text) -- sync spell with targetbot if available
      else
        say(healingInfo.text)
      end
    end
  end)
  healingmacro.setOn(healingInfo.on)

  UI.DualScrollPanel(healingInfo, function(widget, newParams) 
    healingInfo = newParams
    healingmacro.setOn(healingInfo.on)
  end)
end
UI.Separator()
UI.Label("Mana & Health Potions/Runes")

if type(storage.hpitem1) ~= "table" then
  storage.hpitem1 = {on=false, title="HP%", item=266, min=51, max=90}
end
if type(storage.hpitem2) ~= "table" then
  storage.hpitem2 = {on=false, title="HP%", item=3160, min=0, max=50}
end
if type(storage.manaitem1) ~= "table" then
  storage.manaitem1 = {on=false, title="MP%", item=268, min=51, max=90}
end
if type(storage.manaitem2) ~= "table" then
  storage.manaitem2 = {on=false, title="MP%", item=3157, min=0, max=50}
end
for i, healingInfo in ipairs({storage.hpitem1, storage.hpitem2, storage.manaitem1, storage.manaitem2}) do
  local healingmacro = macro(200, function()
    local hp = i <= 2 and player:getHealthPercent() or math.min(100, math.floor(100 * (player:getMana() / player:getMaxMana())))
    if healingInfo.max >= hp and hp >= healingInfo.min then
      if TargetBot then 
        TargetBot.useItem(healingInfo.item, healingInfo.subType, player) -- sync spell with targetbot if available
      else
        local thing = g_things.getThingType(healingInfo.item)
        local subType = g_game.getClientVersion() >= 860 and 0 or 1
        if thing and thing:isFluidContainer() then
          subType = healingInfo.subType
        end
        g_game.useInventoryItemWith(healingInfo.item, player, subType)
      end
    end
  end)
  healingmacro.setOn(healingInfo.on)

  UI.DualScrollItemPanel(healingInfo, function(widget, newParams) 
    healingInfo = newParams
    healingmacro.setOn(healingInfo.on and healingInfo.item > 100)
  end)
end
UI.Label("Haste spell:")
UI.TextEdit(storage.hasteSpell or "utani hur", function(widget, newText)
  storage.hasteSpell = newText
end)
macro(1000, "haste", function() 
  if hasHaste() then return end
  if TargetBot then 
    TargetBot.saySpell(storage.hasteSpell) -- sync spell with targetbot if available
  else
    say(storage.hasteSpell)
  end
end)

-- Hunting Tasks Auto-Renew for vBot
-- Place in: MelhorOT/hunting.lua
-- Full automation: select, upgrade, collect, renew

setDefaultTab("Tools")

if not storage.huntingPreferred then
  storage.huntingPreferred = {"", "", ""}
end

local PREY_HUNTING_ACTION_LISTREROLL = 0
local PREY_HUNTING_ACTION_BONUSREROLL = 1
local PREY_HUNTING_ACTION_SELECT_WILDCARD = 2
local PREY_HUNTING_ACTION_SELECT = 3
local PREY_HUNTING_ACTION_COLLECT = 5

local ACTION_COOLDOWN = 8000
local MSG_DEBOUNCE = 6000

local lastActionTime = {}
local lastMsgText = ""
local lastMsgTime = 0
local nextAllowedAttempt = {0, 0, 0}

local lastActionSlot = nil
local lastActionType = nil

local function nowMillis()
  if g_clock and g_clock.millis then return g_clock.millis() end
  return os.time() * 1000
end

local function extractWaitMinutes(text)
  local m = text:match("wait%s+(%d+)%s+minutes")
  return tonumber(m)
end

local function getHuntingModule()
  return modules.game_prey_hunting
end

local function canDoAction(slot, action)
  local key = slot .. "_" .. action
  local now = nowMillis()
  if lastActionTime[key] and (now - lastActionTime[key] < ACTION_COOLDOWN) then
    return false
  end
  return true
end

local function setActionTime(slot, action)
  local key = slot .. "_" .. action
  lastActionTime[key] = nowMillis()
end

local function getSlotInfo(slot)
  local mod = getHuntingModule()
  if not mod then return {state = "NO_MODULE"} end

  local idx = slot
  local info = {state = "UNKNOWN", stars = 0, killed = 0, toKill = 0, completed = false}

  if mod.exhaustEndTime and mod.exhaustEndTime[idx] then
    local remaining = mod.exhaustEndTime[idx] - os.time()
    if remaining > 0 then
      info.state = "EXHAUSTED"
      return info
    end
  end

  local hasActiveMonster = mod.activeMonsterList and mod.activeMonsterList[idx]

  if mod.selectedMonster and mod.selectedMonster[idx] and hasActiveMonster then
    local data = mod.selectedMonster[idx]
    info.state = "ACTIVE"
    info.stars = data.grade or 0
    info.killed = data.currentKills or 0
    info.toKill = data.maxKills or 0
    info.completed = (info.killed >= info.toKill and info.toKill > 0)
    return info
  end

  if hasActiveMonster then
    info.state = "ACTIVE"
    return info
  end

  if mod.currentWildcardList and mod.currentWildcardList[idx] then
    info.state = "WILDCARD"
    return info
  end

  if mod.currentMonsterList and mod.currentMonsterList[idx] then
    info.state = "SELECT"
    return info
  end

  return info
end

local function getMonsterList(slot)
  local mod = getHuntingModule()
  if not mod then return nil end
  local idx = slot
  if mod.currentWildcardList and mod.currentWildcardList[idx] then
    return mod.currentWildcardList[idx]
  end
  return mod.currentMonsterList and mod.currentMonsterList[idx]
end

local function getMonsterName(raceId)
  if g_things and g_things.getRaceData then
    local data = g_things.getRaceData(raceId)
    if data and data.name then return data.name end
  end
  return nil
end

local function findMonsterByName(searchName, monsterList)
  if not searchName or searchName == "" then return nil end
  if not monsterList then return nil end

  local searchLower = searchName:lower()
  local partialMatch, partialBestiary = nil, nil

  for raceId, bestiaryUnlocked in pairs(monsterList) do
    local name = getMonsterName(raceId)
    if name then
      local nameLower = name:lower()
      if nameLower == searchLower then
        return raceId, bestiaryUnlocked
      end
      if not partialMatch and nameLower:find(searchLower, 1, true) then
        partialMatch = raceId
        partialBestiary = bestiaryUnlocked
      end
    end
  end

  return partialMatch, partialBestiary
end

local function formatSeconds(sec)
  if not sec or sec <= 0 then return "ready" end
  local m = math.floor(sec / 60)
  local s = math.floor(sec % 60)
  return string.format("%dm%02ds", m, s)
end

-- ===== UI =====
UI.Separator()
UI.Label("Hunting Tasks - Full Auto")
UI.Separator()

UI.Label("Nome dos Monstros:")

UI.Label("Slot 1:")
UI.TextEdit(storage.huntingPreferred[1] or "", function(widget, text)
  storage.huntingPreferred[1] = text
end)

UI.Label("Slot 2:")
UI.TextEdit(storage.huntingPreferred[2] or "", function(widget, text)
  storage.huntingPreferred[2] = text
end)

UI.Label("Slot 3:")
UI.TextEdit(storage.huntingPreferred[3] or "", function(widget, text)
  storage.huntingPreferred[3] = text
end)

UI.Separator()

local statusLabels = {}
for i = 1, 3 do
  statusLabels[i] = UI.Label("Slot " .. i .. ": ...")
end

-- ✅ correção 2: local (não global)
local renewButtons = {}

local function updateStatusLabels()
  for i = 1, 3 do
    local info = getSlotInfo(i)
    local preferred = storage.huntingPreferred[i] or ""
    local statusText = "Slot " .. i .. ": " .. info.state

    if info.state == "ACTIVE" then
      statusText = statusText .. " (" .. info.killed .. "/" .. info.toKill .. ") *" .. info.stars
      if info.completed then statusText = statusText .. " DONE!" end
    end

    if preferred ~= "" then
      statusText = statusText .. " [" .. preferred .. "]"
    end

    statusLabels[i]:setText(statusText)

    -- ✅ correção 6: fallback de tempo no botão
    if renewButtons[i] then
      local mod = getHuntingModule()
      local remaining = 0
      if mod and mod.exhaustEndTime and mod.exhaustEndTime[i] then
        remaining = mod.exhaustEndTime[i] - os.time()
      end
      if remaining <= 0 and nextAllowedAttempt[i] then
        remaining = math.floor((nextAllowedAttempt[i] - nowMillis()) / 1000)
      end
      renewButtons[i]:setText("Renew Slot " .. i .. " (" .. formatSeconds(remaining) .. ")")
    end
  end
end

UI.Separator()

renewButtons[1] = UI.Button("Renew Slot 1 (ready)", function()
  lastActionSlot = 1
  lastActionType = "renew"
  setActionTime(1, "renew")
  g_game.taskHuntingAction(0, PREY_HUNTING_ACTION_LISTREROLL, false, 0)
  warn("[Hunting] Renew manual Slot 1")
end)

renewButtons[2] = UI.Button("Renew Slot 2 (ready)", function()
  lastActionSlot = 2
  lastActionType = "renew"
  setActionTime(2, "renew")
  g_game.taskHuntingAction(1, PREY_HUNTING_ACTION_LISTREROLL, false, 0)
  warn("[Hunting] Renew manual Slot 2")
end)

renewButtons[3] = UI.Button("Renew Slot 3 (ready)", function()
  lastActionSlot = 3
  lastActionType = "renew"
  setActionTime(3, "renew")
  g_game.taskHuntingAction(2, PREY_HUNTING_ACTION_LISTREROLL, false, 0)
  warn("[Hunting] Renew manual Slot 3")
end)

UI.Separator()

-- ✅ correção 4: sempre fecha popup (sem debounce que bloqueava mensagens legítimas)
local function shouldCloseMessage(titleText, contentText)
  if titleText ~= "Information" then return false end
  local isHunting = contentText:find("Hunting Task") or contentText:find("empty task")
  local isError = contentText:find("error while processing")
  local isWait = contentText:find("wait") and contentText:find("minutes") and contentText:find("task")
  if not (isHunting or isError or isWait) then return false end

  if isWait then
    local minutes = extractWaitMinutes(contentText)
    if minutes then
      local untilTime = nowMillis() + (minutes * 60 * 1000) + 15000
      if lastActionSlot then
        nextAllowedAttempt[lastActionSlot] = math.max(nextAllowedAttempt[lastActionSlot] or 0, untilTime)
        warn("[Hunting] Wait " .. minutes .. "min aplicado ao slot " .. lastActionSlot)
      else
        for i = 1, 3 do
          nextAllowedAttempt[i] = math.max(nextAllowedAttempt[i] or 0, untilTime)
        end
      end
    end
  end

  return true
end

-- ✅ correção 3 e 8: retorna true se fez ação + prioridade collect > upgrade
local function processSlot(slot)
  if nextAllowedAttempt[slot] and nowMillis() < nextAllowedAttempt[slot] then
    return false
  end

  local info = getSlotInfo(slot)
  local preferred = storage.huntingPreferred[slot] or ""

  -- ✅ correção 8: collect PRIMEIRO (prioridade máxima)
  if info.state == "ACTIVE" and info.completed then
    if canDoAction(slot, "collect") then
      lastActionSlot = slot
      lastActionType = "collect"
      g_game.taskHuntingAction(slot - 1, PREY_HUNTING_ACTION_COLLECT, false, 0)
      setActionTime(slot, "collect")
      warn("[Hunting] Collecting reward from Slot " .. slot)
      return true
    end
  end

  -- upgrade DEPOIS do collect
  if info.state == "ACTIVE" and info.stars < 5 and not info.completed then
    if canDoAction(slot, "upgrade") then
      lastActionSlot = slot
      lastActionType = "upgrade"
      g_game.taskHuntingAction(slot - 1, PREY_HUNTING_ACTION_BONUSREROLL, false, 0)
      setActionTime(slot, "upgrade")
      warn("[Hunting] Upgrading Slot " .. slot .. " from " .. info.stars .. " stars")
      return true
    end
  end

  if info.state == "WILDCARD" and preferred ~= "" then
    if canDoAction(slot, "select") then
      local monsterList = getMonsterList(slot)
      local raceId, bestiaryUnlocked = findMonsterByName(preferred, monsterList)
      if raceId then
        local useBestiary = (bestiaryUnlocked == 1)
        lastActionSlot = slot
        lastActionType = "select"
        g_game.taskHuntingAction(slot - 1, PREY_HUNTING_ACTION_SELECT, useBestiary, raceId)
        setActionTime(slot, "select")
        warn("[Hunting] Selected '" .. preferred .. "' in Slot " .. slot)
        return true
      end
    end
  end

  if info.state == "SELECT" and preferred ~= "" then
    if canDoAction(slot, "wildcard") then
      lastActionSlot = slot
      lastActionType = "wildcard"
      g_game.taskHuntingAction(slot - 1, PREY_HUNTING_ACTION_SELECT_WILDCARD, false, 0)
      setActionTime(slot, "wildcard")
      warn("[Hunting] Opening wildcard for Slot " .. slot)
      return true
    end
  end

  return false
end

macro(2000, "Ativar Hunting", function()
  updateStatusLabels()
  if not g_game.isOnline() then return end

  local root = g_ui.getRootWidget()
  if root then
    for _, child in pairs(root:getChildren()) do
      if child.ok and child.title then
        local titleWidget = child:getChildById('title')
        local contentWidget = child:getChildById('content')
        if titleWidget and contentWidget then
          local titleText = titleWidget:getText() or ""
          local contentText = contentWidget:getText() or ""
          if shouldCloseMessage(titleText, contentText) then
            child:ok()
          end
        end
      end
    end
  end

  -- ✅ correção 3: processa só 1 slot por ciclo
  for slot = 1, 3 do
    if processSlot(slot) then
      return
    end
  end
end)

-- ✅ correção 7: removido schedule(1000, updateStatusLabels) — já roda no macro

macro(5000, "Auto Reconnect", function()
    if g_game.isOnline() then return end
    local root = g_ui.getRootWidget()
    if root then
        local msgBox = root:recursiveGetChildById('msgBox')
        if msgBox then msgBox:destroy() end
    end
    if EnterGame and EnterGame.doLogin then EnterGame.doLogin()
    else if EnterGame then EnterGame.show() end end
end)

UI.Separator()

-- LISTA DE ITENS DE TRAP
local trapItems = {2981, 2982, 2983, 2984, 2985, 3503, 3504, 1738, 1739, 2314, 2743}

-- TABELA PARA CONTAR TENTATIVAS
local attemptCounter = {}
local lastClean = os.time()

macro(200, "Anti-Trap", function()
    local player = g_game.getLocalPlayer()
    if not player then return end
    
    local playerPos = player:getPosition()
    local dir = player:getDirection() -- 0=N, 1=E, 2=S, 3=W

    if os.time() - lastClean > 5 then
        attemptCounter = {}
        lastClean = os.time()
    end

    local backTiles = {}
    if dir == 0 then     -- Olhando Norte (Joga para Sul y+1)
        backTiles = {{x=playerPos.x-1, y=playerPos.y+1, z=playerPos.z}, {x=playerPos.x, y=playerPos.y+1, z=playerPos.z}, {x=playerPos.x+1, y=playerPos.y+1, z=playerPos.z}}
    elseif dir == 1 then -- Olhando Leste (Joga para Oeste x-1)
        backTiles = {{x=playerPos.x-1, y=playerPos.y-1, z=playerPos.z}, {x=playerPos.x-1, y=playerPos.y, z=playerPos.z}, {x=playerPos.x-1, y=playerPos.y+1, z=playerPos.z}}
    elseif dir == 2 then -- Olhando Sul (Joga para Norte y-1)
        backTiles = {{x=playerPos.x-1, y=playerPos.y-1, z=playerPos.z}, {x=playerPos.x, y=playerPos.y-1, z=playerPos.z}, {x=playerPos.x+1, y=playerPos.y-1, z=playerPos.z}}
    elseif dir == 3 then -- Olhando Oeste (Joga para Leste x+1)
        backTiles = {{x=playerPos.x+1, y=playerPos.y-1, z=playerPos.z}, {x=playerPos.x+1, y=playerPos.y, z=playerPos.z}, {x=playerPos.x+1, y=playerPos.y+1, z=playerPos.z}}
    end

    for x = -1, 1 do
        for y = -1, 1 do
            -- Pula o próprio pé (x=0, y=0)
            if x ~= 0 or y ~= 0 then
                local tilePos = {x = playerPos.x + x, y = playerPos.y + y, z = playerPos.z}
                local tile = g_map.getTile(tilePos)
                
                if tile then
                    local items = tile:getItems()
                    if items then
                        for _, item in ipairs(items) do
                            -- Se achar item da lista
                            if table.find(trapItems, item:getId()) then
                                
                                -- Cria chave única para o piso
                                local posKey = tilePos.x .. "," .. tilePos.y
                                local attempts = attemptCounter[posKey] or 0

                                if attempts < 3 then
                                    local randomBack = backTiles[math.random(1, #backTiles)]
                                    g_game.move(item, randomBack, item:getCount())
                                    
                                    attemptCounter[posKey] = attempts + 1
                                    return -- Sai para processar
                                else
                                    g_game.move(item, {x=65535, y=3, z=0}, item:getCount())
                                    return
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

UI.Separator()

-- CONFIGURAÇÕES
local wallId = 2129         -- ID da Magic Wall da magia
local scanRadius = 6        -- Raio para detectar a parede
local ignoreList = {"NomeAmigo1", "NomeAmigo2", "Marcsz"} -- Nomes para NÃO atacar

macro(200, "Auto Attack on Trap", function()
    local player = g_game.getLocalPlayer()
    if not player then return end
    
    local pos = player:getPosition()
    local isTrapped = false


    for x = -scanRadius, scanRadius do
        for y = -scanRadius, scanRadius do
            local tile = g_map.getTile({x = pos.x + x, y = pos.y + y, z = pos.z})
            
            if tile then
                local items = tile:getItems()
                if items then
                    for _, item in ipairs(items) do
                        if item:getId() == wallId then
                            isTrapped = true
                            break
                        end
                    end
                end
            end
            
            if isTrapped then break end
        end
        if isTrapped then break end
    end

    if not isTrapped then return end

    local spectators = g_map.getSpectators(pos, false)
    local targetCreature = nil
    local closestDist = 999

    for _, creature in ipairs(spectators) do
        if creature:isPlayer() and creature ~= player then
            local name = creature:getName()
            
            -- Verifica se NÃO está na lista de amigos
            local isFriend = false
            for _, friendName in ipairs(ignoreList) do
                if name == friendName then
                    isFriend = true
                    break
                end
            end

            if not isFriend then
                local cPos = creature:getPosition()
                local dist = math.max(math.abs(pos.x - cPos.x), math.abs(pos.y - cPos.y))
                
                if dist < closestDist then
                    closestDist = dist
                    targetCreature = creature
                end
            end
        end
    end

    if targetCreature then
        if g_game.getAttackingCreature() ~= targetCreature then
            g_game.attack(targetCreature)
        end
    end
end)

-- PK/PKRed/PKBlack detector: ativa PvP, ataca e pausa bots (HOLD target)

local SKULL_WHITE = 3
local SKULL_RED   = 4
local SKULL_BLACK = 5

local pkDetected = false
local currentPk = nil
local lastSeenTime = 0
local HOLD_TIMEOUT = 2000 -- tempo sem ver PK para liberar

local function nowMillis()
  if g_clock and g_clock.millis then return g_clock.millis() end
  return os.time() * 1000
end

local function enablePvp()
  if g_game.setSafeFight then g_game.setSafeFight(false) end
end

local function disablePvp()
  if g_game.setSafeFight then g_game.setSafeFight(true) end
end

local function stopBots()
  if CaveBot and CaveBot.setOff then CaveBot.setOff() end
  if TargetBot and TargetBot.setOff then TargetBot.setOff() end
end

local function startBots()
  if CaveBot and CaveBot.setOn then CaveBot.setOn() end
  if TargetBot and TargetBot.setOn then TargetBot.setOn() end
end

local function findPk()
  local spectators = g_map.getSpectators(pos(), false)
  for _, creature in ipairs(spectators) do
    if creature:isPlayer() then
      local skull = creature.getSkull and creature:getSkull() or 0
      if skull == SKULL_WHITE or skull == SKULL_RED or skull == SKULL_BLACK then
        return creature
      end
    end
  end
  return nil
end

macro(200, "PK Alert Hold", function()
  local pk = findPk()
  local now = nowMillis()

  if pk then
    lastSeenTime = now
    if not pkDetected then
      pkDetected = true
      currentPk = pk
      stopBots()
      enablePvp()
    else
      -- mantém o mesmo alvo se já existe
      if currentPk and currentPk ~= pk then
        currentPk = pk
      end
    end

    if currentPk then
      local attacking = g_game.getAttackingCreature and g_game.getAttackingCreature()
      if attacking ~= currentPk then
        g_game.attack(currentPk)
      end
    end

  else
    if pkDetected and (now - lastSeenTime) > HOLD_TIMEOUT then
      pkDetected = false
      currentPk = nil
      if g_game.cancelAttack then g_game.cancelAttack() end
      disablePvp()
      startBots()
    end
  end
end)

-- ========================
-- BALANCE
-- ========================

-- Balance tracker (Server Log) + encurtador k/kk/kkk
setDefaultTab("Main")

local BAL_CMD = "!balance"
local lastBalance = nil
local startBalance = nil
local startTime = now

local balanceLabel = UI.Label("Balance: ...")
local rateLabel = UI.Label("Rate/h: ...")

UI.Button("Reset Balance", function()
  lastBalance = nil
  startBalance = nil
  startTime = now
  balanceLabel:setText("Balance: ...")
  rateLabel:setText("Rate/h: ...")
  warn("[Balance] Resetado")
end)

local function shortenK(n)
  if not n then return "0" end
  local suffix = ""
  local v = n

  while v >= 1000 do
    v = v / 1000
    suffix = suffix .. "k"
  end

  local s = string.format("%.2f", v)
  s = s:gsub("%.?0+$", "")
  return s .. suffix
end

local function parseBalance(text)
  local n = text:match("balance is%s+([%d,]+)")
  if not n then return nil end
  n = n:gsub(",", "")
  return tonumber(n)
end

-- envia comando a cada 30s
macro(30000, "Auto Balance", function()
  if g_game.isOnline() then
    say(BAL_CMD)
  end
end)

onTextMessage(function(mode, text)
  local bal = parseBalance(text)
  if not bal then return end

  lastBalance = bal
  if not startBalance then
    startBalance = bal
    startTime = now
  end

  local elapsedHours = math.max((now - startTime) / (1000 * 60 * 60), 0.0001)
  local diff = bal - startBalance
  local rate = diff / elapsedHours

  balanceLabel:setText("Balance: " .. shortenK(bal))
  rateLabel:setText("Rate/h: " .. shortenK(rate))
end)