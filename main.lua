--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.
repeat task.wait() until game:IsLoaded()
if shared.vape then shared.vape:Uninject() end

if identifyexecutor then
	if table.find({'Argon', 'Wave'}, ({identifyexecutor()})[1]) then
		getgenv().setthreadidentity = nil
	end
end

local function validateSecurity()
    local HttpService = game:GetService("HttpService")
    
    if not isfile('newvape/security/validated') then
        game.StarterGui:SetCore("SendNotification", {
            Title = "Security Error",
            Text = "no validation file found",
            Duration = 5
        })
        return false, nil
    end
    
    local validationContent = readfile('newvape/security/validated')
    local success, validationData = pcall(function()
        return HttpService:JSONDecode(validationContent)
    end)
    
    if not success or not validationData then
        game.StarterGui:SetCore("SendNotification", {
            Title = "Security Error",
            Text = "corrupted validation file",
            Duration = 5
        })
        return false, nil
    end
    
    if not validationData.username or not validationData.repo_owner or not validationData.repo_name or not validationData.validated then
        game.StarterGui:SetCore("SendNotification", {
            Title = "Security Error",
            Text = "invalid validation data",
            Duration = 5
        })
        return false, nil
    end
    
    if not isfile('newvape/security/'..validationData.username) then
        game.StarterGui:SetCore("SendNotification", {
            Title = "Security Error",
            Text = "user validation missing",
            Duration = 5
        })
        return false, nil
    end
    
    local EXPECTED_REPO_OWNER = "itzmosaa"
    local EXPECTED_REPO_NAME = "krylon-testing"
    
    if validationData.repo_owner ~= EXPECTED_REPO_OWNER or validationData.repo_name ~= EXPECTED_REPO_NAME then
        game.StarterGui:SetCore("SendNotification", {
            Title = "Security Error",
            Text = "unauthorized repository detected",
            Duration = 5
        })
        return false, nil
    end
    
    local function decodeBase64(data)
        local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
        data = string.gsub(data, '[^'..b..'=]', '')
        return (data:gsub('.', function(x)
            if (x == '=') then return '' end
            local r,f='',(b:find(x)-1)
            for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
            return r;
        end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
            if (#x ~= 8) then return '' end
            local c=0
            for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
            return string.char(c)
        end))
    end

    local ACCOUNT_SYSTEM_URLS = {
        "https://raw.githubusercontent.com/itzmosaa/krylon-testing/main/AccountSystem.lua",
        "https://raw.githubusercontent.com/itzmosaa/krylon-whitelists/main/AccountSystem.lua"
    }

    local function validateSecurity()
        -- Account system removed. Always allow loading.
        -- If a local validation file exists, use its username; otherwise return nil.
        local HttpService = game:GetService("HttpService")
        if isfile('newvape/security/validated') then
            local ok, data = pcall(function()
                return HttpService:JSONDecode(readfile('newvape/security/validated'))
            end)
            if ok and data and data.username then
                return true, data.username
            end
        end
        return true, nil
    end
local function startActiveCheck()
    if activeCheckRunning then return end
    activeCheckRunning = true
    
    while task.wait(30) do
        if shared.vape then
            local isActive = checkAccountActive()
            
            if not isActive then
                game.StarterGui:SetCore("SendNotification", {
                    Title = "Access Revoked",
                    Text = "Your account has been deactivated.",
                    Duration = 5
                })
                
                task.wait(2)
                
                if shared.vape and shared.vape.Uninject then
                    shared.vape:Uninject()
                else
                    shared.vape = nil
                    if getgenv and getgenv().vape then
                        getgenv().vape = nil
                    end
                end
                break
            end
        else
            break
        end
    end
    activeCheckRunning = false
end

local function finishLoading()
	vape.Init = nil
	vape:Load()
	task.spawn(function()
		repeat
			vape:Save()
			task.wait(10)
		until not vape.Loaded
	end)

    if shared.ValidatedUsername then
        task.spawn(function()
            startActiveCheck()
        end)
    end

	local teleportedServers
	vape:Clean(playersService.LocalPlayer.OnTeleport:Connect(function()
		if (not teleportedServers) and (not shared.VapeIndependent) then
			teleportedServers = true
			local teleportScript = [[
				shared.vapereload = true
				if shared.VapeDeveloper then
					loadstring(readfile('newvape/loader.lua'), 'loader')()
				else
					loadstring(game:HttpGet('https://raw.githubusercontent.com/itzmosaa/krylon-testing/'..readfile('newvape/profiles/commit.txt')..'/loader.lua', true), 'loader')()
				end
			]]
			if shared.VapeDeveloper then
				teleportScript = 'shared.VapeDeveloper = true\n'..teleportScript
			end
			if shared.VapeCustomProfile then
				teleportScript = 'shared.VapeCustomProfile = "'..shared.VapeCustomProfile..'"\n'..teleportScript
			end
			vape:Save()
			queue_on_teleport(teleportScript)
		end
	end))

	if not shared.vapereload then
		if not vape.Categories then return end
		if vape.Categories.Main.Options['GUI bind indicator'].Enabled then
			vape:CreateNotification('Finished Loading', 'Welcome, '..shared.ValidatedUsername..'! '..(vape.VapeButton and 'Press the button in the top right to open GUI' or 'Press '..table.concat(vape.Keybind, ' + '):upper()..' to open GUI'), 5)
		end
	end
end

if not isfile('newvape/profiles/gui.txt') then
	writefile('newvape/profiles/gui.txt', 'new')
end
local gui = readfile('newvape/profiles/gui.txt')

if not isfolder('newvape/assets/'..gui) then
	makefolder('newvape/assets/'..gui)
end
vape = loadstring(downloadFile('newvape/guis/'..gui..'.lua'), 'gui')()
shared.vape = vape

if not shared.VapeIndependent then
	loadstring(downloadFile('newvape/games/universal.lua'), 'universal')()
	if isfile('newvape/games/'..game.PlaceId..'.lua') then
		loadstring(readfile('newvape/games/'..game.PlaceId..'.lua'), tostring(game.PlaceId))(...)
	else
		if not shared.VapeDeveloper then
			local suc, res = pcall(function()
				return game:HttpGet('https://raw.githubusercontent.com/itzmosaa/krylon-testing/'..readfile('newvape/profiles/commit.txt')..'/games/'..game.PlaceId..'.lua', true)
			end)
			if suc and res ~= '404: Not Found' then
				loadstring(downloadFile('newvape/games/'..game.PlaceId..'.lua'), tostring(game.PlaceId))(...)
			end
		end
	end
	finishLoading()
else
	vape.Init = finishLoading
	return vape
end
