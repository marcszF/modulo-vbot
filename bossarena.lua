setDefaultTab("Tools")
UI.Separator()
-- Configurações de ID e Distância
local DANGER_ID = 55636
local MAX_RANGE = 4
local SEARCH_DEPTH = 6
local STEP_DELAY = 120

-- Variáveis de controle de estado
local escapePath = nil
local escapeIndex = 1
local lastStepTime = 0

-- Funções Utilitárias (Localizadas para performance)
local function posKey(pos) return pos.x .. "," .. pos.y .. "," .. pos.z end
local function dist(a, b) return math.max(math.abs(a.x - b.x), math.abs(a.y - b.y)) end

local function isDangerTile(pos)
    local tile = g_map.getTile(pos)
    if not tile then return false end
    for _, thing in ipairs(tile:getThings()) do
        if thing:isItem() and thing:getId() == DANGER_ID then return true end
    end
    return false
end

local function findSafePath(startPos, bossPos)
    local directions = {
        { dx = 0, dy = -1, dir = North },
        { dx = 0, dy = 1, dir = South },
        { dx = -1, dy = 0, dir = West },
        { dx = 1, dy = 0, dir = East },
    }
    local visited = {}
    local queue = { { pos = startPos, path = {} } }
    visited[posKey(startPos)] = true
    local bestPath = nil
    local bestDist = 999

    while #queue > 0 do
        local cur = table.remove(queue, 1)
        local curDist = dist(cur.pos, bossPos)

        -- Se o tile é seguro, faz parte do caminho e está no range do Boss
        if not isDangerTile(cur.pos) and #cur.path > 0 and curDist <= MAX_RANGE then
            if curDist < bestDist then
                bestDist = curDist
                bestPath = cur.path
            end
        end

        if #cur.path < SEARCH_DEPTH then
            for _, d in ipairs(directions) do
                local np = { x = cur.pos.x + d.dx, y = cur.pos.y + d.dy, z = cur.pos.z }
                local k = posKey(np)
                if not visited[k] then
                    visited[k] = true
                    local tile = g_map.getTile(np)
                    if tile and tile:isWalkable() then
                        local newPath = table.copy(cur.path)
                        table.insert(newPath, d.dir)
                        table.insert(queue, { pos = np, path = newPath })
                    end
                end
            end
        end
    end
    return bestPath
end

-- Macro Principal
local boss = macro(100, "Boss Safe Step", function()
    local player = g_game.getLocalPlayer()
    if not player then return end

    -- 1. Lógica de detecção e cálculo de rota
    if not escapePath then
        local target = g_game.getAttackingCreature()
        if not target then return end

        local pos = player:getPosition()
        if isDangerTile(pos) then
            escapePath = findSafePath(pos, target:getPosition())
            escapeIndex = 1
        end
    end

    -- 2. Lógica de execução do movimento
    if escapePath then
        if now - lastStepTime < STEP_DELAY then return end

        local dir = escapePath[escapeIndex]
        if dir ~= nil then
            g_game.walk(dir)
            lastStepTime = now
            escapeIndex = escapeIndex + 1
        else
            -- Fim do caminho atingido
            escapePath = nil
            escapeIndex = 1
        end
    end
end)
addIcon("boss", {item={id = 55636, count = 1}, text="!! BOSS !!"}, function(icon, isOn)
  boss.setOn(isOn)
end)