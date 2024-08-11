local outfitBlip = nil
local spawnedBag = nil
local bagPlaced = false

local OldESX = false -- enable if using old esx

if OldESX == true then
local ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
else
    ESX = exports["es_extended"]:getSharedObject()
end
-- Save Current Outfit
RegisterCommand('saveoutfit', function()
    local playerPed = PlayerPedId()
    local outfit = {
        components = {}
    }

    -- Get the player's current outfit components
    for i = 0, 11 do
        outfit.components[i] = {
            drawable = GetPedDrawableVariation(playerPed, i),
            texture = GetPedTextureVariation(playerPed, i),
            palette = GetPedPaletteVariation(playerPed, i)
        }
    end

    -- Generate a random code for the outfit
    local code = tostring(math.random(100000, 999999))

    -- Trigger the server event to save the outfit with the generated code
    TriggerServerEvent('esx_outfit:saveOutfit', code, outfit)
    ESX.ShowNotification('Outfit saved with code: ' .. code)
end)
RegisterCommand('pickupbag', function()
    if bagPlaced and DoesEntityExist(bagEntity) then
        DeleteObject(bagEntity)
        bagPlaced = false
        bagEntity = nil

        if DoesBlipExist(outfitBlip) then
            RemoveBlip(outfitBlip)
            outfitBlip = nil
        end

        TriggerServerEvent('esx_outfit:pickupBag')
        ESX.ShowNotification('You picked up the clothing bag.')
    else
        ESX.ShowNotification('No bag to pick up.')
    end
end)
-- Use Clothing Bag
RegisterNetEvent('esx_outfit:useClothingBag')
AddEventHandler('esx_outfit:useClothingBag', function(coords, outfitCodes)
    local playerPed = PlayerPedId()

    -- Remove the old bag if it exists
    if spawnedBag ~= nil then
        DeleteObject(spawnedBag)
        RemoveBlip(outfitBlip)
        spawnedBag = nil
    end

    -- Create the bag prop
    local model = GetHashKey('prop_cs_heist_bag_01')
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(1)
    end
    local bagPlaced = true

    spawnedBag = CreateObject(model, coords.x, coords.y, coords.z, true, true, true)
    PlaceObjectOnGroundProperly(spawnedBag)
    SetEntityAsMissionEntity(spawnedBag, true, true)

    -- Add a blip for the bag
    outfitBlip = AddBlipForEntity(spawnedBag)
    SetBlipSprite(outfitBlip, 52) -- Bag icon
    SetBlipColour(outfitBlip, 3)
    SetBlipScale(outfitBlip, 0.8)
    SetBlipAsShortRange(outfitBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Clothing Bag')
    EndTextCommandSetBlipName(outfitBlip)

    -- Monitor the player's proximity to the bag
    CreateThread(function()
        while DoesEntityExist(spawnedBag) do
            local playerCoords = GetEntityCoords(playerPed)
            local bagCoords = GetEntityCoords(spawnedBag)
            local distance = #(playerCoords - bagCoords)

            if distance <= 1.5 then
                ESX.ShowHelpNotification('Press E to open the clothing bag')

                if IsControlJustReleased(0, 38) then -- "E" key
                    OpenClothingBagMenu(outfitCodes)
                end
            end

            Wait(0)
        end
    end)
end)

-- Function to open the clothing bag menu
function OpenClothingBagMenu(outfitCodes)
    local elements = {
        {label = 'Save Outfit', value = 'save_outfit', mdi = 'hanger'},
        {label = 'Remove Bag', value = 'remove_bag', mdi = 'export'}
    }
    
    for _, code in ipairs(outfitCodes) do
        table.insert(elements, {label = 'Outfit Code: ' .. code, value = code, mdi = 'drama-masks'})
    end

    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'clothing_bag_menu', {
        title = 'Select Outfit',
        align = 'left',
        elements = elements
    }, function(data, menu)
        local selectedValue = data.current.value
        
        if selectedValue == 'save_outfit' then
            -- Logic to save the current outfit
            ExecuteCommand('saveoutfit')
        
        elseif selectedValue == 'remove_bag' then
            -- Logic to remove the clothing bag
            ExecuteCommand('pickupbag')
        
        else
            -- Apply the selected outfit
            ESX.TriggerServerCallback('esx_outfit:getOutfitByCode', function(outfit)
                if outfit and outfit.components then
                    local playerPed = PlayerPedId()
                    for i = 0, 11 do
                        local component = outfit.components[tostring(i)] -- Use tostring(i) to match keys
                        if component then
                            SetPedComponentVariation(playerPed, i, component.drawable, component.texture, component.palette)
                        end
                    end
                    ESX.ShowNotification('Outfit applied successfully')
                else
                    ESX.ShowNotification('Invalid code or outfit data')
                end
            end, selectedValue)
        end

        menu.close()
    end, function(data, menu)
        menu.close()
    end)
end


-- Remove the Bag
RegisterNetEvent('esx_outfit:removeBag')
AddEventHandler('esx_outfit:removeBag', function()
    if spawnedBag ~= nil then
        DeleteObject(spawnedBag)
        RemoveBlip(outfitBlip)
        TriggerServerEvent('esx_outfit:returnBagToInventory')
    end
end)