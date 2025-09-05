local pastebinID = "w2aT6syk" -- Replace with your Pastebin ID
local scriptName = "paintingProgram.lua" -- Name of this script (with the .lua)
local currentVersion = 3 -- Current version of the script (doesn't matter, just needs to a different number)

-- Function to download and update the script
local function updateScript()
    local url = "https://pastebin.com/raw/" .. pastebinID
    local response = http.get(url)
    
    if response then
        print("Download successful. Reading new code...")
        local newCode = response.readAll()
        response.close()
        
        -- Delete the temporary file if it already exists
        if fs.exists("temp_update.lua") then
            fs.delete("temp_update.lua")
        end
        
        -- Save the new code to a temporary file
        local tempFile = fs.open("temp_update.lua", "w")
        if tempFile then
            tempFile.write(newCode)
            tempFile.close()
        else
            return
        end
        
        -- Schedule the replacement of the current script
        local startupFile = fs.open("startup.lua", "w")
        if startupFile then
            startupFile.write([[
-- Update and Launcher Script
if fs.exists("temp_update.lua") then
    fs.delete("]] .. scriptName .. [[")
    fs.move("temp_update.lua", "]] .. scriptName .. [[")
end
 
-- Launch the main script
shell.run("]] .. scriptName .. [[")
            ]])
            startupFile.close()
        else
            return
        end
        
        os.reboot() -- Restart the computer to apply the update
    else
        print("Failed to fetch update from Pastebin.")
    end
end

-- Function to check for updates
local function checkForUpdates()
    local url = "https://pastebin.com/raw/" .. pastebinID
    local response = http.get(url)
    
    if response then
        local newCode = response.readAll()
        response.close()
        
        -- Extract the version number from the new code
        local newVersion = tonumber(newCode:match("local currentVersion = (%d+)"))
        
        if newVersion and newVersion ~= currentVersion then
            updateScript()
        else
            -- print("No updates available.")
        end
    else
        print("Failed to check for updates.")
    end
end
 
checkForUpdates()

-- Define color mappings (numbers to colors)
local colorMap = {
    [0] = colors.black,   -- 0 = Black
    [1] = colors.white,   -- 1 = White
    [2] = colors.red,     -- 2 = Red
    [3] = colors.blue,    -- 3 = Blue
    [4] = colors.green,   -- 4 = Green
    [5] = colors.yellow,  -- 5 = Yellow
    [6] = colors.orange,  -- 6 = Orange
    [7] = colors.purple,  -- 7 = Purple
    [8] = colors.cyan,    -- 8 = Cyan
    [9] = colors.gray     -- 9 = Gray
}

-- Define the 16x16 pixel art as a 2D table of numbers (using color mappings)
local art = {
    {9, 9, 9, 9, 9, 0, 0, 0, 0, 0, 9, 9, 9, 9, 9, 9},
    {9, 9, 9, 0, 0, 1, 1, 1, 1, 1, 0, 0, 9, 9, 9, 9},
    {9, 9, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 9, 9, 9},
    {9, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 9, 9},
    {9, 0, 1, 0, 1, 0, 1, 1, 1, 1, 1, 1, 1, 0, 9, 9},
    {0, 1, 1, 0, 1, 0, 1, 1, 1, 1, 0, 0, 1, 1, 0, 9},
    {0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 0, 1, 0, 9},
    {0, 1, 2, 1, 2, 1, 2, 1, 1, 1, 1, 1, 0, 1, 0, 9},
    {0, 1, 2, 2, 2, 2, 2, 1, 1, 1, 1, 0, 1, 1, 1, 0},
    {0, 1, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 0},
    {9, 0, 1, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 0},
    {9, 0, 1, 2, 1, 2, 1, 2, 1, 1, 1, 1, 1, 1, 0, 9},
    {9, 9, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 9, 9},
    {9, 9, 9, 0, 0, 0, 1, 1, 1, 1, 0, 0, 9, 9, 9, 9},
    {9, 9, 9, 9, 9, 9, 0, 0, 0, 0, 9, 9, 9, 9, 9, 9},
    {9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9}
}

-- Wrap the monitor peripheral
local monitor = peripheral.find("monitor")
if not monitor then
    error("No advanced monitor found!")
end

-- Get monitor size
local monitorWidth, monitorHeight = monitor.getSize()
monitor.setTextScale(0.5) -- Adjust text scale for better resolution

-- Get art dimensions
local artWidth = #art[1]
local artHeight = #art

-- Calculate scaling factors
local scaleX = math.floor(monitorWidth / artWidth)
local scaleY = math.floor(monitorHeight / artHeight)
local scale = math.min(scaleX, scaleY)

-- Calculate centered position
local startX = math.floor(monitorWidth - (artWidth * scale)) / 2
local startY = math.floor(monitorHeight - (artHeight * scale)) / 2

-- Clear the monitor
monitor.setBackgroundColor(colors.gray)
monitor.clear()

-- Draw the pixel art
for y = 1, artHeight do
    for x = 1, artWidth do
        local colorNumber = art[y][x]
        local color = colorMap[colorNumber] or colors.black -- Default to black if color not found
        monitor.setBackgroundColor(color)
        for dy = 0, scale - 1 do
            for dx = 0, scale - 1 do
                monitor.setCursorPos(startX + (x - 1) * scale + dx, startY + (y - 1) * scale + dy)
                monitor.write(" ")
            end
        end
    end
end