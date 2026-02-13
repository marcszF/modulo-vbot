-- [[ 1. GESTAO DE STORAGE POR PERSONAGEM ]] --
local charName = player:getName()
storage[charName] = storage[charName] or {}
local config = storage[charName]

-- Valores individuais
config.targetLevel = config.targetLevel or "2000"
config.showLvlTimer = config.showLvlTimer or false
config.windowPos = config.windowPos or {x = 200, y = 200}

-- [[ 2. FUNCAO DE LIMPEZA ]] --
local function clearExistingWindows()
    local root = modules.game_interface.getRootPanel()
    local oldWindow = root:recursiveGetChildById('targetLvlWindow')
    if oldWindow then
        oldWindow:destroy()
    end
    targetLvlWindow = nil
end

-- Limpa ao iniciar
clearExistingWindows()

-- [[ 3. INTERFACE NA ABA DO BOT (ORDEM SOLICITADA) ]] --
setDefaultTab("Main")

-- 1. Texto (sem nome do char e sem acentos)
addLabel("lblTitle", "Tempo para o level:")

-- 2. Campo para digitar o level abaixo do texto
addTextEdit("lvlInput", config.targetLevel, function(widget, text)
    config.targetLevel = text
end)

-- 3. Botao Ativado/Desativado abaixo do campo
addSeparator()
local timerBtn = addButton("timerToggle", (config.showLvlTimer and "Ativado" or "Desativado"), function(widget)
    config.showLvlTimer = not config.showLvlTimer
    
    if config.showLvlTimer then
        widget:setText("Ativado")
        widget:setColor("green")
    else
        widget:setText("Desativado")
        widget:setColor("red")
        clearExistingWindows() -- Remove a janela imediatamente ao desativar
    end
end)

-- Define a cor correta ao carregar o script
if config.showLvlTimer then timerBtn:setColor("green") else timerBtn:setColor("red") end

-- [[ 4. GESTAO DA JANELA HUD ]] --
function toggleWindow()
    if not config.showLvlTimer then return false end

    local root = modules.game_interface.getRootPanel()
    local window = root:recursiveGetChildById('targetLvlWindow')
    
    if not window then
        targetLvlWindow = setupUI([[
UIWindow
  id: targetLvlWindow
  size: 200 60
  draggable: true
  focusable: false
  image-source: /images/ui/panel_flat
  image-border: 4
  opacity: 0.95

  Label
    id: title
    text: "Tempo para o Level:"
    text-align: center
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    margin-top: 8
    font: verdana-11px-rounded
    color: #dfdfdf

  Label
    id: resultTime
    text: "Aguardando..."
    text-align: center
    anchors.top: title.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    margin-top: 5
    font: verdana-11px-rounded
    color: #ffaa00
]], root)

        targetLvlWindow:setPosition(config.windowPos)
        targetLvlWindow.onGeometryChange = function(widget)
            config.windowPos = widget:getPosition()
        end
    else
        targetLvlWindow = window
    end
    return true
end

-- [[ 5. LOGICA DE BUSCA E CALCULO ]] --

function parseXP(text)
    if not text then return 0 end
    local clean = text:gsub(",", ""):gsub(" ", ""):lower()
    local multiplier = 1
    if clean:find("kkkk") then multiplier = 1000000000000
    elseif clean:find("kkk") then multiplier = 1000000000
    elseif clean:find("kk") then multiplier = 1000000
    elseif clean:find("k") then multiplier = 1000 end
    local numPart = clean:match("[%d%.]+")
    return (tonumber(numPart) or 0) * multiplier
end

function getXpHour()
    local root = modules.game_interface.getRootPanel()
    local function search(widget)
        if not widget then return nil end
        if widget:getText() == "XP /h:" then
            local p = widget:getParent()
            if p then
                local children = p:getChildren()
                for i, child in ipairs(children) do
                    if child == widget and children[i+1] then return children[i+1]:getText() end
                end
            end
        end
        for _, child in ipairs(widget:getChildren()) do
            local res = search(child)
            if res then return res end
        end
    end
    return search(root)
end

function getExpForLevel(lvl)
    local n = tonumber(lvl) or 0
    if n <= 1 then return 0 end
    return (50/3) * (n^3 - 6*n^2 + 17*n - 12)
end

-- [[ 6. LOOP PRINCIPAL ]] --
macro(1000, function()
    -- Se nao estiver ativado, garante que nao haja janela e para o macro
    if not toggleWindow() then return end

    local targetLvl = tonumber(config.targetLevel) or 0
    targetLvlWindow.title:setText("Tempo para o Level: " .. targetLvl)

    local xphStr = getXpHour()
    if not xphStr then
        targetLvlWindow.resultTime:setText("Abra o Analyser")
        return
    end

    local xph = parseXP(xphStr)
    if xph <= 0 then
        targetLvlWindow.resultTime:setText("Cace para calcular")
        return
    end

    local missingXp = getExpForLevel(targetLvl) - exp()

    if missingXp <= 0 then
        targetLvlWindow.resultTime:setText("Objetivo Alcancado!")
        targetLvlWindow.resultTime:setColor("#00ff00")
    else
        local hours = missingXp / xph
        local h = math.floor(hours)
        local m = math.floor((hours - h) * 60)
        local s = math.floor((((hours - h) * 60) - m) * 60)
        
        if h > 5000 then
            targetLvlWindow.resultTime:setText("Tempo muito longo")
        elseif h > 0 then
            targetLvlWindow.resultTime:setText(string.format("%dh %dm", h, m))
        else
            targetLvlWindow.resultTime:setText(string.format("%dm %ds", m, s))
        end
        targetLvlWindow.resultTime:setColor("#ffaa00")
    end
end)