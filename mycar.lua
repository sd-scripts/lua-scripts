script_author('S&D Scripts')
script_name('MyCar')
script_version('1.4.0')
script_version_number(15) 

local sampev      =   require 'samp.events'
local imgui       =   require 'imgui'
local encoding    =   require 'encoding'
local keys        =   require 'vkeys'
local inicfg      =   require 'inicfg'
local fa          =   require 'fAwesome5'
local ffi         =   require 'ffi'
local memory      =   require 'memory'

local limadd, imadd = pcall(require, 'imgui_addons')
local lrkeys, rkeys = pcall(require, 'rkeys')

encoding.default = 'CP1251'
u8 = encoding.UTF8

local data = {}
local cars = {}
local car_info = {}
local target = {i={},state=false}
local vehicle = {i={},state=false}
local wBox, hBox = 240, 90

local use_jack = false
local page = 1
local one_page = 0

local main_window = imgui.ImBool(false)
local target_window = imgui.ImBool(false)
local balon_window = imgui.ImBool(false)
local price_car = imgui.ImBuffer('', 256)
local work = false
local working = false
local unloading_cars = false
local text_loads = '�������� ������...'
local text_load = '�������� ������...'
local state = 0
local bindID = 0
local step = 0
local font_flag = require('moonloader').font_flag
local font = renderCreateFont('Arial', 10, font_flag.BOLD + font_flag.SHADOW + font_flag.BORDER)
local fontText = renderCreateFont('Arial', 8, font_flag.BOLD + font_flag.SHADOW + font_flag.BORDER)
local fontSpeed = renderCreateFont('Arial', 25, font_flag.BOLD + font_flag.SHADOW + font_flag.BORDER)
local clrBalon = {}

local cfg = inicfg.load({
    CheckBox = {
        enter = true,
        unloading = false,
        fuel = true,
        key = true,
        hint = true
    },
    HotKey = {
        lock = '[76]',
        keys = '[75]',
        main = '[18,77]',
        interaction = '[88]',
        style = '[71]',
        limit = '[186]',
        mouse = '[45]',
        jack = '[48]'
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
local ActiveLimit = {
    v = decodeJson(cfg.HotKey.limit)
}
local ActiveMouse = {
    v = decodeJson(cfg.HotKey.mouse)
}
local ActiveJack = {
    v = decodeJson(cfg.HotKey.jack)
}

local tLastKeys = {}

local fa_font = nil
local fa_glyph_ranges = imgui.ImGlyphRanges({ fa.min_range, fa.max_range })

function imgui.BeforeDrawFrame()
    if fa_font == nil then
        local font_config = imgui.ImFontConfig() -- to use 'imgui.ImFontConfig.new()' on error
        font_config.MergeMode = true
        fa_font = imgui.GetIO().Fonts:AddFontFromFileTTF('moonloader/resource/fonts/fa-solid-900.ttf', 12.0, font_config, fa_glyph_ranges)
    end
end

function Speedometer()
    while true do wait(0)
        if isCharInAnyCar(PLAYER_PED) and pauseMenu() ~= 1 then
            if not stop_render then
                local carhandle = storeCarCharIsInNoSave(PLAYER_PED)
                local idcar = getCarModel(carhandle)
                local AirVehicle = {417, 425, 447, 469, 487, 488, 497, 548, 563, 3224}
                for i = 1, #AirVehicle do
                    if idcar == AirVehicle[i] then
                        local sw, sh = getScreenResolution()
                        local posX, posY = sw - 250, sh - 100
                        local model = sampGetVehicleModelById(idcar)
                        local id = select(2, sampGetVehicleIdByCarHandle(storeCarCharIsInNoSave(PLAYER_PED)))
                        local speed = string.format("%.0f",getCarSpeed(storeCarCharIsInNoSave(PLAYER_PED)) * 3.6)
                        renderDrawBoxWithBorder(posX, posY, wBox, hBox, 0xFF696969, 5, 0xFFC0C0C0)
                        renderDrawLine(posX + 20, posY + 45, posX + 255, posY + 45, 40, 0xAAAAAAAA)
                        renderDrawLine(posX + 18, posY + 45, posX + 92, posY + 45, 17, 0xFFFFFFFF) -- // ������� ������
                        renderDrawLine(posX + 163, posY + 45, posX + 235, posY + 45, 15, 0xFFFFFFFF)
                        renderFontDrawTextCenter(font, model .. '(' ..id.. ')', posX + (wBox / 2), posY + 6, 0xFFFFFFFF)
                        -- // SPEED //
                        local speedLenght = string.len(speed)
                        if speedLenght == 1 then
                            backSpeed = '00'
                            backPosX, fontPosX = 20, 57
                        elseif speedLenght == 2 then
                            backSpeed = '0'
                            backPosX, fontPosX = 20, 39
                        elseif speedLenght == 3 then
                            backSpeed = nil
                            fontPosX = 20
                        end
                        if backSpeed then
                            renderFontDrawText(fontSpeed, backSpeed, posX + 90, posY + 25, 0xFF808080)
                        end
                        renderFontDrawText(fontSpeed, speed, (posX + 70) + fontPosX, posY + 25, 0xFFFFFFFF)
                        renderFontDrawTextCenter(font, 'km/h', posX + (wBox / 2), posY + 65, 0xFFFFFFFF)
                        -- // HP //
                        local health = getCarHealth(storeCarCharIsInNoSave(PLAYER_PED))
                        if car_info[1] then
                            local health_max = car_info[1].car_health_max
                            posLineHp = string.format("%.0f", health / string.format("%.1f", health_max / 90))
                        else
                            posLineHp = string.format("%.0f", health / 16.6)
                        end
                        
                        renderDrawLine(posX + 18, posY + 45, posX + posLineHp, posY + 45, 15, 0xFFFF0000)
                        renderFontDrawText(font, health, posX + 30, posY + 37, 0xFFFFFFFF)
                        -- // DOOR //
                        local res, carHandle = sampGetCarHandleBySampVehicleId(id)
                        if res and id then
                            local doorStatus = getCarDoorLockStatus(carHandle)
                            renderFontDrawText(font, 'D', posX + 158, posY + 37, (doorStatus == 0 and 0xFF008000 or 0xFFFF0000))
                        end
                        -- // ENGINE //
                        local engineState = isCarEngineOn(storeCarCharIsInNoSave(PLAYER_PED))
                        renderFontDrawText(font, 'E', posX + 184, posY + 37, (engineState and 0xFF008000 or 0xFFFF0000))
                        -- // KEY //
                        if key_state ~= nil then
                            renderFontDrawText(font, 'K', posX + 210, posY + 37, (key_state and 0xFF008000 or 0xFFFF0000))
                        else
                            renderFontDrawText(font, 'K', posX + 210, posY + 37, 0xFF808080)
                        end
                    end
                end
            end
        end
    end
end

function renderFontDrawTextCenter(fontCenter, text, x, y, color)
    renderFontDrawText(fontCenter, text, x - renderGetFontDrawTextLength(fontCenter, text) / 2, y, color)
end

function checkServer(ip)
	for k, v in pairs({
			['Phoenix'] 	= '185.169.134.3',
			['Tucson'] 		= '185.169.134.4',
			['Scottdale']	= '185.169.134.43',
			['Chandler'] 	= '185.169.134.44', 
			['Brainburg'] 	= '185.169.134.45',
			['Saint Rose'] 	= '185.169.134.5',
			['Mesa'] 		= '185.169.134.59',
			['Red Rock'] 	= '185.169.134.61',
			['Yuma'] 		= '185.169.134.107',
			['Surprise'] 	= '185.169.134.109',
			['Prescott'] 	= '185.169.134.166',
			['Glendale'] 	= '185.169.134.171',
			['Kingman'] 	= '185.169.134.172',
			['Winslow'] 	= '185.169.134.173',
			['Payson'] 		= '185.169.134.174',
			['Gilbert']		= '80.66.82.191'
		}) do
		if v == ip then 
			return true, k
		end
	end
	return false
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
        main_window.v = true; aboutmod, parkingmod, reloadmod, info_update = false
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
        if (work and carid) or (key_state == nil and carid) then
            sampSendDialogResponse(162, 1, cars[carid]['id'], -1)
        end          

        local i = 0
        local t = {}
        cars = {}
        for v in string.gmatch(text, '[^\n]+') do
            if v:match('%[�� ���������%]') then
                t = {
                    name = v:match('%{......%}%[�� ���������%]%{......%}%s+(.+)\t'),
                    id = i,
                    spawn = false
                }
            elseif v:match('%[������������%]') then
                t = {
                    name = v:match('%{......%}%[������������%]%{......%}%s+(.+)\t'),
                    id = i,
                    spawn = false,
                    pfine = true
                }
            elseif v:match('{......}%s.+%(%d+%)\t') then
                t = {
                    name = v:match('{......}%s(.+)%(%d+%)\t'),
                    id_car = v:match('{......}%s.+%((%d+)%)\t'),
                    id = i,
                    spawn = true
                }
            elseif v:match('%s.+%(%d+%)\t') then
                t = {
                    name = v:match('%s(.+)%(%d+%)\t'):gsub('^%s',''),
                    id_car = v:match('%s.+%((%d+)%)\t'):gsub('^%s',''),
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
        elseif information then
            information = false
        else
            command = '/cars'; id_dialog = 162; cars_info = '��� ���������'
            if not target_window.v and not work and not check_keystate then 
                main_window.v = true; aboutmod, parkingmod, reloadmod, info_update = false 
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
                if check_keystate then
                    carname = cars[carid]['name']; state_spawn = cars[carid]['spawn']
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
    if id == 0 and style == 0 and title == '{BFBBBA}����������' and (main_window.v or target_window.v) or check_keystate then
        car_info = {}
        local t = {
            carname = text:match('%{FFFFFF%}���������%: %{73B461%}(.+)%{FFFFFF%}.+��������'),  
            owner = text:match('��������: {......}(%w+_%w+){......}'),
            intermediary = text:match('���������%: %{73B461%}(%D+)%{FFFFFF%}'),
            mileage = text:match('������%: %{73B461%}(%d+ ��.)%{FFFFFF%}'),
            tax = text:match('�����%: %{73B461%}(%d+)%{FFFFFF%} %/ 150 000'),
            fine = text:match('�����%: %{73B461%}(%d+)%{FFFFFF%} %/ 80 000'),
            recovery_penalty = text:match('����� �� ��������������%: %{73B461%}($.+)%{FFFFFF%}.+���� �������'):gsub('%.',''):gsub('%,',''):gsub('%s', ''),
            price = text:match('���� ������� � ����%:%s%{......%}($[%-%d%.%,]+)'):gsub('%.',''):gsub('%,',''),
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
        check_keystate = false
        return false
    end
end

function comma(n)
    local v1, v2, v3 = string.match(n,'^([^%d]*%d)(%d*)(.-)$')
    return (tonumber(n) == 0 and 0 or (v1 .. (v2:reverse():gsub('(%d%d%d)','%1.'):reverse()) .. v3))
end

local refueling = lua_thread.create_suspended(function()
    while true do wait(0)
        wait(228)
        sampSendClickTextdraw(idtextdraw_change)
        wait(228)
        sampSendClickTextdraw(idtextdraw_fill)
    end
end)

function sampev.onDisplayGameText(style, time, text)
    if style == 3 then
        if text:match('CAR%~[gr]%~ (%u+)%~n%~%/lock') then door_state = not door_state end
        if text:match('Style%:.+%~(%w+)%!') then drive_state = not drive_state end
        if text:match('ABS%: .+%~(%u+)%!') then abs_state = not abs_state end
    end
end

function sampev.onSendCommand(cmd)
    if cmd == '/balon' then
        clrBalon = {}
        balon_stage = 1
        balon_window.v = not balon_window.v
    end
end

function sampev.onShowTextDraw(id, data)
    if active_jack then
        if data.text == 'INVENTORY' or data.text == '�H�EH�AP�' then
            one_page = id + 2
        end
        textdrawInfo[#textdrawInfo+1] = {
            ['id'] = id,
            ['text'] = data.text,
            ['model'] = data.modelId,
            ['zoom'] = data.zoom
        }
        lua_thread.create(function()
            if data.text == 'USE' or data.text == '�C�O���O�A��' and use_jack then
                local clickID = id + 1
                sampSendClickTextdraw(clickID)
                use_jack = false
                close_jack = true
            end
            if close_jack then
                wait(111)
                sampSendClickTextdraw(65535)
                close_jack = false
                active_jack = false
            end
        end)
    end

    if data.text == 'DIESEL' and cfg.CheckBox.fuel then step = 1 end
    if data.text:find('%$%d+') and step == 1 then step = 2; idtextdraw_money = id end
    if data.text:find('LD%_BEAT%:chit') and data.lineWidth == 19 and step == 2 then step = 3; idtextdraw_change = id end
    if data.text:find('FILL') and step == 3 then step = 4; idtextdraw_fill = id; sampSendClickTextdraw(idtextdraw_money); refueling:run() end

end

function sampev.onServerMessage(color,text)
    if text:find('%* ������������ �������� ������������ %(%( '.. sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))) ..' %)%)') and step == 4 then refueling:terminate() end
    if text:find('%[����������%] {FFFFFF}������ ����� ����� �� ������ forum%.arizona%-rp%.com') then
        return { color, '[����������] {FFFFFF}������ ����� ����� ����������� ������� - {FFFF00}/balon [��� ����������]' }
    end
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
    if text:find(sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))).. ' ��������%(�%) ���������') and key_state then
        lua_thread.create(function()
            wait(228)
            sampSendChat('/key')
        end)
    end
    if text:find(sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))).. ' �������%(�%) ����� �� ����� ���������') or text:find(sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))).. ' �������%(�%) ����� � ����� ���������') then key_state = not key_state end
    if text:find('��������� ��������� �� �������') then return false end
    if text:find('���������� �������� ����� � ���������') and CheckBox['enter'].v and itsmycar and not key_state then
        sampSendChat('/key'); engine = true
        return false 
    end
    if text:find(sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))) .. ' �������%(�%) ����� � ����� ���������') and engine then
        engine = false;
        lua_thread.create(function() wait(700); sampSendChat('/engine') end)
    end 
    if text:find('������ ��������� ����� ���� ���� ������������, ������� ��������� ���� ����') and working then
        working = false
    end
    if cfg.CheckBox.fuel then
        if text:find('������ ��� ������� �� �������� ��� ������ ����������') then return false end
        if text:find('����������� ������ ����� ������� ��� ������� � ��� ���%-��') or text:find('�� ������ ��������� ������ ��� %- ����� �� ��������� �������') then return false end
    end
    if text:find('������� ���. �������.') then return false end
end

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end

    local update_file = getWorkingDirectory() .. '\\config\\mycar.json';
    downloadUrlToFile('https://raw.githubusercontent.com/sd-scripts/lua-scripts/main/mycar.json', update_file, function(id, status, p1, p2)
        if status == 6 then    
            local f = io.open(update_file, 'r+');
            if f then
                data = decodeJson(f:read('a*'));
                f:close();
            end
            os.remove(update_file)
        end
    end)

    if not doesFileExist('moonloader/config/MyCar.ini') then
        if inicfg.save(cfg, 'MyCar.ini') then print('{FF8C00}��������������: {ffffff}���� ������������ �� ������. ������ ����: {00ff00}config\\MyCar.ini') end
    end

    if memory.tohex(getModuleHandle("samp.dll") + 0xBABE, 10, true ) == "E86D9A0A0083C41C85C0" then
        sampIsLocalPlayerSpawned = function()
            local res, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
            return sampGetGamestate() == 3 and res and sampGetPlayerAnimationId(id) ~= 0
        end
    end
    
    while not sampIsLocalPlayerSpawned() do wait(120) end
    
    local result, nameServ = checkServer(select(1, sampGetCurrentServerAddress()))
    
    if not result then
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
                if not sampIsChatInputActive() and not sampIsDialogActive() and not isSampfuncsConsoleActive() and pauseMenu() ~= 1 then
                    sampSendChat('/key')
                end
            end   
        end)
        bindJack = rkeys.registerHotKey(ActiveJack.v, true, function ()
            if not sampIsChatInputActive() and not sampIsDialogActive() and not isSampfuncsConsoleActive() and isCharInAnyCar(PLAYER_PED) and pauseMenu() ~= 1 then
                jack = true  
            end
        end)
        bindLock = rkeys.registerHotKey(ActiveLock.v, true, function ()
            if not sampIsChatInputActive() and not sampIsDialogActive() and not isSampfuncsConsoleActive() and pauseMenu() ~= 1 then
                sampSendChat('/lock')  
            end
        end)
        bindStyle = rkeys.registerHotKey(ActiveStyle.v, true, function ()
            if not sampIsChatInputActive() and not sampIsDialogActive() and not isSampfuncsConsoleActive() and isCharInAnyCar(PLAYER_PED) and pauseMenu() ~= 1 then
                sampSendChat('/style')  
            end
        end)
        bindLimit = rkeys.registerHotKey(ActiveLimit.v, true, function ()
            if not sampIsChatInputActive() and not sampIsDialogActive() and not isSampfuncsConsoleActive() and isCharInAnyCar(PLAYER_PED) and pauseMenu() ~= 1 then
                l_limit = not l_limit
                sampSendChat('/limit ' .. (l_limit and 115 or 0))  
            end
        end)
    end

    if doesFileExist('moonloader/mycar.json') then os.remove(getWorkingDirectory() .. '\\mycar.json') end

    lua_thread.create(Speedometer)

    while true do wait(0)
        imgui.Process = main_window.v or target_window.v or balon_window.v
        target.check()
        vehicle.check()
        if sampGetGamestate() == 3 and pauseMenu() ~= 1 then
            if jack then
                if sampIsDialogActive() then
                  sampCloseCurrentDialogWithButton(0)
                end
                sampSendClickTextdraw(65535)
                wait(355)
                active_jack = true
                textdrawInfo = {}
                page = 1
                sampSendChat('/invent')
                jack = false
            end
            if active_jack and textdrawInfo then
                local next_page = true
                wait(228)
                for k,v in pairs(textdrawInfo) do
                    if v['model'] == 19900 and v['zoom'] > 1 then
                        next_page = false
                        wait(228)
                        sampSendClickTextdraw(v['id'])
                        textdrawInfo = {}
                        use_jack = true
                        break
                    end
                end
                if next_page then
                    wait(228);
                    if one_page > 2000 then
                        if page < 3 then
                            sampSendClickTextdraw(page + one_page);
                            wait(600); 
                            page = page + 1
                        else
                            sampSendClickTextdraw(65535)
                            textdrawInfo = {}; 
                            active_jack = false
                            wait(123)
                            sampAddChatMessage('[������] {FFFFFF}� ��� ��� ��������.', 0xBE2D2D)
                        end
                    end
                end
            end
            if encodeJson(cars) == '{}' then
                information = true
                sampSendChat('/cars')
                wait(350)
            else
                if isCharInAnyCar(PLAYER_PED) then
                    local car = getCarCharIsUsing(PLAYER_PED)
                    local vehicle_id = select(2, sampGetVehicleIdByCarHandle(car))
                    for i, v in ipairs(cars) do
                        itsmycar = false
                        if tonumber(v.id_car) == tonumber(vehicle_id) then
                            itsmycar = true
                            if key_state == nil then
                                carid = i
                                check_keystate = true
                                sampSendChat('/cars')
                                wait(350)
                            end
                            break
                        end
                    end
                    veh = storeCarCharIsInNoSave(PLAYER_PED)
                    if doesVehicleExist(veh) and not col_prim and not col_sec then
                        col_prim, col_sec = getCarColours(veh)
                    end
                else
                    veh, col_prim, col_sec = nil
                end
            end
            if (isKeyJustPressed(keys.VK_F) or isKeyJustPressed(keys.VK_RETURN)) and CheckBox['key'].v and itsmycar and key_state then        
                if isCharInAnyCar(playerPed) and not isSampfuncsConsoleActive() and not sampIsChatInputActive() and not sampIsDialogActive() and (string.format('%4.2f', getCarSpeed(storeCarCharIsInNoSave(playerPed))) < '30') then    
                    sampSendChat('/key')	
                end  
            end
            if isKeyJustPressed(cfg.HotKey.interaction:match('%[(%d+)%]')) and not isSampfuncsConsoleActive() and not sampIsChatInputActive() and not sampIsDialogActive() then
                if target.state then 
                    target_window.v = true; sampSendChat('/cars')
                elseif vehicle.state then
                    target_window.v = true
                end
            end

            while isPauseMenuActive() do
                if cursorEnabled then
                    showCursor(false)
                end
                wait(100)
            end
    
            -- MiddleButton Select by Cosmo
            if isKeyDown(cfg.HotKey.mouse:match('%[(%d+)%]')) and isCharInAnyCar(PLAYER_PED) and not isSampfuncsConsoleActive() and not sampIsChatInputActive() and not sampIsDialogActive() and not target_window.v and cars then
                local car = getCarCharIsUsing(PLAYER_PED)
                local vehicle_id = select(2, sampGetVehicleIdByCarHandle(car))
                for i, v in ipairs(cars) do
                    if tonumber(v.id_car) == tonumber(vehicle_id) then
                        cursorEnabled = not cursorEnabled
                        if cursorEnabled then
                            target.state = true
                            target.time = os.clock() + 2
                            choose_car, servercarid = v.name, v.id_car
                        end
                        showCursor(cursorEnabled)
                        while isKeyDown(cfg.HotKey.mouse:match('%[(%d+)%]')) do wait(80) end
                    end
                end
            end
    
            if cursorEnabled then
                if sampGetCursorMode() == 0 then -- ���� ������� ����� cursorEnabled �� ���������, �������� �������� :D
                    showCursor(true)
                end
                local sx, sy = getCursorPos() -- ���������� ������� �� ������
                local sw, sh = getScreenResolution() -- ���������� ������
                if sx >= 0 and sy >= 0 and sx < sw and sy < sh then -- ���� ������ �� � ������� ����������� � �� ������� �� ����� ������ ��..
                    local posX, posY, posZ = convertScreenCoordsToWorld3D(sx, sy, 700.0) -- ������ ����� � 3D-������������ ���� �� ��������� �������
                    local camX, camY, camZ = getActiveCameraCoordinates() -- ����������� ������ �� ���� ����
                    local result, colpoint = processLineOfSight(camX, camY, camZ, posX, posY, posZ, true, true, true, true, false, false, false) -- ��� ����� �� ��� ������ ������ (������/���/����������� � �.�)
                    if result and colpoint.entity ~= 0 then -- ���� ������ �� ���� ����� �� ����������� ��..
                        if colpoint.entityType == 3 then -- ��� ��������: Ped
                            local resb, idb = sampGetPlayerIdByCharHandle(getCharPointerHandle(colpoint.entity)) -- �������� �� ����� ����� �������� (��������� � ������ ������)
                            if sampIsPlayerConnected(idb) and getCharPointerHandle(colpoint.entity) ~= playerPed then -- ���� ����� ���������� � ��� ����� ���������� �� ������ ��..
                                if distanceBetweenPlayer(idb) < 10 then
                                    DrawText_char = "���, ����� ������� ������:\n"..sampGetPlayerNickname(idb).."["..idb.."]"
                                    y_offset_char = sy - 35
                                else
                                    DrawText_char = "���� ����� ������� ������ �� ���"
                                    y_offset_char = sy - 20
                                end
                                renderFontDrawText(font, DrawText_char, sx, y_offset_char, 0xFFFFFFFF)
                            else
                                renderFontDrawText(font, '��� ��..', sx, sy - 20, 0x50FFFFFF)
                            end
                            if isKeyDown(keys.VK_LBUTTON) and getCharPointerHandle(colpoint.entity) ~= playerPed then -- ���� ������ ��� � ��������� ����� �� ����� ������ ��..
                                if resb and distanceBetweenPlayer(idb) < 10 then -- ���� ����� ������ ��� � 20 ������ �� ���, �� �� ���� ������� ���� (����� ����-��)
                                    choose_act = true;
                                    target.i.id, target.i.name, target.i.lvl, target.i.car = idb, sampGetPlayerNickname(idb), sampGetPlayerScore(idb), true
                                    target_window.v = true
                                end
                                setVirtualKeyDown(keys.VK_LBUTTON, true) -- � ��� �����, �� ��� ����� ����� ������� ������ ������� �� ��������
                                setVirtualKeyDown(keys.VK_LBUTTON, false) -- ����� ������� ��������� ������� ������� (���) + ��� ������ � ���� ����������� ��� ������ ����, ������ ������
                                cursorEnabled = false -- ����� ������
                                showCursor(false)
                            end
                        else 
                            renderFontDrawText(font, '�������� ������ �� ������', sx, sy - 35, 0x50FFFFFF)
                        end
                    end
                end
            end

        end
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
                        if not target_window.v and CheckBox['hint'].v then renderFontDrawText(font, '( '..table.concat(rkeys.getKeysName(ActiveInteraction.v), ' + ')..' )', x, y, 0xFFA9A9A9) end
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
                    sampCreate3dTextEx(777, '( '..table.concat(rkeys.getKeysName(ActiveInteraction.v), ' + ')..' )', 0xffA9A9A9, 0, 0, -0.75, 7, false, pID, -1)
                end
                target.i.id, target.i.name, target.i.lvl = pID, sampGetPlayerNickname(pID), sampGetPlayerScore(pID)
                target.state = true
                target.time = os.clock() + 2
            end
        end
        if not result and not cursorEnabled and not target.state and isCharInAnyCar(PLAYER_PED) and cars then
            local car = getCarCharIsUsing(PLAYER_PED)
			local vehicle_id = select(2, sampGetVehicleIdByCarHandle(car))
            for i, v in ipairs(cars) do
                if tonumber(v.id_car) == tonumber(vehicle_id) then
                    for k, ped in ipairs(getAllChars()) do
                        if ped ~= PLAYER_PED then
                            local car_ped = isCharInAnyCar(ped)
                            local res, pID = sampGetPlayerIdByCharHandle(ped)
                            if res and not car_ped then
                                local xp, yp, zp = getCharCoordinates(ped) -- ���������� ���������� ������
                                local x, y, z = getCharCoordinates(PLAYER_PED) -- ���������� ���������� ������
                                local dist = getDistanceBetweenCoords3d(xp, yp, zp, x, y, z)
                                if dist <= 3.0 then
                                    if CheckBox['hint'].v then
                                        sampCreate3dTextEx(777, '( '..table.concat(rkeys.getKeysName(ActiveInteraction.v), ' + ')..' )', 0xffA9A9A9, 0, 0, -0.75, 7, false, pID, -1)
                                    end
                                    choose_car, servercarid = v.name, v.id_car; choose_act = true;
                                    target.i.id, target.i.name, target.i.lvl, target.i.car = pID, sampGetPlayerNickname(pID), sampGetPlayerScore(pID), true
                                    target.state = true
                                    target.time = os.clock() + 2
                                end
                            end
                        end
                    end
                end
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
        if (wparam == keys.VK_ESCAPE and (main_window.v or target_window.v or balon_window.v)) and not isPauseMenuActive() and not isSampfuncsConsoleActive() then
            consumeWindowMessage(true, false)
            if msg == 0x101 then
                main_window.v = false; target_window.v = false; balon_window.v = false
            end
        end
    end
end
function pauseMenu()
    return memory.getuint8(0xBA6748 + 0x5C)
end

function sampGetVehicleModelById(vehicleId) -- ������� ��������� ����� ���������� �� ��� ���������� id
    local ovehicleNames = {
        -- SA:MP VEHICLE
        [400] = 'Landstalker', [401] = 'Bravura', [402] = 'Buffalo', [403] = 'Linerunner', [404] = 'Perrenial',
        [405] = 'Sentinel', [406] = 'Dumper', [407] = 'Firetruck', [408] = 'Trashmaster', [409] = 'Stretch',
        [410] = 'Manana', [411] = 'Infernus',  [412] = 'Voodoo', [413] = 'Pony', [414] = 'Mule',
        [415] = 'Cheetah', [416] = 'Ambulance', [417] = 'Leviathan', [418] = 'Moonbeam', [419] = 'Esperanto',
        [420] = 'Taxi', [421] = 'Washington',  [422] = 'Bobcat', [423] = 'Whoopee', [424] = 'BF Injection',
        [425] = 'Hunter', [426] = 'Premier', [427] = 'Enforcer', [428] = 'Securicar', [429] = 'Banshee',
        [430] = 'Predator', [431] = 'Bus', [432] = 'Rhino', [433] = 'Barracks', [434] = 'Hotknife',
        [435] = 'Article Trailer', [436] = 'Previon', [437] = 'Coach', [438] = 'Cabbie', [439] = 'Stallion',
        [440] = 'Rumpo', [441] = 'RC Bandit', [442] = 'Romero', [443] = 'Packer', [444] = 'Monster',
        [445] = 'Admiral', [446] = 'Squalo', [447] = 'Seasparrow', [448] = 'Pizzaboy', [449] = 'Tram',
        [450] = 'Article Trailer 2', [451] = 'Turismo', [452] = 'Speeder', [453] = 'Reefer', [454] = 'Tropic',
        [455] = 'Flatbed', [456] = 'Yankee', [457] = 'Caddy', [458] = 'Solair', [459] = 'Topfun Van',
        [460] = 'Skimmer', [461] = 'PCJ-600', [462] = 'Faggio', [463] = 'Freeway', [464] = 'RC Baron',
        [465] = 'RC Raider', [466] = 'Glendale', [467] = 'Oceanic', [468] = 'Sanchez', [469] = 'Sparrow',
        [470] = 'Patriot', [471] = 'Quad', [472] = 'Coastguard', [473] = 'Dinghy', [474] = 'Hermes',
        [475] = 'Sabre', [476] = 'Rustler', [477] = 'ZR-350', [478] = 'Walton', [479] = 'Regina',
        [480] = 'Comet', [481] = 'BMX', [482] = 'Burrito', [483] = 'Camper', [484] = 'Marquis',
        [485] = 'Baggage', [486] = 'Dozer', [487] = 'Maverick', [488] = 'News Maverick', [489] = 'Rancher',
        [490] = 'FBI Rancher', [491] = 'Virgo', [492] = 'Greenwood', [493] = 'Jetmax', [494] = 'Hotring Racer',
        [495] = 'Sandking', [496] = 'Blista Compact', [497] = 'Police Maverick', [498] = 'Boxvillde', [499] = 'Benson',
        [500] = 'Mesa', [501] = 'RCGoblin', [502] = 'Hotring Racer A', [503] = 'Hotring Racer B', [504] = 'Bloodring Banger',
        [505] = 'Rancher', [506] = 'SuperGT', [507] = 'Elegant', [508] = 'Journey', [509] = 'Bike',
        [510] = 'Mountain Bike', [511] = 'Beagle', [512] = 'Cropduster', [513] = 'Stunt', [514] = 'Tanker',
        [515] = 'Roadtrain', [516] = 'Nebula', [517] = 'Majestic', [518] = 'Buccaneer', [519] = 'Shamal',
        [520] = 'Hydra', [521] = 'FCR-900', [522] = 'NRG-500', [523] = 'HPV1000', [524] = 'Cement Truck',
        [525] = 'TowTruck', [526] = 'Fortune', [527] = 'Cadrona', [528] = 'FBI Truck', [529] = 'Willard',
        [530] = 'Forklift', [531] = 'Tractor', [532] = 'Combine', [533] = 'Feltzer', [534] = 'Remington',
        [535] = 'Slamvan', [536] = 'Blade', [537] = 'Freight', [538] = 'Streak', [539] = 'Vortex',
        [540] = 'Vincent', [541] = 'Bullet', [542] = 'Clover', [543] = 'Sadler', [544] = 'Firetruck',
        [545] = 'Hustler', [546] = 'Intruder', [547] = 'Primo', [548] = 'Cargobob', [549] = 'Tampa',
        [550] = 'Sunrise', [551] = 'Merit', [552] = 'Utility Van', [553] = 'Nevada', [554] = 'Yosemite',
        [555] = 'Windsor', [556] = 'Monster', [557] = 'Monster', [558] = 'Uranus', [559] = 'Jester',
        [560] = 'Sultan', [561] = 'Stratum', [562] = 'Elegy', [563] = 'Raindance', [564] = 'RC Tiger',
        [565] = 'Flash', [566] = 'Tahoma', [567] = 'Savanna', [568] = 'Bandito', [569] = 'Freight Flat Trailer',
        [570] = 'Streak Trailer', [571] = 'Kart', [572] = 'Mower', [573] = 'Dune', [574] = 'Sweeper',
        [575] = 'Broadway', [576] = 'Tornado', [577] = 'AT400', [578] = 'DFT-30', [579] = 'Huntley',
        [580] = 'Stafford', [581] = 'BF-400', [582] = 'NewsVan', [583] = 'Tug', [584] = 'Petrol Trailer',
        [585] = 'Emperor', [586] = 'Wayfarer', [587] = 'Euros', [588] = 'Hotdog', [589] = 'Club',
        [590] = 'Freight Box Trailer', [591] = 'Article Trailer 3', [592] = 'Andromada', [593] = 'Dodo', [594] = 'RC Cam',
        [595] = 'Launch', [596] = 'Police Car (LSPD)', [597] = 'Police Car (SFPD)', [598] = 'Police Car (LVPD)', [599] = 'Police Ranger',
        [600] = 'Picador', [601] = 'S.W.A.T.', [602] = 'Alpha', [603] = 'Phoenix', [604] = 'Glendale Shit',
        [605] = 'Sadler Shit', [606] = 'Baggage Trailer "A"', [607] = 'Baggage Trailer "B"', [608] = 'Tug Stairs Trailer', [609] = 'Boxville',
        [610] = 'Farm Trailer', [611] = 'Utility Trailer',
        -- ARIZONA VEHICLES
        [612] = 'Mercedes GT63s AMG', [613] = 'Mercedes G63 AMG', [614] = 'Audi RS6', [662] = 'BMW X5', [663] = 'Chevrolet Corvette', 
        [665] = 'Chevrolet Cruze', [666] = 'Lexus LX', [667] = 'Porsche 911', [668] = 'Porsche Cayenne', [699] = 'Bentley Continental', 
        [793] = 'BMW M8', [794] = 'Mercedes E63s AMG', [909] = 'Mercedes S63', [965] = 'Volkswagen Tuareg', [1194] = 'Lamborghini Urus',
        [1195] = 'aqeight', [1196] = 'Dodge Challenger', [1197] = 'Acura NSX', [1198] = 'Volvo V60', [1199] = 'Range Rover', 
        [1200] = 'Honda Civic Type-R', [1201] = 'Lexus Sport-S', [1202] = 'Ford Mustang', [1203] = 'Volvo XC90', [1204] = 'Jaguar F-Pace',
        [1205] = 'KIA Optima', [3155] = 'BMW Z4 40i', [3156] = 'Mercedes-Benz S600', [3157] = 'BMW X5 E53', [3158] = 'Nissan Skyline GT-R',
        [3194] = 'Ducati Daivel', [3195] = 'Ducati Panigale', [3196] = 'Ducati Ducnaked', [3197] = 'Kawasaki Ninja ZX-10RR', [3198] = 'Western',
        [3199] = 'Rolls-Royce Cullinan', [3200] = 'Volkswagen Beetle', [3201] = 'Bugatti Divo', [3202] = 'Bugatti Chiron', [3203] = 'Fiat 500',
        [3204] = 'Mercedes-Benz GLS 2020', [3205] = 'Mercedes-AMG G65 AMG', [3206] = 'Lamborghini Aventador', [3207] = 'Range Rover SVA', [3208] = 'BMW 530i',
        [3209] = 'Mercedes-Benz S600', [3210] = 'Tesla Model X', [3211] = 'Nissan Leaf', [3212] = 'Nissan Silvia', [3213] = 'Subaru Forester XT',
        [3215] = 'Subaru Legasy', [3216] = 'Hyundai Sonata',  [3217] = 'BMW 750i', [3218] = 'Mercedes-Benz E55 AMG', [3219] = 'Mercedes-Benz E500',
        [3220] = 'jstorm', [3222] = 'lightmcq', [3223] = 'mater', [3224] = 'Buckingham', [3232] = 'Infinity FX 50',
        [3233] = 'Lexus RX 450h', [3234] = 'KIA Sportage', [3235] = 'Volkswagen Golf R', [3236] = 'Audi R8', [3237] = 'Toyota Camry XV40',
        [3238] = 'Toyota Camry XV70', [3239] = 'BMW M5 E60', [3240] = 'BMW M5 F90', [3245] = 'Mercedes Maybach S650', [3247] = 'Mercedes-Benz AMG GT',
        [3248] = 'Porsche Panamera Turbo', [3251] = 'Volkswagen Passat', [3254] = 'Chevrolet Corvette', [3266] = 'Dodge Ram', [3348] = 'Ford Mustang Shelby GT500',
        [3974] = 'Aston Martin DB5', [4542] = 'BMW M3 GTR', [4543] = 'Chevrolet Camaro', [4544] = 'Mazda RX-7', [4545] = 'Mazda RX-8',
        [4546] = 'Mitsubishi Eclipse', [4547] = 'Ford Mustang 289', [4548] = 'Nissan 350Z'
    }
    return ovehicleNames[vehicleId] or '�� ����������'
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
        imgui.SetNextWindowSize(imgui.ImVec2(190, 238))
        imgui.Begin('##targetwindow',  target_window, imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoMove)
        imgui.SetCursorPosY(10)
        imgui.CenterTextColoredRGB('{808080}���� ��������������')
        imgui.Separator()
        if vehicle.state then
            imgui.CenterTextColoredRGB('{FFD848}' .. sampGetVehicleModelById(vehicle.i.model) .. '[' .. getClosestCarId() .. ']')
            imgui.SetCursorPosY(60)
            if imgui.Button(u8'�������/�������', imgui.ImVec2(175,25)) then sampSendChat('/lock') end
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
                if not sell_car then
                    imgui.SetCursorPosY(60)
                    if imgui.Button(u8'�������� �����', imgui.ImVec2(175,25)) then sampSendChat('/givekey ' ..target.i.id.. ' ' ..servercarid); choose_car = ''; target_window.v = false; choose_act = false end
                    if imgui.Button(u8'�������� �������', imgui.ImVec2(175,25)) then sampSendChat('/carpass ' ..target.i.id.. ' ' ..servercarid); choose_car = ''; target_window.v = false; choose_act = false end
                    if target.i.car then
                        if imgui.Button(u8'������� ������', imgui.ImVec2(175,25)) then 
                            sell_car = true
                        end
                    end
                else
                    imgui.SetCursorPosY(60)
                    imgui.CenterTextColoredRGB('{BE2D2D}������� ���� �������:')
                    imgui.InputText('##price car', price_car)
                    if imgui.Button(u8'�������', imgui.ImVec2(175,25)) then
                        if tonumber(price_car.v) >= 10000 then
                            target_window.v = false
                            sampSendChat('/sellcarto ' ..target.i.id.. ' ' ..price_car.v)
                            choose_act, sell_car = false; 
                            choose_car = ''; price_car.v = ''
                        else
                            sampAddChatMessage('[������] {FFFFFF}������� ����� ����� ���� ������ 10000$.', 0xBE2D2D)
                        end
                    end
                end
                imgui.SetCursorPosY((target.i.car and 170 or 150))
                imgui.CenterTextColoredRGB('{808080}��������� �/c:')
                imgui.CenterTextColoredRGB('{73B461}' ..choose_car)
                imgui.ColorButton(64, 105, 15, 52, 84, 12, 77, 125, 17)
                if not target.i.car then
                    if imgui.Button(u8'�����', imgui.ImVec2(175,20)) then
                        choose_act = false; choose_car = ''
                    end
                end
                imgui.PopStyleColor(3)
            end
        end
        imgui.SetCursorPosY(210)
		imgui.ColorButton(112, 112, 112, 99, 99, 99, 130, 130, 130)
        if imgui.Button(u8'�������', imgui.ImVec2(175,20)) then target_window.v = false; choose_act, sell_car = false; choose_car = ''; price_car.v = '' end
        imgui.PopStyleColor(3)
        imgui.End()
    end
    if balon_window.v then
        local sw, sh = getScreenResolution()
        imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(650, 700))
        imgui.Begin(u8((veh and '���������� ����� �����' or '����� ����� ���������')),  balon_window, imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoCollapse)

        for i = 0, 255 do
            imgui.PushStyleColor(imgui.Col.Button, imgui.ColorConvertU32ToFloat4(getCarTabColor(i)))
            imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ColorConvertU32ToFloat4(getCarTabColor(i) - 5))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ColorConvertU32ToFloat4(getCarTabColor(i) + 10))
            if imgui.Button(tostring(i), imgui.ImVec2(35, 35)) then
                if i ~= 0 then
                    clrBalon[#clrBalon + 1] = tostring(i)
                    balon_stage = balon_stage + 1
                else
                    sampAddChatMessage('[������] {FFFFFF}�����������: /balon [���� 1 > 0] [���� 2 > 0]', 0xBE2D2D)
                end
            end
            imgui.PopStyleColor(3)
            local n = i + 1
            if n % 16 > 0 then
                imgui.SameLine()
            end
        end
    
        imgui.BeginChild('##clrBalon1', imgui.ImVec2(635, 40), true)
            if veh then 
                imgui.SetCursorPosY(4)
                imgui.TextColoredRGB('{D3D3D3}����� ����������:')
                imgui.SetCursorPosX(40)
                imgui.SetCursorPosY(20)
                imgui.TextColoredRGB('{7CFC00}' ..col_prim.. ', ' ..col_sec)
            end
            imgui.SetCursorPosX(250)
            imgui.SetCursorPosY(12)
            imgui.TextColoredRGB((balon_stage == 1 and '{808080}�������� ������ ����' or '{FFFFFF}��������� ���� �1: {228fff}' ..clrBalon[1]))
            imgui.SameLine()

            imgui.SetCursorPosX(475)
            imgui.SetCursorPosY(6)
            if balon_stage == 2 then
                if imgui.Button(u8'�����', imgui.ImVec2(153,30)) then
                    balon_stage = 1
                    clrBalon = {}
                end
            else
                if veh and new_col_prim and new_col_sec then
                    if imgui.Button(u8'�������', imgui.ImVec2(153,30)) then
                        colorVehicle(col_prim, col_sec)
                        new_col_prim, new_col_sec = nil
                        balon_stage = 1
                        clrBalon = {}
                    end
                end
            end

        imgui.EndChild()

        if balon_stage == 3 then
            if veh then
                colorVehicle(clrBalon[1], clrBalon[2])
                new_col_prim, new_col_sec = clrBalon[1], clrBalon[2]
                balon_stage = 1
                clrBalon = {}
            else
                sampSendChat('/balon ' ..clrBalon[1].. ' ' ..clrBalon[2])
                balon_stage = 1
                clrBalon = {}
                balon_window.v = false
            end
        end
        imgui.End()
    end
    if main_window.v then
 
        imgui.CenterText = function(text)
            imgui.SetCursorPosX((imgui.GetWindowWidth() - imgui.CalcTextSize(u8(text)).x)/2)
            imgui.Text(u8(text))
        end
 
        local sw, sh = getScreenResolution()
        imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(540, 485))
        imgui.Begin(u8('MyCar | ' ..cars_info),  main_window, imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoCollapse)
        imgui.BeginChild('##panel_1', imgui.ImVec2(170, 430), true)
            imgui.CenterText('������ ����������:')
            imgui.Spacing()
            for i, v in ipairs(cars) do
                if not aboutmod and not info_update then
                    imgui.ColButton(cars[i]['spawn'])
                    if imgui.Button(v['name'] .. '##' .. i, imgui.ImVec2(155,25)) and not work then
                        carname = v['name']; car_info = {}; carid = i; sampSendChat(command); sampSendDialogResponse(id_dialog, 1, cars[carid]['id'], -1); state_spawn = cars[carid]['spawn']; text_loads = '�������� ������...'; text_load = '�������� ������...'
                    end    
                    imgui.PopStyleColor(3)
                else
					imgui.ColorButton(112, 112, 112, 99, 99, 99, 222, 2, 2)
                    imgui.Button(v['name'] .. '##' .. i, imgui.ImVec2(155,25))
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
                imgui.Hint(u8('����� �� ������, � ��� ��������� ������ � ��������, ��� �� ������� ������� ������.'), 0.1)
                imgui.SameLine()
                if imgui.Button(u8'�����', imgui.ImVec2(163, 20)) then info_update = false end
            end
            if aboutmod then
                info_update = false
                imgui.SetCursorPosX(80); imgui.Text(fa.ICON_FA_ASTERISK); imgui.SameLine()
                imgui.CenterTextColoredRGB('{6495ED} �������������� �������'); imgui.Separator()
                if imadd.ToggleButton('##enter', CheckBox['enter']) then cfg.CheckBox.enter = CheckBox['enter'].v; inicfg.save(cfg, 'MyCar.ini') end
                imgui.SameLine(); imgui.Text(u8' ������������� ��������� ����� � �����')
                imgui.Hint(u8('������ �� ��� ����� ��������� ���� � ����� ��������� ��� ������� ������� ���������.'), 0.1)
                if imadd.ToggleButton('##key', CheckBox['key']) then cfg.CheckBox.key = CheckBox['key'].v; inicfg.save(cfg, 'MyCar.ini') end
                imgui.SameLine(); imgui.Text(u8' �������� ���� �� ����� ���������')
                imgui.Hint(u8('������ �� ��� ����� ��������� ����� �� ����� ��������� ��� ������ �� ������������� �������� � ����� �� ��������� ���������.'), 0.1)
                if imadd.ToggleButton('##unloading', CheckBox['unloading']) then
                    cfg.CheckBox.unloading = CheckBox['unloading'].v
                    inicfg.save(cfg, 'MyCar.ini') 
                end
                imgui.SameLine(); imgui.Text(u8' ��������� ���� ��������� ��� �����������')
                imgui.Hint(u8('��� ����� � ���� ������ �������� ��� ���� ������������ �������� � �������.'), 0.1)
                if imadd.ToggleButton('##fuel', CheckBox['fuel']) then cfg.CheckBox.fuel = CheckBox['fuel'].v; inicfg.save(cfg, 'MyCar.ini') end
                imgui.SameLine(); imgui.Text(u8' �������������� �������� ���������� �� ���')
                imgui.Hint(u8('������ �� ��� �������� �� ������� ���� ���� ������������ �������� �� ��������������� �������.'), 0.1)
				imgui.NewLine(); imgui.SetCursorPosX(100); imgui.Text(fa.ICON_FA_KEYBOARD); imgui.SameLine()
                imgui.CenterTextColoredRGB('{73B461}������� �������'); imgui.Separator()
                if imadd.HotKey('##menu', ActiveMenus, tLastKeys, 80) then
                    rkeys.changeHotKey(bindMenu, ActiveMenus.v)
                    cfg.HotKey.main = encodeJson(ActiveMenus.v)
					inicfg.save(cfg, 'MyCar.ini')
                end
                imgui.SameLine(); imgui.Text(u8' -   ������� ���� ������� (/cars)')
                if imadd.HotKey('##lock', ActiveLock, tLastKeys, 80) then
                    rkeys.changeHotKey(bindLock, ActiveLock.v)
					cfg.HotKey.lock = encodeJson(ActiveLock.v)
					inicfg.save(cfg, 'MyCar.ini')
                end
                imgui.SameLine(); imgui.Text(u8' -   �������/������� ��������� (/lock)')
                if imadd.HotKey('##key', ActiveKey, tLastKeys, 80) then
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
                if imadd.HotKey('##interaction', ActiveInteraction, tLastKeys, 80) then
                    rkeys.changeHotKey(bindInteraction, ActiveInteraction.v)
                    if ActiveInteraction.v[2] then ActiveInteraction.v = tLastKeys.v end
					cfg.HotKey.interaction = encodeJson(ActiveInteraction.v)
                    inicfg.save(cfg, 'MyCar.ini')
				end
                imgui.SameLine(); imgui.Text(u8' -   ���� ��������������')
                imgui.Hint(u8('��� �������������� � ������� - �������� ��� (���).\n����� ����������������� � �����������, ��������� � ���� � ������� �������.\n��� ����, ����� ��������� ��� ������� - ������� ������� ������� (������� �� ��, ����� Backspace).'), 0.1)
                imgui.SameLine(); imgui.SetCursorPosX(310)
                if imadd.ToggleButton('##hint',CheckBox['hint']) then cfg.CheckBox.hint = CheckBox['hint'].v; inicfg.save(cfg, 'MyCar.ini') end
                imgui.Hint(u8((CheckBox['hint'].v and '���������' or '��������').. ' ��������� ��� ������������� ������� (�� ���������/����������).'), 0.1)
                if imadd.HotKey('##limit', ActiveLimit, tLastKeys, 80) then
                    rkeys.changeHotKey(bindLimit, ActiveLimit.v)
					cfg.HotKey.limit = encodeJson(ActiveLimit.v)
                    inicfg.save(cfg, 'MyCar.ini')
                end
                imgui.SameLine(); imgui.Text(u8' -   ����������� �������� (/limit)')
                imgui.Hint(u8('��������/��������� ����� ��������, ����� �� ���������� �� ������� (������������ ����� - 115 ��/�).'), 0.1)
                if imadd.HotKey('##mouse', ActiveMouse, tLastKeys, 80) then
					cfg.HotKey.mouse = encodeJson(ActiveMouse.v)
                    inicfg.save(cfg, 'MyCar.ini')
                end
                imgui.SameLine(); imgui.Text(u8' -   ��������� ������� ����')
                imgui.Hint(u8('����������/������������ ������ ���� ��� ������ ���� ��������������, ����� �� ���������� � ���� ����������.'), 0.1)
                if imadd.HotKey('##jack', ActiveJack, tLastKeys, 80) then
                    rkeys.changeHotKey(bindJack, ActiveJack.v)
					cfg.HotKey.jack = encodeJson(ActiveJack.v)
                    inicfg.save(cfg, 'MyCar.ini')
                end
                imgui.SameLine(); imgui.Text(u8' -   ������������ �������')
                imgui.Hint(u8('������������� ���������� �������, �������� ��� �� ������ ���������.\n������� ����� ������ �� ����� �������� � ���������.'), 0.1)
				imgui.SetCursorPosY(335)
                imgui.NewLine(); imgui.SetCursorPosX(105); imgui.Text(fa.ICON_FA_SATELLITE_DISH); imgui.SameLine()
                imgui.CenterTextColoredRGB('{A9A9A9}�������� �����:'); imgui.Separator()
				imgui.ColorButton(11, 88, 230, 10, 80, 209, 12, 94, 245)
                if imgui.Button(u8'���������', imgui.ImVec2(107,20)) then os.execute('explorer "https://vk.com/sd_scripts"') end
                imgui.PopStyleColor(3)
                imgui.Hint(u8('����� �� ������, � ��� ��������� ������ � �������� ����� ������ ���������.'), 0.1)
                imgui.SameLine()
                
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.19, 0.22, 0.26, 1.0))
                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.15, 0.18, 0.22, 1.0))
                imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.11, 0.14, 0.18, 1.0))
                if imgui.Button('BlastHack', imgui.ImVec2(107,20)) then os.execute('explorer "https://www.blast.hk/threads/76299/"') end
                imgui.PopStyleColor(3)
                imgui.Hint(u8('����� �� ������, � ��� ��������� ������ � �������� ���� �� ������� BlastHack.'), 0.1)
				imgui.SameLine()
				imgui.ColorButton(35, 84, 25, 30, 70, 20, 48, 115, 34)
				if imgui.Button(u8'������������', imgui.ImVec2(109,20)) then os.execute('explorer "https://vk.me/sd_scripts"') end
				imgui.PopStyleColor(3)
                imgui.Hint(u8('����� �� ������, �� ������� � ������������ (������ ��������� ����� ������ ���������).'), 0.1)
				imgui.Separator()
				
                imgui.SetCursorPosY(405)
				imgui.ColorButton(120, 34, 34, 107, 30, 30, 135, 38, 38)
                if imgui.Button(u8'���������', imgui.ImVec2(115,20)) then thisScript():unload() end
				imgui.PopStyleColor(3)
                imgui.Hint(u8('��������� ������ �� ������������ (CTRL+R) ��� ���������� � ����.'), 0.1)
                imgui.SameLine()
                imgui.ColorButton(16, 73, 148, 16, 65, 130, 21, 86, 171)
                if imgui.Button(u8'�������������', imgui.ImVec2(115,20)) then thisScript():reload() end
                imgui.PopStyleColor(3)
                imgui.Hint(u8('������ ������������ �������.'), 0.1)
                imgui.SameLine()
                if imgui.Button(u8'�������', imgui.ImVec2(93,20)) then aboutmod = false end
                imgui.Hint(u8('��������� ���� ��������.'), 0.1)
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
                    imgui.CenterTextColoredRGB('{228fff}�������: {C0C0C0}' ..tostring(car_info[1] and car_info[1].carname or ''))  
                    imgui.Separator()
                    imgui.Columns(2)
                    local arrayText = {'��������', '���������', '������', '�����', '�����', '����� �� ��������������', '��������������� ���������', '��������������� �����', '��������', '����������� ���������', '��������� �����', '��������� (�� �����������)', '��������� (�� ���)'}
                    local arrayInfo = {car_info[1] and car_info[1].owner or '--', car_info[1] and car_info[1].intermediary or '--', car_info[1] and car_info[1].mileage or '--', car_info[1] and car_info[1].tax.. ' �� 150000' or '--', car_info[1] and car_info[1].fine.. ' �� 80000' or '--', car_info[1] and comma(car_info[1].recovery_penalty) or '--', car_info[1] and comma(car_info[1].price) or '--', car_info[1] and car_info[1].car_number or '--', car_info[1] and car_info[1].car_health_min.. ' / ' ..car_info[1].car_health_max or '--', car_info[1] and car_info[1].state.. ' / 100' or '--', car_info[1] and car_info[1].oil or '--', car_info[1] and car_info[1].insurance_damage or '--', car_info[1] and car_info[1].insurance_meeting or '�����������'}
                    for i = 1, 13 do
                        imgui.SetColumnWidth(-1, 170); imgui.CenterColumnText(u8(arrayText[i])); imgui.NextColumn()
                        imgui.SetColumnWidth(-1, 150); imgui.CenterColumnText(u8(tostring(arrayInfo[i]))); imgui.NextColumn()
                        if i ~= 13 then imgui.Separator() end
                    end
                imgui.EndChild()
                imgui.Separator()
                imgui.ColButton(door_state)
                if imgui.Button((door_state and fa.ICON_FA_UNLOCK or fa.ICON_FA_LOCK), imgui.ImVec2(79,20)) then
                    state = 2
                    work = true
                    sampSendChat(command)
                end
                imgui.PopStyleColor(3)
                imgui.Hint(u8('�������, ����� ' .. (door_state and '�������' or '�������') .. ' ����� ������ ������������� ��������.\n\nP.S. ����������� ������ ���� ����� � ����� �/c ��� �������� � ��.'), 0.1)
                imgui.SameLine()
                imgui.ColButton(key_state)
                if imgui.Button((key_state and fa.ICON_FA_KEY or fa.ICON_FA_BAN), imgui.ImVec2(79,20)) and isCharInAnyCar(PLAYER_PED) and (tonumber(servercarid) == tonumber(select(2, sampGetVehicleIdByCarHandle(storeCarCharIsInNoSave(PLAYER_PED))))) then 
                    state = 3
                    work = true
                    sampSendChat(command) 
                end
                imgui.PopStyleColor(3)
                imgui.Hint(u8('�������, ����� ' .. (key_state and '�������� ����� �� �����' or '�������� ���� � �����') .. ' ��������� ������ ������������� ��������.\n\nP.S. ����������� ������ �������� � ����������.'), 0.1)
                imgui.SameLine()
                imgui.ColButton(drive_state)
                if imgui.Button((drive_state and fa.ICON_FA_CAR_SIDE or fa.ICON_FA_SHIPPING_FAST), imgui.ImVec2(79,20)) and isCharInAnyCar(PLAYER_PED) and (tonumber(servercarid) == tonumber(select(2, sampGetVehicleIdByCarHandle(storeCarCharIsInNoSave(PLAYER_PED))))) then
                    state = 8
                    work = true
                    sampSendChat(command) 
                end
                imgui.PopStyleColor(3)
                imgui.Hint(u8('�������� ����� ���� [Sport, Comfort].\n\nP.S. ����������� ������ �������� � ����������.'), 0.1)
                imgui.SameLine()
                imgui.ColButton(abs_state)
                if imgui.Button((abs_state and fa.ICON_FA_CAR_ALT or fa.ICON_FA_CAR_CRASH), imgui.ImVec2(79,20)) and isCharInAnyCar(PLAYER_PED) and (tonumber(servercarid) == tonumber(select(2, sampGetVehicleIdByCarHandle(storeCarCharIsInNoSave(PLAYER_PED))))) then 
                    state = 9
                    work = true
                    sampSendChat(command) 
                end
                imgui.PopStyleColor(3)
                imgui.Hint(u8('�������, ����� ' .. (abs_state and '���������' or '��������') .. ' ������� ABS ������ ������������� ��������.\n\nP.S. ����������� ������ �������� � ����������.'), 0.1)
                imgui.Separator()
                if imgui.Button(u8'������������', imgui.ImVec2(107,20)) and isCharInAnyCar(PLAYER_PED) then 
                    parkingmod = true 
                end
                imgui.Hint(u8'���������� ������ ������ �������� ������ � ������.', 0.1)
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
                imgui.Hint(u8(infotooltip), 0.1)
                imgui.SameLine()
                if imgui.Button(u8'����������', imgui.ImVec2(89,20)) then
                    state = 10
                    work = true
                    sampSendChat(command) 
                end
                imgui.Hint(u8'���� ������������ �������� ������������ �� ����� ��������.\n��������� ������: 1.000$.', 0.1)
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
                    imgui.Hint(u8('����� �� ��� ������, ����� �������� ������ �������� ���������� ��������.\n� ������ ������ �������� ' ..(loads_status and '�����' or '�� �����') .. ' �������� ��� ����� �� ������.'), 0.1)
                end
            elseif not state_spawn and not parkingmod and not reloadmod and not aboutmod and not info_update then
                imgui.SetCursorPosY(180)
                if carid then
                    if not work then
                        imgui.SetCursorPosY(160)
                        if cars[carid].pfine then
                            imgui.CenterTextColoredRGB('��� ��������� {ffff00}' ..carname.. '{ff0000} �� ������������.')
                        else
                            imgui.CenterTextColoredRGB('��� ��������� {ffff00}' ..carname.. '{ffffff} �� ��������.')
                        end
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
            imgui.Hint(u8('�����, ����� ������ ���������� �� ����������.'), 0.1)
            imgui.SameLine()
        end
        imgui.SetCursorPosX(370)
        imgui.TextColoredRGB('{4169E1}S&D Scripts�')
        if imgui.IsItemClicked() then
            aboutmod = true
        end
        imgui.Hint(u8('�������������� ��������� �������.'), 0.1)
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

function colorVehicle(clr_1, clr_2)
    local res, vid = sampGetVehicleIdByCarHandle(veh)
    local vehpool = sampGetVehiclePoolPtr()
    local pool = sampGetVehiclePoolPtr()
    if getStructElement(pool, 0x3074 + vid * 4, 1) == 1 then
        local this = ffi.cast('void*', getStructElement(pool, 0x1134 + vid * 4, 4))
        ffi.cast('void(__thiscall*)(void* this, int c1, int c2)', sampGetBase() + 0xB0D90)(this, tonumber(clr_1), tonumber(clr_2))
    end
end

function getCarTabColor(id)
	local col_table = memory.getuint32(0x4C8390, true)
	local clr = memory.getuint32(col_table + (id * 4))
	return clr
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

function imgui.Hint(text, delay, action)
    if imgui.IsItemHovered() then
        if go_hint == nil then go_hint = os.clock() + (delay and delay or 0.0) end
        local alpha = (os.clock() - go_hint) * 5
        if os.clock() >= go_hint then
            imgui.PushStyleVar(imgui.StyleVar.WindowPadding, imgui.ImVec2(10, 10))
            imgui.PushStyleVar(imgui.StyleVar.Alpha, (alpha <= 1.0 and alpha or 1.0))
                imgui.PushStyleColor(imgui.Col.PopupBg, imgui.ImVec4(0.11, 0.11, 0.11, 1.00))
                    imgui.BeginTooltip()
                    imgui.PushTextWrapPos(450)
                    imgui.TextColored(imgui.GetStyle().Colors[imgui.Col.ButtonHovered], fa.ICON_FA_INFO_CIRCLE .. u8' ���������:')
                    imgui.TextUnformatted(text)
                    if action ~= nil then
                        imgui.TextColored(imgui.GetStyle().Colors[imgui.Col.TextDisabled], '\n'..action)
                    end
                    if not imgui.IsItemVisible() and imgui.GetStyle().Alpha == 1.0 then go_hint = nil end
                    imgui.PopTextWrapPos()
                    imgui.EndTooltip()
                imgui.PopStyleColor()
            imgui.PopStyleVar(2)
        end
    end
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

function distanceBetweenPlayer(playerId)
    if sampIsPlayerConnected(playerId) then
        local result, ped = sampGetCharHandleBySampPlayerId(playerId)
        if result and doesCharExist(ped) then
            local myX, myY, myZ = getCharCoordinates(playerPed)
            local playerX, playerY, playerZ = getCharCoordinates(ped)
            return math.floor(getDistanceBetweenCoords3d(myX, myY, myZ, playerX, playerY, playerZ))
        end
    end
    return nil
end

apply_custom_style()