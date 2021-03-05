local Models = {}
local Zones = {}
local Vehicles = {
    distance = 2.0
}
local debug = true
local _entity

Citizen.CreateThread(function()
    RegisterKeyMapping("+playerTarget", "Player Targeting", "keyboard", "LMENU") --Removed Bind System and added standalone version
    RegisterCommand('+playerTarget', playerTargetEnable, false)
    RegisterCommand('-playerTarget', playerTargetDisable, false)
    TriggerEvent("chat:removeSuggestion", "/+playerTarget")
    TriggerEvent("chat:removeSuggestion", "/-playerTarget")
end)

function playerTargetEnable()
    if success then return end
    
    targetActive = true
    
    SendNUIMessage({response = "openTarget"})
    
    while targetActive do
        local plyCoords = GetEntityCoords(GetPlayerPed(-1))
        local hit, coords, entity = RayCastGamePlayCamera(20.0)
        _entity = entity
        if debug and hit and GetEntityType(entity) ~= 0 then
            if DoesEntityExist(entity) then
                print(('entity: %s'):format(entity))
                print(('entity type: %s'):format(GetEntityType(entity)))
                print(('entity model: %s'):format(GetEntityModel(entity)))
            end
        end
        
        if hit == 1 then
            if GetEntityType(entity) ~= 0 then
                for _, model in pairs(Models) do
                    if _ == GetEntityModel(entity) then
                        if #(plyCoords - coords) <= Models[_]["distance"] then
                            
                            success = true
                            
                            SendNUIMessage({response = "validTarget", data = Models[_]["options"]})
                            
                            while success and targetActive do
                                local plyCoords = GetEntityCoords(GetPlayerPed(-1))
                                local hit, coords, entity = RayCastGamePlayCamera(20.0)
                                
                                DisablePlayerFiring(PlayerPedId(), true)
                                
                                if (IsControlJustReleased(0, 24) or IsDisabledControlJustReleased(0, 24)) then
                                    SetNuiFocus(true, true)
                                    SetCursorLocation(0.5, 0.5)
                                end
                                
                                if GetEntityType(entity) == 0 or #(plyCoords - coords) > Models[_]["distance"] then
                                    success = false
                                end
                                
                                Citizen.Wait(1)
                            end
                            SendNUIMessage({response = "leftTarget"})
                        end
                    end
                end
            end
            -- -1126237515
            for _, zone in pairs(Zones) do
                if Zones[_]:isPointInside(coords) then
                    if #(plyCoords - Zones[_].center) <= zone["targetoptions"]["distance"] then
                        
                        success = true
                        
                        SendNUIMessage({response = "validTarget", data = Zones[_]["targetoptions"]["options"]})
                        
                        while success and targetActive do
                            local plyCoords = GetEntityCoords(GetPlayerPed(-1))
                            local hit, coords, entity = RayCastGamePlayCamera(20.0)
                            
                            DisablePlayerFiring(PlayerPedId(), true)
                            
                            if (IsControlJustReleased(0, 24) or IsDisabledControlJustReleased(0, 24)) then
                                SetNuiFocus(true, true)
                                SetCursorLocation(0.5, 0.5)
                            end
                            
                            if not Zones[_]:isPointInside(coords) or #(plyCoords - Zones[_].center) > zone.targetoptions.distance then
                                success = false
                            end
                            
                            Citizen.Wait(1)
                        end
                        SendNUIMessage({response = "leftTarget"})
                    end
                end
            end
            
            if IsEntityAVehicle(entity) and #(plyCoords - coords) <= Vehicles.distance then
                
                success = true
                SendNUIMessage({response = "validTarget"})
                while success and targetActive do
                    local plyCoords = GetEntityCoords(GetPlayerPed(-1))
                    local hit, coords, entity = RayCastGamePlayCamera(20.0)
                    Citizen.Wait(50)
                    
                    if GetEntityType(entity) ~= 0 and DoesEntityExist(entity) and IsEntityAVehicle(entity) then
                        local trunk = GetWorldPositionOfEntityBone(entity, GetEntityBoneIndexByName(entity, 'platelight'))
                        print(#(coords - trunk) < 1.0 and 'at trunk' or 'not at trunk')
                        
                    end
                    
                    if GetEntityType(entity) == 0 or #(plyCoords - coords) > Vehicles.distance then
                        success = false
                    end
                    
                    Citizen.Wait(1)
                end
                SendNUIMessage({response = "leftTarget"})
            end
        end
        Citizen.Wait(250)
    end
end

function playerTargetDisable()
    if success then return end
    
    targetActive = false
    
    SendNUIMessage({response = "closeTarget"})
end

--NUI CALL BACKS

RegisterNUICallback('selectTarget', function(data, cb)
    SetNuiFocus(false, false)
    
    success = false
    
    targetActive = false
    TriggerEvent(data.event, _entity, data.args and data.args or nil)
end)

RegisterNUICallback('closeTarget', function(data, cb)
    SetNuiFocus(false, false)
    
    success = false
    
    targetActive = false
end)

--Functions from https://forum.cfx.re/t/get-camera-coordinates/183555/14

function RotationToDirection(rotation)
    local adjustedRotation =
    {
        x = (math.pi / 180) * rotation.x,
        y = (math.pi / 180) * rotation.y,
        z = (math.pi / 180) * rotation.z
    }
    local direction =
    {
        x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        z = math.sin(adjustedRotation.x)
    }
    return direction
end

function RayCastGamePlayCamera(distance)
    local cameraRotation = GetGameplayCamRot()
    local cameraCoord = GetGameplayCamCoord()
    local direction = RotationToDirection(cameraRotation)
    local destination =
    {
        x = cameraCoord.x + direction.x * distance,
        y = cameraCoord.y + direction.y * distance,
        z = cameraCoord.z + direction.z * distance
    }
    local a, b, c, d, e = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, -1, PlayerPedId(), 0))
    return b, c, e
end

--Exports

function AddCircleZone(name, center, radius, options, targetoptions)
    Zones[name] = CircleZone:Create(center, radius, options)
    Zones[name].targetoptions = targetoptions
end

function AddBoxZone(name, center, length, width, options, targetoptions)
    Zones[name] = BoxZone:Create(center, length, width, options)
    Zones[name].targetoptions = targetoptions
end

function AddPolyzone(name, points, options, targetoptions)
    Zones[name] = PolyZone:Create(points, options)
    Zones[name].targetoptions = targetoptions
end

function AddTargetModel(models, parameteres)
    for _, model in pairs(models) do
        Models[model] = parameteres
    end
end

exports("AddCircleZone", AddCircleZone)

exports("AddBoxZone", AddBoxZone)

exports("AddPolyzone", AddPolyzone)

exports("AddTargetModel", AddTargetModel)

local ATMLocations = {
    vector3(147.62, -1035.73, 29.34),
    vector3(145.91, -1035.16, 29.34),
}

Citizen.CreateThread(function()
    
    local peds = {
        `mp_m_shopkeep_01`,
        `a_m_y_hippy_01`,
        `csb_chef`,
        `a_f_y_hipster_02`,
        `s_m_y_prisoner_01`
    }
    AddTargetModel(peds, {
        options = {
            {
                event = "esx_inventoryhud:openStore",
                icon = "fas fa-dumpster",
                label = "Purchase Items",
            },
            {
                event = "esx_inventoryhud:openStore",
                icon = "fas fa-dumpster",
                label = "This would be a second option....",
            },
        },
        distance = 2.5
    })
    
    local bankers = {
        `a_m_m_prolhost_01`
    }
    AddTargetModel(bankers, {
        options = {
            {
                event = "orp:openBank",
                icon = "fas fa-dumpster",
                label = "Open Bank",
            }
        },
        distance = 2.5
    })
    
    local coffee = {
        690372739,
    }
    AddTargetModel(coffee, {
        options = {
            {
                event = "coffeeevent",
                icon = "fas fa-coffee",
                label = "Coffee",
            },
        },
        distance = 2.5
    })
    
    local water = {
        -742198632,
    }
    AddTargetModel(water, {
        options = {
            {
                event = "coffeeevent",
                icon = "fas fa-coffee",
                label = "Get Water",
            },
        },
        distance = 2.5
    })
    
    local vendingMachines = {
        992069095,
        1114264700,
        -654402915,
    }
    AddTargetModel(vendingMachines, {
        options = {
            {
                event = "coffeeevent",
                icon = "fas fa-coffee",
                label = "Purchase Snacks",
            },
        },
        distance = 2.5
    })
    
    AddBoxZone("PoliceDuty", vector3(441.79, -982.07, 30.69), 0.4, 0.6, {
        name="PoliceDuty",
        heading=91,
        debugPoly=false,
        minZ=30.79,
        maxZ=30.99
    }, {
        options = {
            {
                event = "duty:onoff",
                icon = "far fa-clipboard",
                label = "Sign On/Off Duty",
            }
        },
        distance = 1.5
    })
    
    local chairs = {
        1805980844,
        -99500382,
        -1118419705,
        538002882,
    }
    AddTargetModel(chairs, {
        options = {
            {
                event = "sit:sit-chair",
                icon = "fas fa-coffee",
                label = "Sit",
            },
        },
        distance = 2.5
    })
    
    local atmObjects = {
        -870868698,
        -1364697528,
        506770882,
        -1126237515
    }
    AddTargetModel(atmObjects, {
        options = {
            {
                event = "orp:openAtm",
                icon = "far fa-clipboard",
                label = "Use ATM",
            },
            {
                event = "myATMRobbery:startRob",
                icon = "far fa-clipboard",
                label = "Rob ATM",
            }
        },
        distance = 2.5
    })
    
    for i=1, #ATMLocations do
        --! -- name, center, length, width, options, targetoptions
        AddBoxZone(("ATMZonePoly-%s"):format(tostring(i)), ATMLocations[i], 1.0, 1.0, {
            name=("ATMZonePoly-%s"):format(tostring(i)),
            heading=340,
            debugPoly=false,
            minZ=ATMLocations[i].z-0.15,
            maxZ=ATMLocations[i].z+0.50
        }, {
            options = {
                {
                    event = "orp:openAtm",
                    icon = "far fa-clipboard",
                    label = "Use ATM",
                },
                {
                    event = "myATMRobbery:startRob",
                    icon = "far fa-clipboard",
                    label = "Rob ATM",
                }
            },
            distance = 1.0
        })
    end
    
    local bankerLocations = {
        vector3(241.65, 226.09, 106.29),
        vector3(-111.56, 6469.84, 31.63)
    }
    for i=1, #bankerLocations do
        --! -- name, center, length, width, options, targetoptions
        AddBoxZone(("ATMZone-%s"):format(tostring(i)), bankerLocations[i], 1.0, 1.0, {
            name=("ATMZone-%s"):format(tostring(i)),
            heading=340,
            debugPoly=false,
            minZ=bankerLocations[i].z-0.15,
            maxZ=bankerLocations[i].z+0.70
        }, {
            options = {
                {
                    event = "orp:openAtm",
                    icon = "far fa-clipboard",
                    label = "Use ATM",
                }
            },
            distance = 1.2
        })
    end
    
    local pillboxLower = {
        vector3(346.13, -581.04, 28.8),
        vector3(344.79, -584.74, 28.8)
    }
    for i=1, #pillboxLower do
        
        AddBoxZone(('pillboxLower-%s'):format(tostring(i)), pillboxLower[i], 0.1, 0.2, {
            name=('pillboxLower-%s'):format(tostring(i)),
            heading=340,
            debugPoly=false,
            minZ=pillboxLower[i].z+0.20,
            maxZ=pillboxLower[i].z+0.45
        }, {
            options = {
                {
                    event = "esx_ambulancejob:elevator",
                    icon = "far fa-clipboard",
                    label = "Take Elevator",
                    args = 'lower'
                }
            },
            distance = 1.2
        })
    end
    
    local upperPillbox = {
        vector3(331.97, -597.18, 43.28)
    }
    for i=1, #upperPillbox do
        --! -- name, center, length, width, options, targetoptions
        AddBoxZone(('upperPillbox-%s'):format(tostring(i)), upperPillbox[i], 0.1, 0.2, {
            name=('upperPillbox-%s'):format(tostring(i)),
            heading=340,
            debugPoly=false,
            minZ=upperPillbox[i].z+0.20,
            maxZ=upperPillbox[i].z+0.45
        }, {
            options = {
                {
                    event = "esx_ambulancejob:elevator",
                    icon = "far fa-clipboard",
                    label = "Take Elevator",
                    args = 'upper'
                }
            },
            distance = 1.2
        })
    end
end)

