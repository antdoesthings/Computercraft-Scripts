-- black

local pastebinID = "04vWQmiQ"
local scriptName = "Apps/Settings.lua"

local storedText = ""
local storedColor = colors.white
local settingsFile = "settings.txt"

-- Create a reverse mapping of the colors table
local colorNames = {}
local colorOrder = {
    colors.white, colors.orange, colors.magenta, colors.lightBlue,
    colors.yellow, colors.lime, colors.pink, colors.gray,
    colors.lightGray, colors.cyan, colors.purple, colors.blue,
    colors.brown, colors.green, colors.red, colors.black
}

for i, value in ipairs(colorOrder) do
    colorNames[value] = colors[value]
end

-- Load settings from file
local function loadSettings()
    if fs.exists(settingsFile) then
        local file = fs.open(settingsFile, "r")
        if file then
            storedText = file.readLine() or ""
            storedColor = tonumber(file.readLine()) or colors.white
            file.close()
        end
    end
end

-- Save settings to file
local function saveSettings()
    local file = fs.open(settingsFile, "w")
    if file then
        file.writeLine(storedText)
        file.writeLine(tostring(storedColor))
        file.close()
    end
end

local function updateScript()
    local url = "https://pastebin.com/raw/" .. pastebinID
    local response = http.get(url)

    if response then
        local newCode = response.readAll()
        response.close()

        if fs.exists("temp_update.lua") then
            fs.delete("temp_update.lua")
        end

        local tempFile = fs.open("temp_update.lua", "w")
        if tempFile then
            tempFile.write(newCode)
            tempFile.close()
        else
            return
        end

        local startupFile = fs.open("startup.lua", "w")
        if startupFile then
            startupFile.write([[
if fs.exists("temp_update.lua") then
    fs.delete("]] .. scriptName .. [[")
    fs.move("temp_update.lua", "]] .. scriptName .. [[")
end
shell.run("]] .. scriptName .. [[")
            ]])
            startupFile.close()
        else
            return
        end

        os.reboot()
    else
        print("Failed to fetch update from Pastebin.")
    end
end

local function checkForUpdates()
    local url = "https://pastebin.com/raw/" .. pastebinID
    local response = http.get(url)

    if response then
        local newCode = response.readAll()
        response.close()

        local currentFile = fs.open(scriptName, "r")
        if currentFile then
            local currentCode = currentFile.readAll()
            currentFile.close()

            if newCode ~= currentCode then
                updateScript()
            end
        end
    else
        print("Failed to check for updates.")
    end
end

checkForUpdates()

local function readSettings()
    if not fs.exists("settings.txt") then
        return nil, colors.cyan
    end
 
    local file = fs.open("settings.txt", "r")
    local name = file.readLine() or "Unknown"
    local colorNumber = tonumber(file.readLine()) or colors.cyan
    file.close()
 
    return name, colorNumber
end

local function drawTopBar(name)
    local w, h = term.getSize()
    term.setBackgroundColor(colors.white)
    term.setTextColor(colors.black)
    term.setCursorPos(1, 1)
    term.clearLine()
 
    -- Draw the name on the top left
    term.write(name)
 
    -- Draw the day count and time on the top right
    local dayCount = os.day() - 1
    local time = textutils.formatTime(os.time(), false)
    local timeText = "Day " .. dayCount .. "   " .. time
    term.setCursorPos(w - #timeText + 1, 1)
    term.write(timeText)
end

local function drawBackground()
    term.setBackgroundColor(colors.black)
    term.clear()
end

local function drawBottomBar()
    local w, h = term.getSize()
    local barHeight = 3
    term.setBackgroundColor(colors.gray)
    for i = 1, barHeight do
        term.setCursorPos(1, h - i + 1)
        term.clearLine()
    end

    -- Draw house icon in the center of the bottom bar
    local houseIcon = "-"
    local iconWidth = 1
    local iconStart = math.floor((w - iconWidth) / 2) + 1
    term.setTextColor(colors.white)
    term.setCursorPos(iconStart, h - barHeight + 2)
    term.write(houseIcon)
end

local function drawSaveButton()
    local w, h = term.getSize()
    term.setBackgroundColor(colors.green)
    term.setTextColor(colors.white)
    local saveText = "[Save]"
    local saveX = math.floor((w - #saveText) / 2) + 1
    local saveY = h - 4 -- Positioned above the bottom bar
    term.setCursorPos(saveX, saveY)
    term.write(saveText)
end

local function drawInputFields()
    local w, h = term.getSize()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.setCursorPos(2, 5)
    term.write("Enter text: ")
    term.setCursorPos(2, 7)
    term.write("Select color: ")

    -- Draw text input field
    term.setBackgroundColor(colors.white)
    term.setTextColor(colors.black)
    term.setCursorPos(14, 5)
    term.write(" " .. storedText .. " ")

    -- Draw selected color block
    term.setBackgroundColor(storedColor)
    term.setCursorPos(16, 7)
    term.write("  ") -- Two spaces to represent the block
end

local function drawColorPicker()
    local w, h = term.getSize()
    local pickerX, pickerY = 16, 9
    local pickerWidth = 10
    local pickerHeight = 8

    -- Draw a grid of all available colors
    for i = 1, 16 do
        local x = pickerX + ((i - 1) % 4) * 3
        local y = pickerY + math.floor((i - 1) / 4)
        term.setBackgroundColor(colorOrder[i])
        term.setCursorPos(x, y)
        term.write("  ") -- Two spaces to represent each color block
    end
end

local function handleInput()
    local event, key, x, y
    while true do
        event, key, x, y = os.pullEvent()
        if event == "mouse_click" then
            local w, h = term.getSize()

			-- Check if the click is on the "-" button
    		local barHeight = 3
    		local iconWidth = 1
    		local iconStart = math.floor((w - iconWidth) / 2) + 1
    		local iconY = h - barHeight + 2

			if x >= iconStart and x < iconStart + iconWidth and y == iconY then
      			shell.run("OS.lua")
    			return true
			end

            -- Check if click is within the selected color block
            if x >= 16 and x <= 17 and y == 7 then
                -- Show the color picker
                drawColorPicker()

                -- Wait for the user to select a color
                while true do
                    event, key, x, y = os.pullEvent()
                    if event == "mouse_click" then
                        local pickerX, pickerY = 16, 9
                        local colorIndex = (y - pickerY) * 4 + math.floor((x - pickerX) / 3) + 1
                        if colorIndex >= 1 and colorIndex <= 16 then
                            storedColor = colorOrder[colorIndex]
                            break
                        end
                    end
                end
                break
            end

            -- Check if click is within the text input field
            if x >= 14 and x <= 14 + #storedText + 2 and y == 5 then
                term.setCursorPos(14, 5)
                term.setBackgroundColor(colors.white)
                term.setTextColor(colors.black)
                term.write(" ")
                storedText = read()
                term.setCursorPos(14, 5)
                term.write(" " .. storedText .. " ")
                break
            end

            -- Check if click is within the save button
            if y == h - 4 and x >= math.floor((w - 6) / 2) + 1 and x <= math.floor((w - 6) / 2) + 6 then
                saveSettings()
                break
            end
        end
    end
end

local function main()
	local name = readSettings()
    local running = true

    -- Load settings at startup
    loadSettings()

    while running do
        drawBackground()
        drawTopBar(name)
        drawBottomBar()
        drawSaveButton()
        drawInputFields()
        handleInput()
        os.startTimer(1)
        sleep(0.05)
    end
end

local startupFile = fs.open("startup.lua", "w")
startupFile.write('shell.run("OS.lua")')
startupFile.close()

main()