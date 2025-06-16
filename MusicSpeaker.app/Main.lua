
-- Import libraries
local GUI = require("GUI")
local system = require("System")
local computer = require("Computer")
local screen = require("Screen")
local event = require("Event")
local fs = require("filesystem")


---------------------------------------------------------------------------------

-- загрузка файлов
local filesPath = fs.path(system.getCurrentScript())
local songFolder = "Songs"  -- путь к папке с песнями
local songFiles = {}

for i, file in ipairs(fs.list(filesPath .. songFolder)) do
  if file:match("%.lua$") then 
    table.insert(songFiles, file:sub(1,-5))
  end
end

-- язык
local lang = system.getCurrentScriptLocalization()

-- Add a new window to MineOS workspace
local workspace, window, menu = system.addWindow(GUI.filledWindow(1, 1, 60, #songFiles + 10, 0x424242))

-- Get localization table dependent of current system language
local localization = system.getCurrentScriptLocalization()

-- Add single cell layout to window
local layout = window:addChild(GUI.layout(1, 1, window.width, window.height, 1, 1))

-- функции
local function addButton(text)
  return layout:addChild(GUI.roundedButton(1, 1, 36, 3, 0xC50909, 0xFFFFFF, 0xAB1A17, 0xC0C0C0, text))
end

local function addText(text)
  local width = unicode.len(text)
  local obj = layout:addChild(GUI.object(1, 1, width, 1))
  obj.draw = function(obj)
    screen.drawText(obj.x, obj.y, 0x4B4B4B, text)
  end
end

local function barController(bar, funct)
  bar.onTouch = function()
    layout:removeChildren()
    funct()
    workspace:draw()
  end
end

---------------------------------------------------------------------------------
local function loadSong(filename)
  local f, err = loadfile(filesPath .. songFolder .. "/" .. filename .. ".lua")
  if not f then
    error(lang.fileError .. " "..filename..": "..err)
  end
  return f()
end

local function playMelody(melody)
  local i = 1
  local function playNote()
    if i <= #melody then
      local freq, dur = melody[i][1], melody[i][2]
      if freq > 20 and freq < 20000 then
        computer.beep(freq, dur)       
      end
        i = i + 1
        if freq ~= 0 then
          playNote()
--           event.addHandler(playNote, 0, 1)
        else
          event.addHandler(playNote, dur, 1)
        end
    end
  end
  playNote()
end



-- GUI
local selectedSongFile = songFiles[1]

local list = layout:addChild(GUI.list(1, 5, 40, #songFiles, 1, 0, 0x212121, 0xBBBBBB, 0x212121, 0xBBBBBB, 0x333333, 0xBBBBBB))
for i, songFile in ipairs(songFiles) do
  local item = list:addItem(songFile)
    item.onTouch = function()
      list.selectedItem = i
      selectedSongFile = songFile

      if list.onItemSelected then
        list.onItemSelected(i, songFile)
      end
    end
end

addButton(lang.play).onTouch = function()
  if selectedSongFile then
    local melody = loadSong(selectedSongFile)
    playMelody(melody)
  else
    GUI.alert(lang.selectSongError)
  end
end

-- Create callback function with resizing rules when window changes its' size
window.onResize = function(newWidth, newHeight)
  window.backgroundPanel.width, window.backgroundPanel.height = newWidth, newHeight
  layout.width, layout.height = newWidth, newHeight
end

---------------------------------------------------------------------------------

-- Draw changes on screen after customizing your window
workspace:draw()
