setDefaultTab("Main")

-- CONFIGURAÇÃO
storage.trainItemId = storage.trainItemId or 0
storage.dummyId = storage.dummyId or 0

addLabel("lbl1", "Treinar no Dummy (PZ)")
addSeparator()

addTextEdit("itemId", storage.trainItemId, function(widget, text)
    storage.trainItemId = tonumber(text)
end)
addLabel("lblItem", "ID ARMA")

addTextEdit("dummyId", storage.dummyId, function(widget, text)
    storage.dummyId = tonumber(text)
end)
addLabel("lblDummy", "ID DUMMY")

addSeparator()

macro(300, "Usar item no Dummy", function()
    -- Verifica PZ
    if not isInPz() then return end

    -- Verifica item
    local item = findItem(storage.trainItemId)
    if not item then
        print("Item acabou, macro desligado.")
        return false
    end

    -- Procura dummy na tela
    for _, tile in pairs(g_map.getTiles(posz())) do
        local top = tile:getTopUseThing()
        if top and top:getId() == storage.dummyId then
            useWith(storage.trainItemId, top)
            return
        end
    end
end)

setDefaultTab("Tools")
UI.Separator()

local banheira = macro(5000, "Entrar Banheira", function(m)
    local player = g_game.getLocalPlayer()
    local staminaMax = 2520 -- 42 horas
    local playerPos = player:getPosition()
    
    if not isInPz() then return end

    -- 1. VERIFICAÇÃO: SE JÁ ESTIVER NA BANHEIRA (STAMINA CHEIA) -> SAIR
    if player:getStamina() >= staminaMax then
        local standingTile = g_map.getTile(playerPos)
        if standingTile then
            for _, item in ipairs(standingTile:getItems()) do
                -- Se estou em cima da banheira/orb e a stamina encheu
                if item:getId() == 54091 or item:getId() == 54000 then
                    local directions = {
                        {x = 0, y = 1}, {x = 0, y = -1}, {x = 1, y = 0}, {x = -1, y = 0},
                        {x = 1, y = 1}, {x = 1, y = -1}, {x = -1, y = 1}, {x = -1, y = -1}
                    }
                    for _, dir in ipairs(directions) do
                        local targetPos = {x = playerPos.x + dir.x, y = playerPos.y + dir.y, z = playerPos.z}
                        local tile = g_map.getTile(targetPos)
                        if tile and tile:isWalkable() and #tile:getCreatures() == 0 then
                            autoWalk(targetPos, 100, { ignoreNonPathable = false })
                            return
                        end
                    end
                end
            end
        end
        return 
    end

    -- 2. VERIFICAÇÃO: SE JÁ ESTOU EM CIMA DE UMA BANHEIRA -> NÃO FAZ NADA
    local standingTile = g_map.getTile(playerPos)
    if standingTile then
        for _, item in ipairs(standingTile:getItems()) do
            if item:getId() == 54000 or item:getId() == 54091 then 
                return -- Já estou posicionado corretamente
            end
        end
    end

    -- 3. BUSCA POR BANHEIRA LIVRE
    for _, tile in ipairs(g_map.getTiles(posz())) do
        local tilePos = tile:getPosition()
        if getDistanceBetween(playerPos, tilePos) <= 2 then
            local hasOrb = false
            for _, item in ipairs(tile:getItems()) do
                if item:getId() == 54000 then
                    hasOrb = true
                    break
                end
            end

            -- Se tem o Orb E não tem nenhuma criatura (player/monstro) no tile
            if hasOrb and #tile:getCreatures() == 0 then
                autoWalk(tilePos, 100, { ignoreNonPathable = true })
                return 
            end
        end
    end
end)
addIcon("banheira", {item={id = 54000, count = 1}}, function(icon, isOn)
  banheira.setOn(isOn)
end)

-- ========================================
-- Macro: atravessar fields com segurança
-- Pausa CaveBot em 562,1340,6 e anda 1 sqm
-- Retoma CaveBot em 567,1340,6
-- Só anda com mana >= 90%
-- Usa autoWalk
-- ========================================

local START = {x = 562, y = 1340, z = 6}
local END_  = {x = 567, y = 1340, z = 6}
local MANA_MIN = 90

local function samePos(a, b)
  return a.x == b.x and a.y == b.y and a.z == b.z
end

local function stepRight()
  local pos = player:getPosition()
  autoWalk({x = pos.x + 1, y = pos.y, z = pos.z})
end

macro(200, "Mana Safe Walk", function()
  if not g_game.isOnline() then return end

  local pos = player:getPosition()

  -- entrou na área perigosa
  if samePos(pos, START) then
    CaveBot.setOff()
  end

  -- se estiver no trajeto, anda 1 sqm por vez
  if pos.z == START.z and pos.y == START.y and pos.x >= START.x and pos.x < END_.x then
    if manapercent() >= MANA_MIN then
      stepRight()
      delay(300)
    end
    return
  end

  -- chegou no fim, liga cavebot
  if samePos(pos, END_) then
    CaveBot.setOn()
  end
end)
