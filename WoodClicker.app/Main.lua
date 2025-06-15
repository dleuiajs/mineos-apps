  
-- Import libraries
local GUI = require("GUI")
local system = require("System")
local screen = require("Screen")
local computer = require("Computer")
local unicode = require("unicode")
local fs = require("filesystem")

---------------------------------------------------------------------------------

-- окно
local workspace, window, menu = system.addWindow(GUI.tabbedWindow(1, 1, 60, 20, 0xE1E1E1))

-- язык
local lang = system.getCurrentScriptLocalization()

-- лейаут
local layout = window:addChild(GUI.layout(1, 5, window.width, window.height -5, 1, 1))

local gameBar = window.tabBar:addItem(lang.game)
local inventoryBar = window.tabBar:addItem(lang.inventory)
local shopBar = window.tabBar:addItem(lang.shop)
local settingsBar = window.tabBar:addItem(lang.settings)

-- consts
local filesPath = fs.path(system.getCurrentScript())

--------------------------------------------------------------------------------
-- переменные
local clicks = 0  -- баланс
local diamonds = 0 -- баланс алмазов
local factor = 1 -- коэф кликов
local priceUpgradeClick = 1 -- нач. цена кликов

local valueUpgradeClick = 0

local timeoutAutoClick = 0 -- сколько прошло времени
local valueAutoClick = 0 -- кол-во роботов
local priceAutoClick = 3  -- нач. цена роботов

local sound = true

-- функции
local function loadGame()
  local path = filesPath .. "save.sf"
  if fs.exists(path) then
    local data = fs.readTable(path)
    clicks = data.clicks or 0
    diamonds = data.diamonds or 0 
    factor = data.factor or 1
    priceUpgradeClick = data.priceUpgradeClick or 1
    valueUpgradeClick = data.valueUpgradeClick or 0  
    timeoutAutoClick = data.timeoutAutoClick or 0  
    valueAutoClick = data.valueAutoClick or 0  
    priceAutoClick = data.priceAutoClick or 3  
    if data.sound ~= nil then sound = data.sound end
  end
end

local function saveGame()
  local saveData = {
    clicks = clicks,
    diamonds = diamonds,
    factor = factor,
    priceUpgradeClick = priceUpgradeClick,
    valueUpgradeClick = valueUpgradeClick,
    timeoutAutoClick = timeoutAutoClick,
    valueAutoClick = valueAutoClick,
    priceAutoClick = priceAutoClick,
    sound = sound
  }
  fs.writeTable(filesPath .. "save.sf", saveData)
end


local function roundDownTo(n, multiple)
  return math.floor(n / multiple) * multiple
end

local function addButton(text)
  return layout:addChild(GUI.roundedButton(1, 1, 36, 3, 0xD2D2D2, 0x696969, 0x4B4B4B, 0xF0F0F0, text))
end

local function addText(text)
  local width = unicode.len(text)
  local obj = layout:addChild(GUI.object(1, 1, width, 1))
  obj.draw = function(obj)
    screen.drawText(obj.x, obj.y, 0x4B4B4B, text)
  end
end

local function addClicksText()
  local width = unicode.len(lang.clicksHave ..  clicks ..  lang.currency)
  local obj = layout:addChild(GUI.object(1, 1, width, 1))
  obj.draw = function(obj)
    screen.drawText(obj.x, obj.y, 0x4B4B4B, lang.clicksHave ..  clicks ..  lang.currency)
  end
end

local function addDiamondsText()
  local width = unicode.len(lang.clicksHave ..  diamonds ..  lang.diamonds)
  local obj = layout:addChild(GUI.object(1, 1, width, 1))
  obj.draw = function(obj)
    screen.drawText(obj.x, obj.y, 0x4B4B4B, lang.clicksHave ..  diamonds ..  lang.diamonds)
  end
end

local function beep(freq)
  if sound == true then
    computer.beep(freq)
  end
end

local function error(text)
  beep(50)
  GUI.alert(text)
end  

local function barController(bar, funct)
  bar.onTouch = function()
    layout:removeChildren()
    funct()
    saveGame()
    workspace:draw()
  end
end

local function generateGameObjects()
  local autoSaveClicks = 0
  local autoClickerText = ""
  addClicksText()
  addButton(lang.click).onTouch = function() 
    beep(100)
    clicks = clicks + factor
    
    -- если у нас есть автокликеры
    if valueAutoClick >= 1 then
      timeoutAutoClick = timeoutAutoClick + 1
      if timeoutAutoClick == 30 then
        local clicksAutoClick = math.floor(math.random(10, 50) * valueAutoClick)
        clicks = clicks + clicksAutoClick
        timeoutAutoClick = 0
        autoClickerText = lang.autoClickTextGet .. clicksAutoClick .. lang.currency
      else
        autoClickerText = ""
      end
    end 
    
    autoSaveClicks = autoSaveClicks + 1
    if autoSaveClicks >= 10 then
      saveGame()
      autoSaveClicks = 0  
    end
  end
  local autoClickerGUIText = layout:addChild(GUI.object(1, 1, 30, 1))
    autoClickerGUIText.draw = function(object)
      if autoClickerText ~= "" then
        object.width = unicode.len(autoClickerText)
        screen.drawText(object.x, object.y, 0xAAAAAA, autoClickerText)
      end
    end
end

--------------------------------------------------------------------------------

------ start
loadGame()
generateGameObjects()

------ игра
barController(gameBar, generateGameObjects)

------ инвентарь
barController(inventoryBar, function()
  if clicks > 0 then addText(lang.haveClicks .. clicks) end
  if diamonds > 0 then addText(lang.haveDiamonds .. diamonds) end
  addText(lang.axe .. " (" .. lang.lvl .. " " .. valueUpgradeClick + 1 .. ")")
  if valueAutoClick > 0 then addText(lang.haveAutoClicks .. valueAutoClick) end
  end
  )

------ магазин
barController(shopBar, function()  
  addClicksText()
  addDiamondsText()
  local maxValue = math.floor(clicks / 10)
  if maxValue < 1 then maxValue = 1 end
  local slider = layout:addChild(GUI.slider(1, 1, 30, 0x66DB80, 0x0, 0xFFFFFF, 0xAAAAAA, 0, maxValue, maxValue, true, lang.get, lang.diamonds))
  local clicksNeed = roundDownTo(slider.value * 10, 10)
  local diamondsGived = math.floor(slider.value)
  slider.roundValues = true
  slider.onValueChanged = function()
    clicksNeed = roundDownTo(slider.value * 10, 10)
    diamondsGived = math.floor(slider.value)
  end 
  -- 
  local object = layout:addChild(GUI.object(1, 1, 16, 1))
    object.draw = function(object)
    screen.drawText(object.x, object.y, 0xAAAAAA, lang.give .. clicksNeed .. lang.currency)
  end
  addButton(lang.trade).onTouch = function()
    if slider.value >= 1 and clicks >= clicksNeed then
      clicks = clicks - clicksNeed
      diamonds = diamonds + diamondsGived
      beep(1000)
    else
      if slider.value < 1 then
        error(lang.tradeError1)
      else
        error(lang.tradeError2)
      end  
    end
  end 
  -- товары
  addButton(lang.products).onTouch = function()
    local container = GUI.addBackgroundContainer(workspace, true, true, lang.products)
    
    local function addButtonContainer(text)
      return container.layout:addChild(GUI.roundedButton(1, 1, 36, 3, 0xD2D2D2, 0x696969, 0x4B4B4B, 0xF0F0F0, text))
    end
  
    local UpgradeClickBuyButton = addButtonContainer(lang.upgradeClick .. lang.price .. priceUpgradeClick .. lang.diamondsAbbriv .. ")")
    UpgradeClickBuyButton.onTouch = function()
      if diamonds >= priceUpgradeClick then
        beep(1000) 
        valueUpgradeClick = valueUpgradeClick + 1
        factor = factor + 1
        diamonds = diamonds - priceUpgradeClick
        priceUpgradeClick = math.floor(priceUpgradeClick * 1.5 + 0.5)
        UpgradeClickBuyButton.text = lang.upgradeClick .. lang.price .. priceUpgradeClick .. lang.diamondsAbbriv .. ")"
        workspace:draw()
      else
        error(lang.errorShop ..  priceUpgradeClick - diamonds .. lang.diamonds)
      end
    end
    
    local AutoClickerBuyButton = addButtonContainer(lang.autoClick .. lang.price .. priceAutoClick .. lang.diamondsAbbriv .. ")")
    AutoClickerBuyButton.onTouch = function()
      if diamonds >= priceAutoClick then
        beep(1000)
        valueAutoClick = valueAutoClick + 1
        diamonds = diamonds - priceAutoClick
        priceAutoClick = math.floor(priceAutoClick * 1.5 + 0.5)
        AutoClickerBuyButton.text = lang.autoClick .. lang.price .. priceAutoClick .. lang.diamondsAbbriv .. ")"
        workspace:draw() 
      else
        error(lang.errorShop ..  priceAutoClick - diamonds .. lang.diamonds)
      end  
    end
    
  end      
end
  )

------ настройки
barController(settingsBar, function()
local soundToggler = layout:addChild(GUI.switchAndLabel(1, 1, 25, 8, 0x66DB80, 0x1D1D1D, 0xE6E6E6, 0x4B4B4B, lang.sound, sound))
  soundToggler.switch.state = sound
  soundToggler.switch.onStateChanged = function()
     sound = soundToggler.switch.state
     saveGame()
  end
addText(lang.dev .. ": dleuiajs")
end
)


--------------------------------------------------------------------------------

-- Customize MineOS menu for this application by your will
local contextMenu = menu:addContextMenuItem("File")
contextMenu:addItem("New")
contextMenu:addSeparator()
contextMenu:addItem("Open")
contextMenu:addItem("Save", true)
contextMenu:addItem("Save as")
contextMenu:addSeparator()
contextMenu:addItem("Close").onTouch = function()
  window:remove()
end

-- You can also add items without context menu
menu:addItem("Example item").onTouch = function()
  GUI.alert("It works!")
end

-- Create callback function with resizing rules when window changes its' size
window.onResize = function(newWidth, newHeight)
  window.backgroundPanel.width, window.backgroundPanel.height = newWidth, newHeight
  layout.width, layout.height = newWidth, newHeight
end

---------------------------------------------------------------------------------

-- Draw changes on screen after customizing your window
workspace:draw()
