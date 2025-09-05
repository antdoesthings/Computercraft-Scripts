-- blue

local githubBaseUrl = "https://raw.githubusercontent.com/antdoesthings/Computercraft-Scripts/main/"
local apiBaseUrl = "https://api.github.com/repos/antdoesthings/Computercraft-Scripts/contents/App%20Store%20Apps/"
local scriptName = "apps/App Store.lua"
local appStoreUrl = githubBaseUrl .. "App%20Store.lua"
 
local function updateScript()
    local response = http.get(appStoreUrl)
 
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
        print("Failed to fetch update from GitHub.")
    end
end
 
local function checkForUpdates()
    local response = http.get(appStoreUrl)
 
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
 
local function getColorFromName(name)
    local colorTable = {
        white = colors.white,
        orange = colors.orange,
        magenta = colors.magenta,
        lightBlue = colors.lightBlue,
        yellow = colors.yellow,
        lime = colors.lime,
        pink = colors.pink,
        gray = colors.gray,
        lightGray = colors.lightGray,
        cyan = colors.cyan,
        purple = colors.purple,
        blue = colors.blue,
        brown = colors.brown,
        green = colors.green,
        red = colors.red,
        black = colors.black
    }
    return colorTable[name] or colors.cyan
end
 
local function getAppsFromGithub()
    local apps = {}
    local response = http.get(apiBaseUrl)
    if response then
        local content = response.readAll()
        response.close()
        local data = textutils.unserializeJSON(content)
        if type(data) == "table" then
            for _, item in ipairs(data) do
                if item.type == "file" and string.sub(item.name, -4) == ".lua" then
                    local appUrl = githubBaseUrl .. item.path
                    local appResponse = http.get(appUrl)
                    if appResponse then
                        local firstLine = appResponse.readLine() or ""
                        appResponse.close()
                        local appName = string.sub(item.name, 1, -5)
                        local appColor = colors.cyan -- Default color
                        local colorName = string.match(firstLine, "^%-%-%s*(%S+)")
                        if colorName then
                            appColor = getColorFromName(colorName)
                        end
                        table.insert(apps, {item.path, appName, appColor})
                    end
                end
            end
        end
    end
    return apps
end

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
 
    term.write(name)
 
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

local function drawApps(apps)
    local w, h = term.getSize()
    local iconWidth = 5
    local iconHeight = 4
    local iconPadding = 1
    local startX, startY = 2, 3
    local iconsPerRow = math.floor(w / (iconWidth + iconPadding))

    local installedApps = getInstalledApps()

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

    for i, app in ipairs(availableApps) do
        local appPathOnGithub, appName, appColor = unpack(app)
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

local function handleMouseClick(x, y, apps)
    local w, h = term.getSize()
    local iconWidth = 5
    local iconHeight = 4
    local iconPadding = 1
    local startX, startY = 2, 3
    local iconsPerRow = math.floor(w / (iconWidth + iconPadding))

    local barHeight = 3
    local iconWidth = 1
    local iconStart = math.floor((w - iconWidth) / 2) + 1
    local iconY = h - barHeight + 2

    if x >= iconStart and x < iconStart + iconWidth and y == iconY then
        shell.run("OS.lua")
        return true
    end

    local installedApps = getInstalledApps()
 
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

    for i, app in ipairs(availableApps) do
        local xPos = startX + ((i - 1) % iconsPerRow) * (iconWidth + iconPadding)
        local yPos = startY + math.floor((i - 1) / iconsPerRow) * (iconHeight + iconPadding)

        if x >= xPos and x < xPos + iconWidth and y >= yPos and y < yPos + iconHeight then
            local appPathOnGithub = app[1]
            local appName = app[2]
            local url = githubBaseUrl .. appPathOnGithub
            local response = http.get(url)

            if response then
                local newCode = response.readAll()
                response.close()

                if not fs.exists("apps") then
                    fs.makeDir("apps")
                end

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
    local apps = getAppsFromGithub()
    
    while running do
        drawBackground()
        drawTopBar(name)
        drawBottomBar()
        drawApps(apps)

        os.startTimer(1)
        local event, button, x, y = os.pullEvent()
        if event == "mouse_click" then
            if handleMouseClick(x, y, apps) then
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
