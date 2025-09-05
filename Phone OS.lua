local pastebinID = "6dmvbgXQ"
local scriptName = "OS.lua"

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

local function getAppColor(appPath)
    local colorMap = {
        red = colors.red,
        green = colors.green,
        blue = colors.blue,
        yellow = colors.yellow,
        white = colors.white,
        black = colors.black,
        gray = colors.gray,
        cyan = colors.cyan,
        magenta = colors.magenta,
        orange = colors.orange,
        purple = colors.purple,
        brown = colors.brown
    }

    local file = fs.open(appPath, "r")
    local colorLine = file.readLine()
    file.close()

    local colorName = colorLine:match("^%-%- (.+)")
    return colorMap[colorName] or colors.green
end

local function drawBackground(backgroundColor)
    term.setBackgroundColor(backgroundColor)
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

    local houseIcon = "-"
    local iconWidth = 1
    local iconStart = math.floor((w - iconWidth) / 2) + 1
    term.setTextColor(colors.white)
    term.setCursorPos(iconStart, h - barHeight + 2)
    term.write(houseIcon)
end

local function drawApps()
    local w, h = term.getSize()
    local appsFolder = "apps"

    if not fs.exists(appsFolder) then
        return
    end

    local files = fs.list(appsFolder)

    if #files == 0 then
        return
    end

    local iconWidth = 5
    local iconHeight = 4
    local iconPadding = 1
    local startX, startY = 2, 3
    local iconsPerRow = math.floor(w / (iconWidth + iconPadding))

    for i, file in ipairs(files) do
        if fs.isDir(appsFolder .. "/" .. file) then
            goto continue
        end

        local x = startX + ((i - 1) % iconsPerRow) * (iconWidth + iconPadding)
        local y = startY + math.floor((i - 1) / iconsPerRow) * (iconHeight + iconPadding)
        local appPath = appsFolder .. "/" .. file
        local appColor = getAppColor(appPath)

        term.setBackgroundColor(appColor)
        for row = 1, iconHeight do
            term.setCursorPos(x, y + row - 1)
            for col = 1, iconWidth do
                term.write(" ")
            end
        end

        -- Draw the app name inside the icon
        local appName = file:gsub("%.lua$", "")  -- Remove the .lua extension
        term.setTextColor(colors.white)
        term.setBackgroundColor(appColor)

        -- Split the app name into lines if it doesn't fit
        local maxCharsPerLine = iconWidth
        local lines = {}
        for line in appName:gmatch("[^\n]+") do
            while #line > 0 do
                table.insert(lines, line:sub(1, maxCharsPerLine))
                line = line:sub(maxCharsPerLine + 1)
            end
        end

        -- Write the app name inside the icon
        for lineIndex, lineText in ipairs(lines) do
            if lineIndex > iconHeight then break end  -- Don't overflow the icon
            local centerX = x + math.floor((iconWidth - #lineText) / 2)
            term.setCursorPos(centerX, y + lineIndex - 1)
            term.write(lineText)
        end

        ::continue::
    end
end

local function handleMouseClick(x, y)
    local w, h = term.getSize()
    local appsFolder = "apps"

    -- Check if the click is on the "-" button
    local barHeight = 3
    local iconWidth = 1
    local iconStart = math.floor((w - iconWidth) / 2) + 1
    local iconY = h - barHeight + 2

    if x >= iconStart and x < iconStart + iconWidth and y == iconY then
        -- Stop the currently running program
        os.queueEvent("terminate")
        -- Restart the OS script
        shell.run("OS.lua")
        return true
    end

    -- Handle app clicks
    if not fs.exists(appsFolder) or #fs.list(appsFolder) == 0 then
        return false
    end

    local files = fs.list(appsFolder)
    local iconWidth = 5
    local iconHeight = 4
    local iconPadding = 1
    local startX, startY = 2, 3
    local iconsPerRow = math.floor(w / (iconWidth + iconPadding))

    for i, file in ipairs(files) do
        if fs.isDir(appsFolder .. "/" .. file) then
            goto continue
        end

        local xPos = startX + ((i - 1) % iconsPerRow) * (iconWidth + iconPadding)
        local yPos = startY + math.floor((i - 1) / iconsPerRow) * (iconHeight + iconPadding)

        if x >= xPos and x < xPos + iconWidth and y >= yPos and y < yPos + iconHeight then
            local appPath = appsFolder .. "/" .. file
            if fs.exists(appPath) then
                term.setBackgroundColor(colors.black)
                term.setTextColor(colors.white)
                term.clear()
                term.setCursorPos(1, 1)
                shell.run(appPath)
                return true
            end
        end

        ::continue::
    end

    return false
end

local function main()
    local name, backgroundColor = readSettings()
    local running = true

    while running do
        drawBackground(backgroundColor)
        drawTopBar(name)
        drawBottomBar()
        drawApps()

        -- Update the time every second
        os.startTimer(1)
        local event, button, x, y = os.pullEvent()  -- Wait for 1 second or an event
        if event == "mouse_click" then
            if handleMouseClick(x, y) then
                -- After the app is closed, return to the main menu
                running = true
            end
        end
        sleep(0.05)
    end
end

local startupFile = fs.open("startup.lua", "w")
startupFile.write('shell.run("OS.lua")')
startupFile.close()

main()