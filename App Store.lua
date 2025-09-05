-- blue

local pastebinID = "RA9QRuCz"
local scriptName = "apps/AppStore.lua"
 
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

-- List of apps: {pastebinCode, NameofProgram, ColorToDisplay}
local apps = {
    {"6dmvbgXQ", "OS", colors.cyan},
    {"04vWQmiQ", "Settings", colors.black}
}

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
    term.setBackgroundColor(colors.lightGray)
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

local function getInstalledApps()
    local installedApps = {}
    local appsFolder = "apps"

    if fs.exists(appsFolder) then
        for _, file in ipairs(fs.list(appsFolder)) do
            if not fs.isDir(appsFolder .. "/" .. file) then
                table.insert(installedApps, file)
            end
        end
    end

    return installedApps
end

local function drawApps()
    local w, h = term.getSize()
    local iconWidth = 5
    local iconHeight = 4
    local iconPadding = 1
    local startX, startY = 2, 3
    local iconsPerRow = math.floor(w / (iconWidth + iconPadding))

    -- Get the list of installed apps
    local installedApps = getInstalledApps()

    -- Filter out apps that are already installed
    local availableApps = {}
    for _, app in ipairs(apps) do
        local appName = app[2]
        local isInstalled = false
        for _, installedApp in ipairs(installedApps) do
            if installedApp == (appName .. ".lua") then
                isInstalled = true
                break
            end
        end
        if not isInstalled then
            table.insert(availableApps, app)
        end
    end

    -- Draw the available apps
    for i, app in ipairs(availableApps) do
        local pastebinCode, appName, appColor = unpack(app)
        local x = startX + ((i - 1) % iconsPerRow) * (iconWidth + iconPadding)
        local y = startY + math.floor((i - 1) / iconsPerRow) * (iconHeight + iconPadding)

        term.setBackgroundColor(appColor)
        for row = 1, iconHeight do
            term.setCursorPos(x, y + row - 1)
            for col = 1, iconWidth do
                term.write(" ")
            end
        end

        term.setBackgroundColor(colors.lightGray)
        term.setTextColor(colors.white)
        local nameWidth = #appName
        local centerX = x + math.floor((iconWidth - nameWidth) / 2)
        term.setCursorPos(centerX, y + iconHeight)
        term.write(appName)
    end
end

local function handleMouseClick(x, y)
    local w, h = term.getSize()
    local iconWidth = 5
    local iconHeight = 4
    local iconPadding = 1
    local startX, startY = 2, 3
    local iconsPerRow = math.floor(w / (iconWidth + iconPadding))

	-- Check if the click is on the "-" button
    local barHeight = 3
    local iconWidth = 1
    local iconStart = math.floor((w - iconWidth) / 2) + 1
    local iconY = h - barHeight + 2

	if x >= iconStart and x < iconStart + iconWidth and y == iconY then
      	shell.run("OS.lua")
    	return true
	end

    -- Get the list of installed apps
    local installedApps = getInstalledApps()

    -- Filter out apps that are already installed
    local availableApps = {}
    for _, app in ipairs(apps) do
        local appName = app[2]
        local isInstalled = false
        for _, installedApp in ipairs(installedApps) do
            if installedApp == (appName .. ".lua") then
                isInstalled = true
                break
            end
        end
        if not isInstalled then
            table.insert(availableApps, app)
        end
    end

    -- Handle clicks on available apps
    for i, app in ipairs(availableApps) do
        local xPos = startX + ((i - 1) % iconsPerRow) * (iconWidth + iconPadding)
        local yPos = startY + math.floor((i - 1) / iconsPerRow) * (iconHeight + iconPadding)

        if x >= xPos and x < xPos + iconWidth and y >= yPos and y < yPos + iconHeight then
            local pastebinCode = app[1]
            local appName = app[2]
            local url = "https://pastebin.com/raw/" .. pastebinCode
            local response = http.get(url)

            if response then
                local newCode = response.readAll()
                response.close()

                -- Ensure the apps folder exists
                if not fs.exists("apps") then
                    fs.makeDir("apps")
                end

                -- Save the app to the apps folder
                local appPath = "apps/" .. appName .. ".lua"
                local appFile = fs.open(appPath, "w")
                if appFile then
                    appFile.write(newCode)
                    appFile.close()
                else
                    return false
                end

                term.setBackgroundColor(colors.black)
                term.setTextColor(colors.white)
                term.clear()
                term.setCursorPos(1, 1)
                shell.run(appPath)
                term.setBackgroundColor(colors.black)
                term.setTextColor(colors.white)
                term.clear()
                return true
            end
        end
    end

    return false
end

local function main()
	local name = readSettings()
    local running = true

    while running do
        drawBackground()
        drawTopBar(name)
        drawBottomBar()
        drawApps()

        os.startTimer(1)
        local event, button, x, y = os.pullEvent()
        if event == "mouse_click" then
            if handleMouseClick(x, y) then
                running = false
            end
        end
        sleep(0.05)
    end
end
 
local startupFile = fs.open("startup.lua", "w")
startupFile.write('shell.run("OS.lua")')
startupFile.close()

main()