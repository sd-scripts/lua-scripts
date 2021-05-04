script_author('S&D Scripts')
script_name('MyCar')
script_version('1.2.0')
script_version_number(6) 
 
local sampev      =   require 'samp.events'
local imgui       =   require 'imgui'
local encoding    =   require 'encoding'
local keys        =   require 'vkeys'
local inicfg      =   require 'inicfg'

local limadd, imadd 	= pcall(require, 'imgui_addons')
local lrkeys, rkeys 	= pcall(require, 'rkeys')
 
encoding.default = 'CP1251'
u8 = encoding.UTF8

local data = {}
local cars = {}
local car_info = {}
local target = {i={},state=false}
local vehicle = {i={},state=false}

local main_window = imgui.ImBool(false)
local target_window = imgui.ImBool(false)
local work = false
local working = false
local unloading_cars = false
local text_loads = '�������� ������...'
local text_load = '�������� ������...'
local state = 0
local bindID = 0
local step = 0
local font_flag = require('moonloader').font_flag
local font = renderCreateFont("Arial", 10, font_flag.BOLD + font_flag.SHADOW + font_flag.BORDER)

local cfg = inicfg.load({
    CheckBox = {
        enter = true,
        unloading = false,
        fuel = true,
        key = true,
        hint = true
    },
    HotKey = {
        lock = "[76]",
        keys = "[75]",
        main = "[18,77]",
        interaction = "[88]",
        style = "[71]"
    }
}, 'MyCar')

local CheckBox = {
    ['enter'] = imgui.ImBool(cfg.CheckBox.enter),
    ['unloading'] = imgui.ImBool(cfg.CheckBox.unloading),
    ['fuel'] = imgui.ImBool(cfg.CheckBox.fuel),
    ['key'] = imgui.ImBool(cfg.CheckBox.key),
    ['hint'] = imgui.ImBool(cfg.CheckBox.hint)
}

local ActiveMenus = {
	v = decodeJson(cfg.HotKey.main)
}
local ActiveKey = {
	v = decodeJson(cfg.HotKey.keys)
}
local ActiveLock = {
	v = decodeJson(cfg.HotKey.lock)
}
local ActiveStyle = {
    v = decodeJson(cfg.HotKey.style)
}
local ActiveInteraction = {
	v = decodeJson(cfg.HotKey.interaction)
}

local tLastKeys = {}

function checkServer(ip)
    local tServers = {
        ['185.169.134.3'] = 'Phoenix',
        ['185.169.134.4'] = 'Tucson',
        ['185.169.134.43'] = 'Scottdale',
        ['185.169.134.44'] = 'Chandler',
        ['185.169.134.45'] = 'Brainburg',
        ['185.169.134.5'] = 'SaintRose',
        ['185.169.134.59'] = 'Mesa',
        ['185.169.134.61'] = 'Red Rock',
        ['185.169.134.107'] = 'Yuma',
        ['185.169.134.109'] = 'Surprise',
        ['185.169.134.166'] = 'Prescott',
        ['185.169.134.171'] = 'Glendale',
        ['185.169.134.172'] = 'Kingman',
        ['185.169.134.173'] = 'Winslow',
        ['185.169.134.174'] = 'Payson'
    }
	return tServers[ip]
end

function sampev.onShowDialog(id, style, title, b1,b2,text)
    if id == 1162 then
        if work and carid then
            sampSendDialogResponse(1162, 1, cars[carid]['id'], -1)
        end  

        local i = 0
        local t = {}
        cars = {}
        for v in string.gmatch(text, '[^\n]+') do
            if v:match('%{FFFFFF%} %w+') then
                t = {
                    name = v:match('%{FFFFFF%}%s+(.+)%('),
                    id = i,
                    spawn = true
                }
            else
                t = {
                    name = v:match('(.+)%('),
                    id = i,
                    spawn = true
                }
            end
            table.insert(cars, t)
            i = i + 1
        end
        
        command = '/keys'; id_dialog = 1162; cars_info = '����� ���������'
        main_window.v = true
        sampSendDialogResponse(id, 0, nil, nil)
        return false
    end
    if id == 1163 then
        if title:find('{BFBBBA}����������� ��� .+ %(%d+%)') then
            if work then 
                work = false
            else
                local l = 0
                for v in string.gmatch(text, '[^\n]+') do
                    if l == 0 then --�������/�������
                        if v:match('%{......%}�������') then door_state = true else door_state = false end
                    end
                    if l == 1 then --�����
                        if v:match('%{......%}�������� �����') then key_state = false else key_state = true end
                    end
                    if l == 7 then --����� ����
                        if v:match('%{......%}����� ���� %[ %{......%}Sport%{......%} %]') then drive_state = false else drive_state = true end
                    end
                    if l == 8 then --ABS
                        if v:match('������� ABS  %[ %{......%}���%{......%} %]') then abs_state = true else abs_state = false end
                    end
                    l = l + 1
                end
                sampSendDialogResponse(1163, 1, 5, -1)
            end
 
       
            if state == 2 then
                sampSendDialogResponse(1163, 1, 0, -1)
                state = 0
            end
            if state == 3 then
                sampSendDialogResponse(1163, 1, 1, -1)
                state = 0
            end
            if state == 4 then
                sampSendDialogResponse(1163, 1, 2, -1)
                state = 0
            end
            if state == 5 then
                sampSendDialogResponse(1163, 1, 3, -1)
                state = 0
            end
            if state == 6 then
                sampSendDialogResponse(1163, 1, 4, -1)
                state = 0
            end
            if state == 7 then
                sampSendDialogResponse(1163, 1, 6, -1)
                state_spawn = false
                main_window.v = false
                sampSendChat('/keys')
                state = 0
            end
            if state == 8 then
                sampSendDialogResponse(1163, 1, 7, -1)
                state = 0
            end
            if state == 9 then
                sampSendDialogResponse(1163, 1, 8, -1)
                state = 0
            end
            if state == 10 then
                sampSendDialogResponse(1163, 1, 9, -1)
                state = 0
            end

 
        else
            if work then
                sampSendDialogResponse(1163, 1, 0, -1)
            else
                sampSendDialogResponse(1163, 0, nil, nil)
            end
        end

        return false
    end


    if id == 162 then
        if work and carid then
            sampSendDialogResponse(162, 1, cars[carid]['id'], -1)
        end          
 
        local i = 0
        local t = {}
        cars = {}
        for v in string.gmatch(text, '[^\n]+') do
            if v:match('%[�� ���������%]') then
                t = {
                    name = v:match('%{F05959%}%[�� ���������%]%{FFFFFF%}%s+(%w+)'),
                    id = i,
                    spawn = false
                }
            elseif v:match('%[������������%]') then
                t = {
                    name = v:match('%{......%}%[������������%]%{FFFFFF%}%s+(%w+)'),
                    id = i,
                    spawn = false,
                    pfine = true
                }
            elseif v:match('%{FFFFFF%} %w+') then
                t = {
                    name = v:match('%{FFFFFF%}%s+(.+)%('),
                    id = i,
                    spawn = true
                }
            else
                t = {
                    name = v:match('%s+(.+)%('),
                    id = i,
                    spawn = true
                }
            end
            table.insert(cars, t)
            i = i + 1
        end

        if unloading_cars then
            for k, v in pairs(cars) do 
                if v.spawn then
                    work = true
                    sampSendDialogResponse(162, 1, v.id, -1)
                end
            end
            if not work then
                unloading_cars = false
            end
        else
            command = '/cars'; id_dialog = 162; cars_info = '��� ���������'
            if not target_window.v and not work then 
                main_window.v = true 
            end
        end
        sampSendDialogResponse(id, 0, nil, nil)
        return false
    end
    if id == 163 then
        if title:find('{BFBBBA}����������� ��� .+ %(%d+%)') then
            if work then
                work = false
                if unloading_cars then
                    sampSendDialogResponse(163, 1, 11, 1)
                end
                if working then
                    working = false
                    if main_window.v then 
                        carname = cars[carid]['name']; state_spawn = cars[carid]['spawn']; sampSendChat('/cars'); sampSendDialogResponse(162, 1, cars[carid]['id'], -1)
                    end
                end
                if not state_spawn then
                    carid = nil
                end
            else
                local l = 0
                for v in string.gmatch(text, '[^\n]+') do
                    if l == 0 then --�������/�������
                        if v:match('%{......%}�������') then door_state = true else door_state = false end
                    end
                    if l == 1 then --�����
                        if v:match('%{......%}�������� �����') then key_state = false else key_state = true end
                    end
                    if l == 7 then --����� ����
                        if v:match('%{......%}����� ���� %[ %{......%}Sport%{......%} %]') then drive_state = false else drive_state = true end
                    end
                    if l == 8 then --ABS
                        if v:match('������� ABS  %[ %{......%}���%{......%} %]') then abs_state = true else abs_state = false end
                    end
                    if l == 10 then --�������� ��� �����������
                        if v:find('��������� ��� �����������') or v:find('�� ��������� ��� �����������') then text_loads = v end
                    end
                    l = l + 1
                end

                sampSendDialogResponse(163, 1, 5, -1)
            end
 
            if state == 1 then
                sampSendDialogResponse(163, 1, 11, -1)
                state = 0
                state_spawn = false
                carid = nil
            end
            if state == 2 then
                sampSendDialogResponse(163, 1, 0, -1)
                state = 0
            end
            if state == 3 then
                sampSendDialogResponse(163, 1, 1, -1)
                state = 0
            end
            if state == 4 then
                sampSendDialogResponse(163, 1, 2, -1)
                state = 0
            end
            if state == 5 then
                sampSendDialogResponse(163, 1, 3, -1)
                state = 0
            end
            if state == 6 then
                sampSendDialogResponse(163, 1, 4, -1)
                state = 0
            end
            if state == 7 then
                sampSendDialogResponse(163, 1, 6, -1)
                state = 0
                car_info[1].intermediary = 'The State'
            end
            if state == 8 then
                sampSendDialogResponse(163, 1, 7, -1)
                state = 0
            end
            if state == 9 then
                sampSendDialogResponse(163, 1, 8, -1)
                state = 0
            end
            if state == 10 then
                sampSendDialogResponse(163, 1, 9, -1)
                state = 0
            end
            if state == 11 then
                sampSendDialogResponse(163, 1, 10, -1)
                state = 0
                if text_loads == '��������� ��� �����������' then
                    text_loads = '�� ��������� ��� �����������'
                elseif text_loads == '�� ��������� ��� �����������' then
                    text_loads = '��������� ��� �����������'
                end
            end
        else
            if work then
                if loading then
                    sampSendDialogResponse(163, 1, 1, -1)
                    work = false
                    loading = false
                    if text_load == '��������� ��� �����������' then
                        text_load = '�� ��������� ��� �����������'
                    elseif text_load == '�� ��������� ��� �����������' then
                        text_load = '��������� ��� �����������'
                    end
                else
                    sampSendDialogResponse(163, 1, 0, -1)
                    work = false
                    carid = nil
                end
            else
                --sampSendDialogResponse(163, 0, nil, nil)
                for v in string.gmatch(text, '[^\n]+') do
                    if v:find('��������� ��� �����������') or v:find('�� ��������� ��� �����������') then text_load = v end
                end
            end
        end

        return false
    end
    if id == 6971 and style == 2 then
        sampSendDialogResponse(id, 1, parkingstate, -1)
        parkingstate = nil
        return false
    end
    if id == 0 and style == 0 and title == '{BFBBBA}����������' and (main_window.v or target_window.v) then
        car_info = {}
        local t = {
            carname = text:match('%{FFFFFF%}���������%: %{73B461%}(.+)%{FFFFFF%}.+��������'),  
            owner = text:match('��������: {......}(%w+_%w+){......}'),
            intermediary = text:match('���������%: %{73B461%}(%D+)%{FFFFFF%}'),
            mileage = text:match('������%: %{73B461%}(%d+ ��.)%{FFFFFF%}'),
            tax = text:match('�����%: %{73B461%}(%d+)%{FFFFFF%} %/ 150 000'),
            fine = text:match('�����%: %{73B461%}(%d+)%{FFFFFF%} %/ 80 000'),
            recovery_penalty = text:match('����� �� ��������������%: %{73B461%}($%d+)%{FFFFFF%}'),
            price = text:match('���� ������� � ����%:%s%{......%}($.+).+�����'),
            car_number = text:match('����� ����������%:.+{......}(.+){......}.+��������'),
            car_health_min = text:match('�������� ����������%: %{F57449%}(%d+.%d)/%d+.%d%{FFFFFF%}'),
            car_health_max = text:match('�������� ����������%: %{F57449%}%d+.%d/(%d+.%d)%{FFFFFF%}'),
            state = text:match('��������� ����%: %{F57449%}(%d+)/100%{FFFFFF%}'),
            oil = text:match('��������� �����%: %{F57449%}%{......%}(%X+)%{FFFFFF%}'),
            insurance_damage = text:match('��������� %(�� �����������%)%: %{......%}(%X+)%{FFFFFF%}'),
            insurance_meeting = text:match('��������� %(�� ���%)%: %{......%}.+(�� [%d%:%s%.]+).+%{FFFFFF%}'),
        }
        table.insert(car_info, t)
        servercarid = car_info[1].carname:match('%w+%[(%d+)%]')
        sampSendDialogResponse(id, 0, nil, nil)
        return false
    end
end

function refueling()
    wait(50)
    sampSendClickTextdraw(idtextdraw_change)
    wait(30)
    sampSendClickTextdraw(idtextdraw_fill)
end

function sampev.onDisplayGameText(style, time, text)
    if style == 3 then
        if text:match('CAR%~[gr]%~ (%u+)%~n%~%/lock') then door_state = not door_state end
        if text:match('Style%:.+%~(%w+)%!') then drive_state = not drive_state end
        if text:match('ABS%: .+%~(%u+)%!') then abs_state = not abs_state end
    end
end

function sampev.onShowTextDraw(id, data)
    if data.text == 'DIESEL' and cfg.CheckBox.fuel then step = 1 end
    if data.text:find('%$%d+') and step == 1 then step = 2; idtextdraw_money = id end
    if data.text:find('LD%_BEAT%:chit') and data.lineWidth == 19 and step == 2 then step = 3; idtextdraw_change = id end
    if data.text:find('FILL') and step == 3 then step = 4; idtextdraw_fill = id; sampSendClickTextdraw(idtextdraw_money); lua_thread.create(refueling) end
end
 
function sampev.onServerMessage(color,text)
    if text:find('������ ������� ������������ � ����� ���� ����, ������� ������� ������������ � ������� ����') then
        load_status = not load_status
        loads_status = not loads_status
        if text_loads == '��������� ��� �����������' then
            text_loads = '�� ��������� ��� �����������'
        elseif text_loads == '�� ��������� ��� �����������' then
            text_loads = '��������� ��� �����������'
        end
        if text_load == '��������� ��� �����������' then
            text_load = '�� ��������� ��� �����������'
        elseif text_load == '�� ��������� ��� �����������' then
            text_load = '��������� ��� �����������'
        end
    end
    if text:find('�������%(�%) ����� �� ����� ���������') or text:find('�������%(�%) ����� � ����� ���������') then key_state = not key_state end
    if text:find('��������� ��������� �� �������') then return false end
    if text:find('����� �� ���������') and CheckBox['enter'].v then
        sampSendChat('/key'); sampSendChat('/engine') 
        return false 
    end
    if text:find('�� �� � ����� ����') and CheckBox['key'].v then 
        lua_thread.create(function()
            CheckBox['key'].v = false
            wait(700)
            CheckBox['key'].v = true
        end)
        return false 
    end    
    if text:find('������ ��������� ����� ���� ���� ������������, ������� ��������� ���� ����') and working then
        working = false
    end
    if cfg.CheckBox.fuel then
        if text:find('������ ��� ������� �� �������� ��� ������ ����������') then lua_thread.create(refueling) return false end
        if text:find('����������� ������ ����� ������� ��� ������� � ��� ���%-��') or text:find('�� ������ ��������� ������ ��� %- ����� �� ��������� �������') then return false end
    end
    if text:find('������� ���. �������.') then return false end
end
 
function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end

    local update_file = getWorkingDirectory() .. '\\mycar.json';
    downloadUrlToFile('https://raw.githubusercontent.com/sd-scripts/lua-scripts/main/mycar.json', update_file, function(id, status, p1, p2)
        if status == 6 then    
            local f = io.open(update_file, 'r+');
            if f then
                data = decodeJson(f:read('a*'));
                f:close();
                os.remove(update_file)
            end
        end
    end)

    if not doesFileExist('moonloader/config/MyCar.ini') then
        if inicfg.save(cfg, 'MyCar.ini') then print('{FF8C00}��������������: {ffffff}���� ������������ �� ������. ������ ����: {00ff00}config\\MyCar.ini') end
    end
    
    while not sampIsLocalPlayerSpawned() do wait(120) end
    
    nameServ = checkServer(select(1, sampGetCurrentServerAddress()))
    
    if not nameServ then
		print('{ff0000}������: {ffffff}������ �������� ������ �� ������� {FA8072}Arizona RP.')
		thisScript():unload()
    end

    if cfg.CheckBox.unloading then
        unloading_cars = true; sampSendChat('/cars')
    end

    if lrkeys then
        bindMenu = rkeys.registerHotKey(ActiveMenus.v, true, function ()
            if not main_window.v then sampSendChat('/cars') else main_window.v = false end   
        end)
        bindKey = rkeys.registerHotKey(ActiveKey.v, true, function ()
            if isCharInAnyCar(PLAYER_PED) then 
                if not sampIsChatInputActive() and not sampIsDialogActive() and not isSampfuncsConsoleActive() then
                    sampSendChat('/key')
                end
            end   
        end)
        bindLock = rkeys.registerHotKey(ActiveLock.v, true, function ()
            if not sampIsChatInputActive() and not sampIsDialogActive() and not isSampfuncsConsoleActive() then
                sampSendChat('/lock')  
            end
        end)
        bindStyle = rkeys.registerHotKey(ActiveStyle.v, true, function ()
            if not sampIsChatInputActive() and not sampIsDialogActive() and not isSampfuncsConsoleActive() and isCharInAnyCar(PLAYER_PED) then
                sampSendChat('/style')  
            end
        end)
    end

    while true do
        target.check()
        vehicle.check()
		if (isKeyJustPressed(keys.VK_F) or isKeyJustPressed(keys.VK_RETURN)) and CheckBox['key'].v then         
            if isCharInAnyCar(playerPed) and not isSampfuncsConsoleActive() and not sampIsChatInputActive() and not sampIsDialogActive() and (string.format('%4.2f', getCarSpeed(storeCarCharIsInNoSave(playerPed))) < '30') then    
                sampSendChat('/key')	
            end  
        end
        if isKeyJustPressed(cfg.HotKey.interaction:match('%[(%d+)%]')) then
            if target.state then 
                target_window.v = true; sampSendChat('/cars')
            elseif vehicle.state and not isSampfuncsConsoleActive() and not sampIsChatInputActive() and not sampIsDialogActive() then
                target_window.v = true
            end
        end
        wait(0)
        imgui.Process = main_window.v or target_window.v
    end
end

function vehicle.check()
    if cfg.HotKey.interaction ~= '{}' and not isCharInAnyCar(playerPed) and not target_window.v then
        for k,v in ipairs(getAllVehicles()) do
            if isCarOnScreen(v) then
                local carPos = {getCarCoordinates(v)}
                local myPos = {getCharCoordinates(playerPed)}
                if (getDistanceBetweenCoords3d(myPos[1], myPos[2], myPos[3], carPos[1], carPos[2], carPos[3]) < 2) then
                    local result, x, y, z, w, h = convert3DCoordsToScreenEx(carPos[1], carPos[2], carPos[3], false, false)
                    if result then
                        vehicle.state = true
                        vehicle.time = os.clock() + 1
                        vehicle.i.model = getCarModel(v)
                        if not target_window.v and CheckBox['hint'].v then renderFontDrawText(font, '( '..table.concat(rkeys.getKeysName(ActiveInteraction.v), " + ")..' )', x, y, 0xFFA9A9A9) end
                    end
                end
            end
        end
    end

    if vehicle.state then
        if vehicle.state and not target_window.v then
            if vehicle.time <= os.clock() then
                vehicle.state = false
                vehicle.i = {}
            end
        end
    end
end

function target.check()
    if cfg.HotKey.interaction ~= '{}' then
        local result, ped = getCharPlayerIsTargeting(player)
        if result and not target.state then 
            local _, pID = sampGetPlayerIdByCharHandle(ped)
            local x, y, z = getCharCoordinates(ped) -- ���������� ����������� ������
            local x1, y1, z1 = getCharCoordinates(playerPed) -- ���������� ���������� ������
            local distance = getDistanceBetweenCoords3d(x1,y1,z1,x,y,z) -- ���������� ��������� �� ����������� ������ �� ����������
            if (pID >= 0 and pID <= 1000) and (distance <= 2) then
                if CheckBox['hint'].v then
                    sampCreate3dTextEx(777, '( '..table.concat(rkeys.getKeysName(ActiveInteraction.v), " + ")..' )', 0xffA9A9A9, 0, 0, -0.75, 7, false, pID, -1)
                end
                target.i.id, target.i.name, target.i.lvl = pID, sampGetPlayerNickname(pID), sampGetPlayerScore(pID)
                target.state = true
                target.time = os.clock() + 2
            end
        end
    end
    
    if target.state then
        vehicle.state = false; vehicle.i = {}
        if target.state and not target_window.v then
            if target.time <= os.clock() then 
                target.state = false
                target.i = {}
                if CheckBox['hint'].v then sampDestroy3dText(777) end
            end
        end
    end
end

function onWindowMessage(msg, wparam, lparam)
    if msg == 0x100 or msg == 0x101 then
        if (wparam == keys.VK_ESCAPE and (main_window.v or target_window.v)) and not isPauseMenuActive() then
            consumeWindowMessage(true, false)
            if msg == 0x101 then
                main_window.v = false; target_window.v = false
            end
        end
    end
end

function sampGetVehicleModelById(vehicleId) -- ������� ��������� ����� ���������� �� ��� ���������� id
    local ovehicleNames = {"Landstalker","Bravura","Buffalo","Linerunner","Perrenial","Sentinel","Dumper","Firetruck","Trashmaster","Stretch","Manana","Infernus","Voodoo","Pony","Mule","Cheetah","Ambulance","Leviathan","Moonbeam","Esperanto","Taxi","Washington","Bobcat","Whoopee","BFInjection","Hunter","Premier","Enforcer","Securicar","Banshee","Predator","Bus","Rhino","Barracks","Hotknife","Trailer","Previon","Coach","Cabbie","Stallion","Rumpo","RCBandit","Romero","Packer","Monster","Admiral","Squalo","Seasparrow","Pizzaboy","Tram","Trailer","Turismo","Speeder","Reefer","Tropic","Flatbed","Yankee","Caddy","Solair","BerkleysRCVan","Skimmer","PCJ-600","Faggio","Freeway","RCBaron","RCRaider","Glendale","Oceanic","Sanchez","Sparrow","Patriot","Quad","Coastguard","Dinghy","Hermes","Sabre","Rustler","ZR-350","Walton","Regina","Comet","BMX","Burrito","Camper","Marquis","Baggage","Dozer","Maverick","NewsChopper","Rancher","FBIRancher","Virgo","Greenwood","Jetmax","Hotring","Sandking","BlistaCompact","PoliceMaverick","Boxvillde","Benson","Mesa","RCGoblin","HotringRacerA","HotringRacerB","BloodringBanger","Rancher","SuperGT","Elegant","Journey","Bike","MountainBike","Beagle","Cropduster","Stunt","Tanker","Roadtrain","Nebula","Majestic","Buccaneer","Shamal","hydra","FCR-900","NRG-500","HPV1000","CementTruck","TowTruck","Fortune","Cadrona","FBITruck","Willard","Forklift","Tractor","Combine","Feltzer","Remington","Slamvan","Blade","Freight","Streak","Vortex","Vincent","Bullet","Clover","Sadler","Firetruck","Hustler","Intruder","Primo","Cargobob","Tampa","Sunrise","Merit","Utility","Nevada","Yosemite","Windsor","Monster","Monster","Uranus","Jester","Sultan","Stratum","Elegy","Raindance","RCTiger","Flash","Tahoma","Savanna","Bandito","FreightFlat","StreakCarriage","Kart","Mower","Dune","Sweeper","Broadway","Tornado","AT-400","DFT-30","Huntley","Stafford","BF-400","NewsVan","Tug","Trailer","Emperor","Wayfarer","Euros","Hotdog","Club","FreightBox","Trailer","Andromada","Dodo","RCCam","Launch","PoliceCar","PoliceCar","PoliceCar","PoliceRanger","Picador","S.W.A.T","Alpha","Phoenix","GlendaleShit","SadlerShit","Luggage","Luggage","Stairs","Boxville","Tiller","UtilityTrailer"}
    if vehicleId then
        local id = vehicleId - 399
        vehicleName = ovehicleNames[id]
    end
    return vehicleName or '�� ����������'
end

function getClosestCarId() -- ������� ��������� ���������� id ����������
    local minDist = 9999
    local closestId = -1
    local x, y, z = getCharCoordinates(PLAYER_PED)
    for i = 0, 1800 do
        local streamed, pedID = sampGetCarHandleBySampVehicleId(i)
        if streamed then
            local xi, yi, zi = getCarCoordinates(pedID)
            local dist = math.sqrt( (xi - x) ^ 2 + (yi - y) ^ 2 + (zi - z) ^ 2 )
            if dist < minDist then
                minDist = dist
                closestId = i
            end
        end
    end
    return closestId or '000'
end
 
function imgui.OnDrawFrame()
    if target_window.v then
        local sw, sh = getScreenResolution()
        imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(190, 228))
        imgui.Begin('##targetwindow',  target_window, imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoMove)
        imgui.SetCursorPosY(10)
        imgui.CenterTextColoredRGB('{808080}���� ��������������')
        imgui.Separator()
        if vehicle.state then
            imgui.CenterTextColoredRGB('{FFD848}' .. sampGetVehicleModelById(vehicle.i.model) .. '[' .. getClosestCarId() .. ']')
            imgui.SetCursorPosY(60)
            if imgui.Button(u8'���������������', imgui.ImVec2(175,25)) then sampSendChat('/repcar'); target_window.v = false end
            if imgui.Button(u8'��������� ���������', imgui.ImVec2(175,25)) then sampSendChat('/fillcar'); target_window.v = false end
            if imgui.Button(u8'�������� �����', imgui.ImVec2(175,25)) then sampSendChat('/breakcar'); target_window.v = false end
        else
            imgui.CenterTextColoredRGB('{FFD848}' ..target.i.name.. '[' ..target.i.id.. ']')
            if not choose_act then
                local uf = 0
                imgui.SetCursorPosY(60)
                for i, v in ipairs(cars) do
                    if v.spawn then
                        uf = uf + 1
                        if imgui.Button(v.name .. '##' .. i, imgui.ImVec2(175,25)) then choose_car = v.name; sampSendChat('/cars'); sampSendDialogResponse(162, 1, v.id, -1); choose_act = true end
                    end
                end
                if uf == 0 then
                    imgui.SetCursorPosY(105)
                    imgui.CenterTextColoredRGB('{808080}� ��� ��� ����������� �/�')
                    imgui.SetCursorPosY(175)
                    if imgui.Button(u8'���������', imgui.ImVec2(175,20)) then target_window.v = false; sampSendChat('/cars') end        
                end
            else
                imgui.SetCursorPosY(60)
                if imgui.Button(u8'�������� �����', imgui.ImVec2(175,25)) then sampSendChat('/givekey ' ..target.i.id.. ' ' ..servercarid); choose_car = ''; target_window.v = false; choose_act = false end
                if imgui.Button(u8'�������� �������', imgui.ImVec2(175,25)) then sampSendChat('/carpass ' ..target.i.id.. ' ' ..servercarid); choose_car = ''; target_window.v = false; choose_act = false end
                imgui.SetCursorPosY(140)
                imgui.CenterTextColoredRGB('{808080}��������� �/c:')
                imgui.CenterTextColoredRGB('{73B461}' ..choose_car)
                imgui.ColorButton(64, 105, 15, 52, 84, 12, 77, 125, 17)
                if imgui.Button(u8'�����', imgui.ImVec2(175,20)) then choose_act = false; choose_car = '' end
                imgui.PopStyleColor(3)
            end
        end
        imgui.SetCursorPosY(200)
		imgui.ColorButton(112, 112, 112, 99, 99, 99, 130, 130, 130)
        if imgui.Button(u8'�������', imgui.ImVec2(175,20)) then target_window.v = false; choose_act = false; choose_car = '' end
        imgui.PopStyleColor(3)
        imgui.End()
    end
    if main_window.v then
 
        imgui.CenterText = function(text)
            imgui.SetCursorPosX((imgui.GetWindowWidth() - imgui.CalcTextSize(u8(text)).x)/2)
            imgui.Text(u8(text))
        end
 
        local sw, sh = getScreenResolution()
        imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(515, 485))
        imgui.Begin(u8('MyCar | ' ..cars_info),  main_window, imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoCollapse)
        imgui.BeginChild('##panel_1', imgui.ImVec2(145, 430), true)
            imgui.CenterText('������ ����:')
            for i, v in ipairs(cars) do
                if not aboutmod and not info_update then
                    imgui.ColButton(cars[i]['spawn'])
                    if imgui.Button(v['name'] .. '##' .. i, imgui.ImVec2(130,20)) and not work then
                        carname = v['name']; car_info = {}; carid = i; sampSendChat(command); sampSendDialogResponse(id_dialog, 1, cars[carid]['id'], -1); state_spawn = cars[carid]['spawn']; text_loads = '�������� ������...'; text_load = '�������� ������...'
                    end    
                    imgui.PopStyleColor(3)
                else
					imgui.ColorButton(112, 112, 112, 99, 99, 99, 222, 2, 2)
                    imgui.Button(v['name'] .. '##' .. i, imgui.ImVec2(130,20))
                    imgui.PopStyleColor(3)
                end
            end
        imgui.EndChild()

        imgui.SameLine()
        
        imgui.BeginChild('##panel_2', imgui.ImVec2(347, 430), true)
            if info_update then
                aboutmod = false
                imgui.CenterTextColoredRGB('{4169E1}�������� ����� ���������� v' ..data.name.. '.'); imgui.Separator()
                imgui.CenterTextColoredRGB('{73B461}������ ������ ���������:')
                imgui.BeginChild('##update', imgui.ImVec2(330, 355), true)
                    local text = data.info
                    if text then
                        imgui.TextWrapped(text)
                    else
                        imgui.SetCursorPosY(180)
                        imgui.CenterTextColoredRGB('{DCDCDC}�� ������� ��������� ���������� �� ����������.')
                    end
                imgui.EndChild()
				imgui.ColorButton(35, 84, 25, 30, 70, 20, 48, 115, 34)
                if imgui.Button(u8'�������', imgui.ImVec2(163,20)) then os.execute('explorer "https://www.blast.hk/threads/76299/"') end
                imgui.PopStyleColor(3)
                if imgui.IsItemHovered() then imgui.BeginTooltip() imgui.TextUnformatted(u8('����� �� ������, � ��� ��������� ������ � ��������, ��� �� ������� ������� ������.')) imgui.EndTooltip() end
                imgui.SameLine()
                if imgui.Button(u8'�����', imgui.ImVec2(163, 20)) then info_update = false end
            end
            if aboutmod then
                info_update = false
                imgui.CenterTextColoredRGB('{6495ED}�������������� �������'); imgui.Separator()
                if imgui.Checkbox(u8'�������� ����� � ����� ��� ������� ������� �/�', CheckBox['enter']) then cfg.CheckBox.enter = CheckBox['enter'].v; inicfg.save(cfg, 'MyCar.ini') end
                if imgui.IsItemHovered() then imgui.BeginTooltip() imgui.TextUnformatted(u8('������ �� ��� ����� ��������� ���� � ����� ��������� ��� ������� ������� ���������.')) imgui.EndTooltip() end
                if imgui.Checkbox(u8'������� ���� �� ����� ��������� ��� ������ �� �/�', CheckBox['key']) then cfg.CheckBox.key = CheckBox['key'].v; inicfg.save(cfg, 'MyCar.ini') end
                if imgui.IsItemHovered() then imgui.BeginTooltip() imgui.TextUnformatted(u8('������ �� ��� ����� ��������� ����� �� ����� ��������� ��� ������ �� ������������� ��������.')) imgui.EndTooltip() end
                if imgui.Checkbox(u8'��������� ���� ��������� ��� �����������', CheckBox['unloading']) then
                    cfg.CheckBox.unloading = CheckBox['unloading'].v
                    inicfg.save(cfg, 'MyCar.ini') 
                end
                if imgui.IsItemHovered() then imgui.BeginTooltip() imgui.TextUnformatted(u8('��� ����� � ���� ������ �������� ��� ���� ������������ �������� � �������.')) imgui.EndTooltip() end
                if imgui.Checkbox(u8'�������������� �������� ���������� �� ���', CheckBox['fuel']) then cfg.CheckBox.fuel = CheckBox['fuel'].v; inicfg.save(cfg, 'MyCar.ini') end
                if imgui.IsItemHovered() then imgui.BeginTooltip() imgui.TextUnformatted(u8('������ �� ��� �������� �� ������� ���� ���� ������������ �������� �� ��������������� �������.')) imgui.EndTooltip() end
				
                imgui.NewLine(); imgui.CenterTextColoredRGB('{73B461}������� �������'); imgui.Separator()
                if imadd.HotKey("##menu", ActiveMenus, tLastKeys, 80) then
                    rkeys.changeHotKey(bindMenu, ActiveMenus.v)
                    cfg.HotKey.main = encodeJson(ActiveMenus.v)
					inicfg.save(cfg, 'MyCar.ini')
                end
                imgui.SameLine(); imgui.Text(u8' -   ������� ���� ������� (/cars)')
                if imadd.HotKey("##lock", ActiveLock, tLastKeys, 80) then
                    rkeys.changeHotKey(bindLock, ActiveLock.v)
					cfg.HotKey.lock = encodeJson(ActiveLock.v)
					inicfg.save(cfg, 'MyCar.ini')
                end
                imgui.SameLine(); imgui.Text(u8' -   �������/������� ��������� (/lock)')
                if imadd.HotKey("##key", ActiveKey, tLastKeys, 80) then
                    rkeys.changeHotKey(bindKey, ActiveKey.v)
					cfg.HotKey.keys = encodeJson(ActiveKey.v)
					inicfg.save(cfg, 'MyCar.ini')
				end
                imgui.SameLine(); imgui.Text(u8' -   ��������/������� ����� (/key)')
                if imadd.HotKey('##style', ActiveStyle, tLastKeys, 80) then
                    rkeys.changeHotKey(bindStyle, ActiveStyle.v)
					cfg.HotKey.style = encodeJson(ActiveStyle.v)
                    inicfg.save(cfg, 'MyCar.ini')
                end
                imgui.SameLine(); imgui.Text(u8' -   �������� ����� ���� (/style)')
                if imadd.HotKey("##interaction", ActiveInteraction, tLastKeys, 80) then
                    rkeys.changeHotKey(bindInteraction, ActiveInteraction.v)
                    if ActiveInteraction.v[2] then ActiveInteraction.v = tLastKeys.v end
					cfg.HotKey.interaction = encodeJson(ActiveInteraction.v)
                    inicfg.save(cfg, 'MyCar.ini')
				end
                imgui.SameLine(); imgui.Text(u8' -   ���� ��������������')
                if imgui.IsItemHovered() then imgui.BeginTooltip() imgui.TextUnformatted(u8('��� �������������� � ������� - �������� ��� (���).\n����� ����������������� � �����������, ��������� � ���� � ������� �������.\n��� ����, ����� ��������� ��� ������� - ������� ������� ������� (������� �� ��, ����� Backspace).')) imgui.EndTooltip() end
                imgui.SameLine(); imgui.SetCursorPosX(320)
                if imgui.Checkbox('##hint',CheckBox['hint']) then cfg.CheckBox.hint = CheckBox['hint'].v; inicfg.save(cfg, 'MyCar.ini') end
				if imgui.IsItemHovered() then imgui.BeginTooltip() imgui.TextUnformatted(u8((CheckBox['hint'].v and '���������' or '��������').. ' ��������� ��� ������������� ������� (�� ���������/����������).')) imgui.EndTooltip() end
				imgui.SetCursorPosY(335)
                imgui.NewLine(); imgui.CenterTextColoredRGB('{A9A9A9}�������� �����:'); imgui.Separator()
				imgui.ColorButton(11, 88, 230, 10, 80, 209, 12, 94, 245)
                if imgui.Button(u8'���������', imgui.ImVec2(107,20)) then os.execute('explorer "https://vk.com/sd_scripts"') end
                imgui.PopStyleColor(3)
                if imgui.IsItemHovered() then imgui.BeginTooltip() imgui.TextUnformatted(u8('����� �� ������, � ��� ��������� ������ � �������� ����� ������ ���������.')) imgui.EndTooltip() end
                imgui.SameLine()
                
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.19, 0.22, 0.26, 1.0))
                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.15, 0.18, 0.22, 1.0))
                imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.11, 0.14, 0.18, 1.0))
                if imgui.Button('BlastHack', imgui.ImVec2(107,20)) then os.execute('explorer "https://www.blast.hk/threads/76299/"') end
                imgui.PopStyleColor(3)
                if imgui.IsItemHovered() then imgui.BeginTooltip() imgui.TextUnformatted(u8('����� �� ������, � ��� ��������� ������ � �������� ���� �� ������� BlastHack.')) imgui.EndTooltip() end
				imgui.SameLine()
				imgui.ColorButton(35, 84, 25, 30, 70, 20, 48, 115, 34)
				if imgui.Button(u8'������������', imgui.ImVec2(109,20)) then os.execute('explorer "https://vk.me/sd_scripts"') end
				imgui.PopStyleColor(3)
				if imgui.IsItemHovered() then imgui.BeginTooltip() imgui.TextUnformatted(u8('����� �� ������, �� ������� � ������������ (������ ��������� ����� ������ ���������).')) imgui.EndTooltip() end
				imgui.Separator()
				
                imgui.SetCursorPosY(405)
				imgui.ColorButton(120, 34, 34, 107, 30, 30, 135, 38, 38)
                if imgui.Button(u8'���������', imgui.ImVec2(115,20)) then thisScript():unload() end
				imgui.PopStyleColor(3)
                if imgui.IsItemHovered() then imgui.BeginTooltip() imgui.TextUnformatted(u8('��������� ������ �� ������������ (CTRL+R) ��� ���������� � ����.')) imgui.EndTooltip() end
                imgui.SameLine()
                imgui.ColorButton(16, 73, 148, 16, 65, 130, 21, 86, 171)
                if imgui.Button(u8'�������������', imgui.ImVec2(115,20)) then thisScript():reload() end
                imgui.PopStyleColor(3)
                if imgui.IsItemHovered() then imgui.BeginTooltip() imgui.TextUnformatted(u8('������ ������������ �������.')) imgui.EndTooltip() end
                imgui.SameLine()
                if imgui.Button(u8'�������', imgui.ImVec2(93,20)) then aboutmod = false end
                if imgui.IsItemHovered() then imgui.BeginTooltip() imgui.TextUnformatted(u8('��������� ���� ��������.')) imgui.EndTooltip() end
            end
            if parkingmod then
                imgui.SetCursorPosY(160)
				imgui.CenterTextColoredRGB('{808080}��������, ��� ������������ ��� ���������.')
                if imgui.Button(u8'������������ � ���� �����', imgui.ImVec2(335,25)) then
                    parkingmod = false
                    parkingstate = 0
                    state = 4
                    work = true
                    sampSendChat(command)
                end
                if imgui.Button(u8'������� �� ����������� ��������', imgui.ImVec2(335,25)) then
                    parkingmod = false
                    parkingstate = 1
                    state = 4
                    work = true
                    sampSendChat(command)
                end
                imgui.SetCursorPosX(223)
				imgui.ColorButton(112, 112, 112, 99, 99, 99, 130, 130, 130)
                if imgui.Button(u8'�����', imgui.ImVec2(120, 20)) then parkingmod = false end
                imgui.PopStyleColor(3)
            end
            if state_spawn and not parkingmod and not reloadmod and not aboutmod and not info_update then
                imgui.BeginChild('##columns', imgui.ImVec2(330, 315), true)
                    imgui.CenterTextColoredRGB('������� ���������� {C0C0C0}' ..tostring(car_info[1] and car_info[1].carname or ''))  
                    imgui.Separator()
                    imgui.Columns(2)
                    local arrayText = {'��������', '���������', '������', '�����', '�����', '����� �� ��������������', '��������������� ���������', '��������������� �����', '��������', '����������� ���������', '��������� �����', '��������� (�� �����������)', '��������� (�� ���)'}
                    local arrayInfo = {car_info[1] and car_info[1].owner or '--', car_info[1] and car_info[1].intermediary or '--', car_info[1] and car_info[1].mileage or '--', car_info[1] and car_info[1].tax.. ' �� 150000' or '--', car_info[1] and car_info[1].fine.. ' �� 80000' or '--', car_info[1] and car_info[1].recovery_penalty or '--', car_info[1] and car_info[1].price or '--', car_info[1] and car_info[1].car_number or '--', car_info[1] and car_info[1].car_health_min.. ' / ' ..car_info[1].car_health_max or '--', car_info[1] and car_info[1].state.. ' / 100' or '--', car_info[1] and car_info[1].oil or '--', car_info[1] and car_info[1].insurance_damage or '--', car_info[1] and car_info[1].insurance_meeting or '�����������'}
                    for i = 1, 13 do
                        imgui.SetColumnWidth(-1, 170); imgui.CenterColumnText(u8(arrayText[i])); imgui.NextColumn()
                        imgui.SetColumnWidth(-1, 150); imgui.CenterColumnText(u8(tostring(arrayInfo[i]))); imgui.NextColumn()
                        if i ~= 13 then imgui.Separator() end
                    end
                imgui.EndChild()
                imgui.Separator()
                imgui.ColButton(door_state)
                if imgui.Button(u8'DOOR', imgui.ImVec2(79,20)) then
                    state = 2
                    work = true
                    sampSendChat(command)
                end
                imgui.PopStyleColor(3)
                if imgui.IsItemHovered() then imgui.BeginTooltip() imgui.TextUnformatted(u8('�������, ����� ' .. (door_state and '�������' or '�������') .. ' ����� ������ ������������� ��������.\n\nP.S. ����������� ������ ���� ����� � ����� �/c ��� �������� � ��.')) imgui.EndTooltip() end 
                imgui.SameLine()
                imgui.ColButton(key_state)
                if imgui.Button(u8'KEY', imgui.ImVec2(79,20)) and isCharInAnyCar(PLAYER_PED) and (tonumber(servercarid) == tonumber(select(2, sampGetVehicleIdByCarHandle(storeCarCharIsInNoSave(PLAYER_PED))))) then 
                    state = 3
                    work = true
                    sampSendChat(command) 
                end
                imgui.PopStyleColor(3)
                if imgui.IsItemHovered() then imgui.BeginTooltip() imgui.TextUnformatted(u8('�������, ����� ' .. (key_state and '�������� ����� �� �����' or '�������� ���� � �����') .. ' ��������� ������ ������������� ��������.\n\nP.S. ����������� ������ �������� � ����������.')) imgui.EndTooltip() end
                imgui.SameLine()
                imgui.ColButton(drive_state)
                if imgui.Button((drive_state and 'Comfort' or 'Sport'), imgui.ImVec2(79,20)) and isCharInAnyCar(PLAYER_PED) and (tonumber(servercarid) == tonumber(select(2, sampGetVehicleIdByCarHandle(storeCarCharIsInNoSave(PLAYER_PED))))) then
                    state = 8
                    work = true
                    sampSendChat(command) 
                end
                imgui.PopStyleColor(3)
                if imgui.IsItemHovered() then imgui.BeginTooltip() imgui.TextUnformatted(u8('�������� ����� ���� [Sport, Comfort].\n\nP.S. ����������� ������ �������� � ����������.')) imgui.EndTooltip() end
                imgui.SameLine()
                imgui.ColButton(abs_state)
                if imgui.Button(u8'ABS', imgui.ImVec2(79,20)) and isCharInAnyCar(PLAYER_PED) and (tonumber(servercarid) == tonumber(select(2, sampGetVehicleIdByCarHandle(storeCarCharIsInNoSave(PLAYER_PED))))) then 
                    state = 9
                    work = true
                    sampSendChat(command) 
                end
                imgui.PopStyleColor(3)
                if imgui.IsItemHovered() then imgui.BeginTooltip() imgui.TextUnformatted(u8('�������, ����� ' .. (abs_state and '���������' or '��������') .. ' ������� ABS ������ ������������� ��������.\n\nP.S. ����������� ������ �������� � ����������.')) imgui.EndTooltip() end
                imgui.Separator()
                if imgui.Button(u8'������������', imgui.ImVec2(107,20)) then 
                    parkingmod = true 
                end
                imgui.SameLine()
                if imgui.Button(u8'�����', imgui.ImVec2(107,20)) then 
                    state = 5
                    work = true
                    sampSendChat(command) 
                end
                imgui.SameLine()
                if imgui.Button(u8'������������', imgui.ImVec2(107,20)) then 
                    state = 6
                    work = true
                    sampSendChat(command) 
                end

                if command == '/cars' then 
                    button_key = '�������� �����������'; infotooltip = '������� ����� � ��������, �������� �� �� ������.'
                elseif command == '/keys' then 
                    button_key = '������� �����'; infotooltip = '������� ����� ���������.'
                end
                if imgui.Button(u8(button_key), imgui.ImVec2(143,20)) then 
                    state = 7
                    work = true
                    sampSendChat(command) 
                end
                if imgui.IsItemHovered() then imgui.BeginTooltip() imgui.TextUnformatted(u8(infotooltip)) imgui.EndTooltip() end
                imgui.SameLine()
                if imgui.Button(u8'����������', imgui.ImVec2(89,20)) then
                    state = 10
                    work = true
                    sampSendChat(command) 
                end
                if imgui.IsItemHovered() then imgui.BeginTooltip() imgui.TextUnformatted(u8('���� ������������ �������� ������������ �� ����� ��������.\n��������� ������: 1.000$.')) imgui.EndTooltip() end
                imgui.SameLine()
                if command == '/cars' then
                    if imgui.Button(u8'���������', imgui.ImVec2(89,20)) then
                        state_spawn = false
                        state = 1
                        work = true
                        sampSendChat('/cars')
                    end
                    if text_loads == '��������� ��� �����������' then loads_status = false else loads_status = true end
                    imgui.ColButton(loads_status)
                    if imgui.Button(u8(text_loads), imgui.ImVec2(332,20)) then
                        work = true; state = 11; sampSendChat('/cars')
                    end
                    imgui.PopStyleColor(3)
                    if imgui.IsItemHovered() then imgui.BeginTooltip() imgui.TextUnformatted(u8('����� �� ��� ������, ����� �������� ������ �������� ���������� ��������.\n� ������ ������ �������� ' ..(loads_status and '�����' or '�� �����') .. ' �������� ��� ����� �� ������.')) imgui.EndTooltip() end
                end
            elseif not state_spawn and not parkingmod and not reloadmod and not aboutmod and not info_update then
                imgui.SetCursorPosY(180)
                if carid then
                    if not work then
                        if cars[carid].pfine then
                            imgui.CenterTextColoredRGB('��� ��������� {ffff00}' ..carname.. '{ffffff} �� ������������.')
                        else
                            imgui.SetCursorPosY(160)
                            imgui.CenterTextColoredRGB('��� ��������� {ffff00}' ..carname.. '{ffffff} �� ��������.')
                            if imgui.Button(u8'���������', imgui.ImVec2(335,25)) then
                                work = true
                                sampSendChat('/cars')
                                working = true
                            end
                            if text_load == '��������� ��� �����������' then load_status = false else load_status = true end
                            imgui.ColButton(load_status)
                            if imgui.Button(u8(text_load), imgui.ImVec2(335,25)) then
                                work = true
                                sampSendChat('/cars')
                                loading = true
                            end
                            imgui.PopStyleColor(3)
                        end
                    else
                        if not loading then
                            imgui.SetCursorPosY(150)
                            imgui.SetCursorPosX(165)
                            imadd.Spinner('##spinner', 12, 3, imgui.GetColorU32(imgui.GetStyle().Colors[imgui.Col.ButtonHovered]))
                            imgui.CenterTextColoredRGB('���������. ��� '.. (state == 1 and '��������' or '��������') ..' ���������� {ffff00}' ..carname.. '{ffffff}.')
                            if imgui.Button(u8'����', imgui.ImVec2(335,30)) then
                                work = false   
                            end
                        else
                            imgui.SetCursorPosY(160)
                            imgui.CenterTextColoredRGB('��� ��������� {ffff00}' ..carname.. '{ffffff} �� ��������.')
                            imgui.Button(u8'���������', imgui.ImVec2(335,25))
                            imgui.Button(u8(text_load), imgui.ImVec2(335,25))
                        end
                    end
                else
                    imgui.CenterText('�������� ��������� �� ������ �����.')
                end
            end
        imgui.EndChild()
        
        if data.version and data.version > thisScript().version_num then 
            imgui.TextColoredRGB('{808080}  �������� ����������!')
            if imgui.IsItemClicked() then
                info_update = true
            end
            if imgui.IsItemHovered() then imgui.BeginTooltip() imgui.TextUnformatted(u8('�����, ����� ������ ���������� �� ����������.')) imgui.EndTooltip() end
            imgui.SameLine()
        end
        imgui.SetCursorPosX(345)
        imgui.TextColoredRGB('{4169E1}S&D Scripts�')
        if imgui.IsItemClicked() then
            aboutmod = true
        end
        if imgui.IsItemHovered() then imgui.BeginTooltip() imgui.TextUnformatted(u8('�������������� ��������� �������.')) imgui.EndTooltip() end
        imgui.SameLine()
        imgui.TextColoredRGB(' {ffffff}Version: {808080}' ..thisScript().version)
        imgui.End()
    end 
end

function onReceivePacket(id)
	if id == 34 or id == 41 then
        lua_thread.create(function()
            wait(3500)
            print('{FF8C00}��������������: {ffffff}������ ��� ������������ ��-�� ���������� � ����. {808080}ID_PACKET: ' ..id)
            thisScript():reload()
        end)
    end
end
 
function apply_custom_style()
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4
    local ImVec2 = imgui.ImVec2

    style.WindowPadding = imgui.ImVec2(8, 8)
    style.WindowRounding = 6
    style.ChildWindowRounding = 5
    style.FramePadding = imgui.ImVec2(5, 3)
    style.FrameRounding = 3.0
    style.ItemSpacing = imgui.ImVec2(5, 4)
    style.ItemInnerSpacing = imgui.ImVec2(4, 4)
    style.IndentSpacing = 21
    style.ScrollbarSize = 10.0
    style.ScrollbarRounding = 13
    style.GrabMinSize = 8
    style.GrabRounding = 1
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)

    colors[clr.Text]                   = ImVec4(0.95, 0.96, 0.98, 1.00);
    colors[clr.TextDisabled]           = ImVec4(0.29, 0.29, 0.29, 1.00);
    colors[clr.WindowBg]               = ImVec4(0.14, 0.14, 0.14, 1.00);
    colors[clr.ChildWindowBg]          = ImVec4(0.12, 0.12, 0.12, 1.00);
    colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.94);
    colors[clr.Border]                 = ImVec4(0.14, 0.14, 0.14, 1.00);
    colors[clr.BorderShadow]           = ImVec4(1.00, 1.00, 1.00, 0.10);
    colors[clr.FrameBg]                = ImVec4(0.22, 0.22, 0.22, 1.00);
    colors[clr.FrameBgHovered]         = ImVec4(0.18, 0.18, 0.18, 1.00);
    colors[clr.FrameBgActive]          = ImVec4(0.09, 0.12, 0.14, 1.00);
    colors[clr.TitleBg]                = ImVec4(0.14, 0.14, 0.14, 0.81);
    colors[clr.TitleBgActive]          = ImVec4(0.14, 0.14, 0.14, 1.00);
    colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.00, 0.00, 0.51);
    colors[clr.MenuBarBg]              = ImVec4(0.20, 0.20, 0.20, 1.00);
    colors[clr.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.39);
    colors[clr.ScrollbarGrab]          = ImVec4(0.36, 0.36, 0.36, 1.00);
    colors[clr.ScrollbarGrabHovered]   = ImVec4(0.18, 0.22, 0.25, 1.00);
    colors[clr.ScrollbarGrabActive]    = ImVec4(0.24, 0.24, 0.24, 1.00);
    colors[clr.ComboBg]                = ImVec4(0.24, 0.24, 0.24, 1.00);
    colors[clr.CheckMark]              = ImVec4(1.00, 0.28, 0.28, 1.00);
    colors[clr.SliderGrab]             = ImVec4(1.00, 0.28, 0.28, 1.00);
    colors[clr.SliderGrabActive]       = ImVec4(1.00, 0.28, 0.28, 1.00);
    colors[clr.Button]                 = ImVec4(1.00, 0.28, 0.28, 1.00);
    colors[clr.ButtonHovered]          = ImVec4(1.00, 0.39, 0.39, 1.00);
    colors[clr.ButtonActive]           = ImVec4(1.00, 0.21, 0.21, 1.00);
    colors[clr.Header]                 = ImVec4(1.00, 0.28, 0.28, 1.00);
    colors[clr.HeaderHovered]          = ImVec4(1.00, 0.39, 0.39, 1.00);
    colors[clr.HeaderActive]           = ImVec4(1.00, 0.21, 0.21, 1.00);
    colors[clr.ResizeGrip]             = ImVec4(1.00, 0.28, 0.28, 1.00);
    colors[clr.ResizeGripHovered]      = ImVec4(1.00, 0.39, 0.39, 1.00);
    colors[clr.ResizeGripActive]       = ImVec4(1.00, 0.19, 0.19, 1.00);
    colors[clr.CloseButton]            = ImVec4(0.40, 0.39, 0.38, 0.16);
    colors[clr.CloseButtonHovered]     = ImVec4(0.40, 0.39, 0.38, 0.39);
    colors[clr.CloseButtonActive]      = ImVec4(0.40, 0.39, 0.38, 1.00);
    colors[clr.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00);
    colors[clr.PlotLinesHovered]       = ImVec4(1.00, 0.43, 0.35, 1.00);
    colors[clr.PlotHistogram]          = ImVec4(1.00, 0.21, 0.21, 1.00);
    colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 0.18, 0.18, 1.00);
    colors[clr.TextSelectedBg]         = ImVec4(1.00, 0.32, 0.32, 1.00);
    colors[clr.ModalWindowDarkening]   = ImVec4(0.26, 0.26, 0.26, 0.60);
end

function onScriptTerminate(LuaScript, quitGame)
    if LuaScript == thisScript() then
        if imgui then imgui.ShowCursor = false; showCursor(false) end
    end
end
 
function imgui.CenterColumnText(text)
    imgui.SetCursorPosX((imgui.GetColumnOffset() + (imgui.GetColumnWidth() / 2)) - imgui.CalcTextSize(text).x / 2)
    imgui.Text(text)
end

function imgui.ColorButton(p1, p2, p3, p4, p5, p6, p7, p8, p9)
	imgui.PushStyleColor(imgui.Col.Button, imgui.ImColor(p1, p2, p3, 255):GetVec4()) 
	imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImColor(p4, p5, p6, 255):GetVec4()) 
    imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImColor(p7, p8, p9, 255):GetVec4())
end
 
function imgui.ColButton(style)
    if style then -- greenButton
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImColor(35, 84, 25, 255):GetVec4()) -- ����������� ���� RGBA
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImColor(30, 70, 20, 255):GetVec4()) -- ���� ��� ��������� �� ������ (������)
        imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImColor(48, 115, 34, 255):GetVec4()) -- ���� ��� ������� �� ������ (�������)
    else --redButton
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImColor(120, 34, 34, 255):GetVec4()) -- ����������� ���� RGBA
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImColor(107, 30, 30, 255):GetVec4()) -- ���� ��� ��������� �� ������ (������)
        imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImColor(135, 38, 38, 255):GetVec4()) -- ���� ��� ������� �� ������ (�������)
    end
end

function imgui.CenterTextColoredRGB(text)
    local width = imgui.GetWindowWidth()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local ImVec4 = imgui.ImVec4

    local explode_argb = function(argb)
        local a = bit.band(bit.rshift(argb, 24), 0xFF)
        local r = bit.band(bit.rshift(argb, 16), 0xFF)
        local g = bit.band(bit.rshift(argb, 8), 0xFF)
        local b = bit.band(argb, 0xFF)
        return a, r, g, b
    end

    local getcolor = function(color)
        if color:sub(1, 6):upper() == 'SSSSSS' then
            local r, g, b = colors[1].x, colors[1].y, colors[1].z
            local a = tonumber(color:sub(7, 8), 16) or colors[1].w * 255
            return ImVec4(r, g, b, a / 255)
        end
        local color = type(color) == 'string' and tonumber(color, 16) or color
        if type(color) ~= 'number' then return end
        local r, g, b, a = explode_argb(color)
        return imgui.ImColor(r, g, b, a):GetVec4()
    end

    local render_text = function(text_)
        for w in text_:gmatch('[^\r\n]+') do
            local textsize = w:gsub('{.-}', '')
            local text_width = imgui.CalcTextSize(u8(textsize))
            imgui.SetCursorPosX( width / 2 - text_width .x / 2 )
            local text, colors_, m = {}, {}, 1
            w = w:gsub('{(......)}', '{%1FF}')
            while w:find('{........}') do
                local n, k = w:find('{........}')
                local color = getcolor(w:sub(n + 1, k - 1))
                if color then
                    text[#text], text[#text + 1] = w:sub(m, n - 1), w:sub(k + 1, #w)
                    colors_[#colors_ + 1] = color
                    m = n
                end
                w = w:sub(1, n - 1) .. w:sub(k + 1, #w)
            end
            if text[0] then
                for i = 0, #text do
                    imgui.TextColored(colors_[i] or colors[1], u8(text[i]))
                    imgui.SameLine(nil, 0)
                end
                imgui.NewLine()
            else
                imgui.Text(u8(w))
            end
        end
    end
    render_text(text)
end
function imgui.TextColoredRGB(text)
    local style = imgui.GetStyle()
    local colors = style.Colors
    local ImVec4 = imgui.ImVec4

    local explode_argb = function(argb)
        local a = bit.band(bit.rshift(argb, 24), 0xFF)
        local r = bit.band(bit.rshift(argb, 16), 0xFF)
        local g = bit.band(bit.rshift(argb, 8), 0xFF)
        local b = bit.band(argb, 0xFF)
        return a, r, g, b
    end

    local getcolor = function(color)
        if color:sub(1, 6):upper() == 'SSSSSS' then
            local r, g, b = colors[1].x, colors[1].y, colors[1].z
            local a = tonumber(color:sub(7, 8), 16) or colors[1].w * 255
            return ImVec4(r, g, b, a / 255)
        end
        local color = type(color) == 'string' and tonumber(color, 16) or color
        if type(color) ~= 'number' then return end
        local r, g, b, a = explode_argb(color)
        return imgui.ImColor(r, g, b, a):GetVec4()
    end

    local render_text = function(text_)
        for w in text_:gmatch('[^\r\n]+') do
            local text, colors_, m = {}, {}, 1
            w = w:gsub('{(......)}', '{%1FF}')
            while w:find('{........}') do
                local n, k = w:find('{........}')
                local color = getcolor(w:sub(n + 1, k - 1))
                if color then
                    text[#text], text[#text + 1] = w:sub(m, n - 1), w:sub(k + 1, #w)
                    colors_[#colors_ + 1] = color
                    m = n
                end
                w = w:sub(1, n - 1) .. w:sub(k + 1, #w)
            end
            if text[0] then
                for i = 0, #text do
                    imgui.TextColored(colors_[i] or colors[1], u8(text[i]))
                    imgui.SameLine(nil, 0)
                end
                imgui.NewLine()
            else imgui.Text(u8(w)) end
        end
    end

    render_text(text)
end

apply_custom_style()