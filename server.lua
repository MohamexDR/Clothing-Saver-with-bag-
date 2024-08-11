

local OldESX = false -- enable if using old esx


if OldESX == true then
ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
else
    ESX = exports["es_extended"]:getSharedObject()
end

-- Register Server Callback to Get Outfit by Code
ESX.RegisterServerCallback('esx_outfit:getOutfitByCode', function(source, cb, code)
    MySQL.Async.fetchAll('SELECT * FROM outfits WHERE code = @code', {
        ['@code'] = code
    }, function(result)
        if result[1] then
            cb(json.decode(result[1].outfit))
        else
            cb(nil)
        end
    end)
end)

ESX.RegisterServerCallback('esx_outfit:getPlayerOutfits', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    MySQL.Async.fetchAll('SELECT code FROM outfits WHERE identifier = @identifier', {
        ['@identifier'] = xPlayer.identifier
    }, function(result)
        local codes = {}
        for _, outfit in ipairs(result) do
            table.insert(codes, outfit.code)
        end
        cb(codes)
    end)
end)

RegisterServerEvent('esx_outfit:saveOutfit')
AddEventHandler('esx_outfit:saveOutfit', function(code, outfit)
    local xPlayer = ESX.GetPlayerFromId(source)
    MySQL.Async.execute('INSERT INTO outfits (identifier, code, outfit) VALUES (@identifier, @code, @outfit)', {
        ['@identifier'] = xPlayer.identifier,
        ['@code'] = code,
        ['@outfit'] = json.encode(outfit)
    }, function(rowsChanged)
        
    end)
end)

-- Event to Handle Using the Clothing Bag
RegisterServerEvent('clothingBag:useBag')
AddEventHandler('clothingBag:useBag', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    local coords = xPlayer.getCoords()

    xPlayer.removeInventoryItem('clothing_bag', 1)

    MySQL.Async.fetchAll('SELECT code FROM outfits WHERE identifier = @identifier', {
        ['@identifier'] = xPlayer.identifier
    }, function(result)
        local outfitCodes = {}
        for _, outfit in ipairs(result) do
            table.insert(outfitCodes, outfit.code)
        end
        TriggerClientEvent('esx_outfit:useClothingBag', source, coords, outfitCodes)
    end)
end)

-- Event to Handle Picking Up the Bag
RegisterServerEvent('esx_outfit:pickupBag')
AddEventHandler('esx_outfit:pickupBag', function()
    local xPlayer = ESX.GetPlayerFromId(source)
    xPlayer.addInventoryItem('clothing_bag', 1)
end)

-- Register the Item as Usable
ESX.RegisterUsableItem('clothing_bag', function(source)
    TriggerEvent('clothingBag:useBag', source)
end)


ESX.RegisterUsableItem('clothing_bag', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    TriggerEvent('clothingBag:useBag', source)
    xPlayer.removeInventoryItem('clothing_bag', 1)
end)

-- Event to Return Bag to Inventory
RegisterServerEvent('esx_outfit:returnBagToInventory')
AddEventHandler('esx_outfit:returnBagToInventory', function()
    local xPlayer = ESX.GetPlayerFromId(source)
    xPlayer.addInventoryItem('clothing_bag', 1)
end)