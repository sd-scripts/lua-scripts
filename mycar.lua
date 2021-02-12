script_author('S&D Scripts')
script_name('MyCar')
script_version('1.1.0')
script_version_number(3)
 
local sampev      =   require 'samp.events'
local imgui       =   require 'imgui'
local encoding    =   require 'encoding'
local keys        =   require 'vkeys'
local inicfg      =   require 'inicfg'

local limadd, imadd 	= pcall(require, 'imgui_addons')
local lrkeys, rkeys 	= pcall(require, 'rkeys')
 
encoding.default = 'CP1251'
u8 = encoding.UTF8
 
local cars = {}
local old_cars = {}
local car_info = {}
local settings = {}
local target = {i={},state=false}

local main_window = imgui.ImBool(false)
local target_window = imgui.ImBool(false)
local check_old = false
local unloading_cars = false
local work = false
local state = 0
local bindID = 0
local sellsum = imgui.ImBuffer(150)

local cfg = inicfg.load({
    CheckBox = {
		fixmycar = false,
        enter = true,
        unloading = false,
        save = true
    },
    HotKey = {
        lock1 = 76,
        lock2 = nil,
        keys1 = 75,
        keys2 = nil,
        main1 = 18,
        main2 = 77,
        interaction1 = 88,
        interaction2 = nil
    }
}, 'MyCar')

local CheckBox = {
	['fixmycar'] = imgui.ImBool(cfg.CheckBox.fixmycar),
    ['enter'] = imgui.ImBool(cfg.CheckBox.enter),
    ['unloading'] = imgui.ImBool(cfg.CheckBox.unloading),
    ['save'] = imgui.ImBool(cfg.CheckBox.save)
}

local ActiveMenu = {
	v = {cfg.HotKey.main1, cfg.HotKey.main2}
}
local ActiveKey = {
	v = {cfg.HotKey.keys1, cfg.HotKey.keys2}
}
local ActiveLock = {
	v = {cfg.HotKey.lock1, cfg.HotKey.lock2}
}
local ActiveInteraction = {
	v = {cfg.HotKey.interaction1}
}
local tLastKeys = {

}

function settings.load(table, dir)
    if not doesFileExist(dir) then
        local f = io.open(dir, 'w+'); local suc = f:write(encodeJson(table)); f:close()
        if suc then return table end
        return table
    else
        local f = io.open(dir, 'r+'); local array = decodeJson(f:read('a*')); f:close()
        if not array then return table end
        return array
    end
end

function settings.save(table, dir)
    local f = io.open(dir, 'w+'); local suc = f:write(encodeJson(table));
    f:close()
    return table
end

function sampev.onShowDialog(id, style, title, b1,b2,text)
    --sampAddChatMessage('DIALOGID: ' ..id, -1)
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
                    name = v:match('%{FFFFFF%} (.+)%('),
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
        
        command = '/keys'; id_dialog = 1162; cars_info = 'Чужой транспорт'
        main_window.v = true
        sampSendDialogResponse(id, 0, nil, nil)
        return false
    end
    if id == 1163 then
        if title:find('{BFBBBA}Инструменты для .+ %(%d+%)') then
            if work then 
                work = false
            else
                local l = 0
                for v in string.gmatch(text, '[^\n]+') do
                    if l == 0 then --закрыть/открыть
                        if v:match('%{......%}Закрыть') then door_state = true else door_state = false end
                    end
                    if l == 1 then --ключи
                        if v:match('%{......%}Вставить ключи') then key_state = false else key_state = true end
                    end
                    if l == 7 then --режим езды
                        if v:match('%{......%}Режим езды %[ %{......%}Sport%{......%} %]') then drive_state = false else drive_state = true end
                    end
                    if l == 8 then --ABS
                        if v:match('Система ABS  %[ %{......%}ВКЛ%{......%} %]') then abs_state = true else abs_state = false end
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
            if v:match('%[Не загружено%]') then
                t = {
                    name = v:match('%{F05959%}%[Не загружено%]%{FFFFFF%} (%w+)'),
                    id = i,
                    spawn = false
                }
            elseif v:match('%{FFFFFF%} %w+') then
                t = {
                    name = v:match('%{FFFFFF%} (.+)%('),
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
        if check_old then
            list = {}
            for k, v in pairs(cars) do 
                list[v.name .. v.id] = v.spawn
            end
            
            for k, v in pairs(old_cars) do -- выгрузка авто
                if list[v.name .. v.id] ~= v.spawn then
                    if not v.spawn then
                        work = true
                        sampSendDialogResponse(162, 1, v.id, -1)
                    end
                end
            end

            for k, v in pairs(old_cars) do -- загрузка авто
                if list[v.name .. v.id] ~= v.spawn then
                    sampSendDialogResponse(162, 1, v.id, -1)
                    if v.spawn then work = true end
                end
            end
            
            if not work then
                check_old = false
            end
        elseif unloading_cars then
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
            settings.save(cars, getWorkingDirectory().. '\\config\\mycar.json')
            command = '/cars'; id_dialog = 162; cars_info = 'Мой транспорт'
            if not target_window.v then main_window.v = true end
        end

        sampSendDialogResponse(id, 0, nil, nil)
        return false
 
    end
    if id == 163 then
        if title:find('{BFBBBA}Инструменты для .+ %(%d+%)') then

            if work then 
                work = false
                if check_old or unloading_cars then
                    sampSendDialogResponse(163, 1, 10, 1)
                end
                if not state_spawn then
                    carid = nil
                end
            else

                local l = 0
                for v in string.gmatch(text, '[^\n]+') do
                    if l == 0 then --закрыть/открыть
                        if v:match('%{......%}Закрыть') then door_state = true else door_state = false end
                    end
                    if l == 1 then --ключи
                        if v:match('%{......%}Вставить ключи') then key_state = false else key_state = true end
                    end
                    if l == 7 then --режим езды
                        if v:match('%{......%}Режим езды %[ %{......%}Sport%{......%} %]') then drive_state = false else drive_state = true end
                    end
                    if l == 8 then --ABS
                        if v:match('Система ABS  %[ %{......%}ВКЛ%{......%} %]') then abs_state = true else abs_state = false end
                    end
                    l = l + 1
                end

                sampSendDialogResponse(163, 1, 5, -1)
            end
 
            if state == 1 then
                sampSendDialogResponse(163, 1, 10, -1)
                state = 0
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
                work = true
                carid = recarid
            end
 
        else
            if work then
                sampSendDialogResponse(163, 1, 0, -1)
                if check_old then
                    work = false 
                end
            else
                sampSendDialogResponse(163, 0, nil, nil)
            end
        end

        return false
    end
    if id == 6971 and style == 2 then
        sampSendDialogResponse(id, 1, parkingstate, -1)
        parkingstate = nil
        return false
    end
    if id == 0 and style == 0 and title == '{BFBBBA}Информация' and (main_window.v or target_window.v) then
        car_info = {}
        local t = {
            carname = text:match('%{FFFFFF%}Транспорт%: %{73B461%}(.+)%{FFFFFF%}.+Владелец'),  
            owner = text:match('Владелец: {......}(%w+_%w+){......}'),
            intermediary = text:match('Посредник%: %{73B461%}(%D+)%{FFFFFF%}'),
            mileage = text:match('Пробег%: %{73B461%}(%d+ км.)%{FFFFFF%}'),
            tax = text:match('Налог%: %{73B461%}(%d+)%{FFFFFF%} %/ 150 000'),
            fine = text:match('Штраф%: %{73B461%}(%d+)%{FFFFFF%} %/ 80 000'),
            recovery_penalty = text:match('Штраф за восстановление%: %{73B461%}($%d+)%{FFFFFF%}'),
            price = text:match('Цена покупки с госа%:%s%{......%}($.+%d+).+Номер'),
            car_number = text:match('Номер автомобиля%:.+{......}(.+){......}.+Здоровье'),
            car_health_min = text:match('Здоровье автомобиля%: %{F57449%}(%d+.%d)/%d+.%d%{FFFFFF%}'),
            car_health_max = text:match('Здоровье автомобиля%: %{F57449%}%d+.%d/(%d+.%d)%{FFFFFF%}'),
            state = text:match('Состояние авто%: %{F57449%}(%d+)/100%{FFFFFF%}'),
            oil = text:match('Состояния масла%: %{F57449%}%{......%}(%X+)%{FFFFFF%}'),
            insurance_damage = text:match('Страховка %(на повреждение%)%: %{......%}(%X+)%{FFFFFF%}'),
            insurance_meeting = text:match('Страховка %(на слёт%)%: %{......%}.+(до [%d%:%s%.]+).+%{FFFFFF%}'),
        }
        table.insert(car_info, t)
        servercarid = car_info[1].carname:match('%w+%[(%d+)%]')
        sampSendDialogResponse(id, 0, nil, nil)
        return false
    end
end

function sampev.onDisplayGameText(style, time, text)
    if style == 3 then
        if text:match('CAR%~[gr]%~ (%u+)%~n%~%/lock') then door_state = not door_state end
        if text:match('Style%:.+%~(%w+)%!') then drive_state = not drive_state end
        if text:match('ABS%: .+%~(%u+)%!') then abs_state = not abs_state end
    end
end
 
function sampev.onServerMessage(color,text)
    if text:find('вытащил%(а%) ключи из замка зажигания') or text:find('вставил%(а%) ключи в замок зажигания') then key_state = not key_state end
    if text:find('Загрузить транспорт не удалось') and work then return false end
	if text:find('%[Ошибка%] %{FFFFFF%}В данном гараже уже припарковано 1 %/ 1, а это авто сейчас находится в гараже.') then
		if check_old or unloading_cars then check_old = false; unloading_cars = false; work = false return false end
	end
	if text:find('Ключи не вставлены') and CheckBox['enter'].v then
        sampSendChat('/key'); sampSendChat('/engine') 
        return false 
    end
    if text:find('Нельзя загружать более двух авто одновременно, сначало выгрузите одно авто') and work then
        work = false
        reloadmod = true
        return false
    end

    if text:find('смотрит тех. паспорт.') then return false end
end
 
function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end
    while not sampIsLocalPlayerSpawned() do wait(120) end

    local update_file = getWorkingDirectory() .. '\\mycar.json';
    downloadUrlToFile('https://raw.githubusercontent.com/sd-scripts/lua-scripts/main/mycar.json', getWorkingDirectory()..'\\mycar.json', function(id, status, p1, p2)
        if status == 6 then
            local f = io.open(update_file, 'a+'); 
            data = decodeJson(f:read('a*'));
            f:close();
            os.remove(update_file)
        end
    end)

    if not doesFileExist('moonloader/config/MyCar.ini') then
        if inicfg.save(cfg, 'MyCar.ini') then sampfuncsLog('[MyCar] Создан файл конфигурации: MyCar.ini') end
    end

    old_cars = settings.load({}, getWorkingDirectory().. '\\config\\mycar.json')

    if cfg.CheckBox.save and #old_cars > 0 then
        check_old = true; sampSendChat('/cars')
    end

    if cfg.CheckBox.unloading then
        unloading_cars = true; sampSendChat('/cars')
    end

    if lrkeys then
        bindMenu = rkeys.registerHotKey(ActiveMenu.v, true, function ()
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
    end

    while true do
        target.check()
		if (isKeyJustPressed(keys.VK_F) or isKeyJustPressed(keys.VK_RETURN)) and CheckBox['enter'].v then
            if isCharInAnyCar(playerPed) then           
                if isCharInAnyCar(playerPed) and not isSampfuncsConsoleActive() and not sampIsChatInputActive() and not sampIsDialogActive() and (string.format('%4.2f', getCarSpeed(storeCarCharIsInNoSave(playerPed))) < '30') then    
                    sampSendChat('/key')	
                end 
            end
        end
        if isKeyJustPressed(cfg.HotKey.interaction1) and target.state then target_window.v = true; sampSendChat('/cars') end
        wait(0)
        imgui.Process = main_window.v or target_window.v
        if not main_window.v then state_spawn = false; carid = nil end
    end
end

function target.check()

    local result, ped = getCharPlayerIsTargeting(player)
    if result and not target.state then 
        local _, pID = sampGetPlayerIdByCharHandle(ped)
        local x, y, z = getCharCoordinates(ped)
        if pID >= 0 and pID <= 1000 then
            target.i.id, target.i.name, target.i.lvl = pID, sampGetPlayerNickname(pID), sampGetPlayerScore(pID)
            target.state = true;
            target.time = os.clock() + 2
        end
    end
    
    if target.state then 
        if target.state and not target_window.v then
            if target.time <= os.clock() then 
                target.state = false;
                target.i = {}
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
 
function imgui.OnDrawFrame()
    if target_window.v then
        local sw, sh = getScreenResolution()
        imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(190, 228))
        imgui.Begin('##targetwindow',  target_window, imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoMove)
        if not choose_act then
            local uf = 0
            imgui.SetCursorPosY(60)
            for i, v in ipairs(cars) do
                if v.spawn then
                    uf = uf + 1
                    if imgui.Button(v.name .. '##' .. i, imgui.ImVec2(175,25)) then choose_car = v.name; sampSendChat('/cars'); sampSendDialogResponse(162, 1, v.id, -1); choose_act = true end
                end
            end
            imgui.SetCursorPosY(10)
            imgui.CenterTextColoredRGB('{808080}Меню взаимодействия')
            imgui.Separator()
            imgui.CenterTextColoredRGB('{FFD848}' ..target.i.name.. '[' ..target.i.id.. ']')
            if uf == 0 then
                imgui.SetCursorPosY(105)
                imgui.CenterTextColoredRGB('{808080}У вас нет загруженных т/с')
                imgui.SetCursorPosY(175)
                if imgui.Button(u8'Загрузить', imgui.ImVec2(175,20)) then target_window.v = false; sampSendChat('/cars') end        
            end
        else
            imgui.SetCursorPosY(10)
            imgui.CenterTextColoredRGB('{808080}Меню взаимодействия')
            imgui.Separator()
            imgui.CenterTextColoredRGB('{FFD848}' ..target.i.name.. '[' ..target.i.id.. ']')
            imgui.SetCursorPosY(60)
            if imgui.Button(u8'Передать ключи', imgui.ImVec2(175,25)) then sampSendChat('/givekey ' ..target.i.id.. ' ' ..servercarid); choose_car = ''; target_window.v = false; choose_act = false end
            if imgui.Button(u8'Показать паспорт', imgui.ImVec2(175,25)) then sampSendChat('/carpass ' ..target.i.id.. ' ' ..servercarid); choose_car = ''; target_window.v = false; choose_act = false end
            imgui.SetCursorPosY(157)
            imgui.CenterTextColoredRGB('{808080}Выбранное т/c: {73B461}' ..choose_car)
            imgui.ColorButton(64, 105, 15, 52, 84, 12, 77, 125, 17)
            if imgui.Button(u8'Назад', imgui.ImVec2(175,20)) then choose_act = false; choose_car = '' end
            imgui.PopStyleColor(3)
        end
        imgui.SetCursorPosY(200)
		imgui.ColorButton(112, 112, 112, 99, 99, 99, 130, 130, 130)
        if imgui.Button(u8'Закрыть', imgui.ImVec2(175,20)) then target_window.v = false; choose_act = false; choose_car = '' end
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
        imgui.SetNextWindowSize(imgui.ImVec2(515, 465))
        imgui.Begin(u8('MyCar | ' ..cars_info),  main_window, imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoCollapse)
        imgui.BeginChild('##panel_1', imgui.ImVec2(145, 410), true)
            imgui.CenterText('Список авто:')
            for i, v in ipairs(cars) do
                if not aboutmod and not info_update then
                    imgui.ColButton(cars[i]['spawn'])
                    if imgui.Button(v['name'] .. '##' .. i, imgui.ImVec2(130,20)) and not work then 
                        carname = v['name']; car_info = {}; carid = i; sampSendChat(command); sampSendDialogResponse(id_dialog, 1, cars[carid]['id'], -1); state_spawn = cars[carid]['spawn']
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
        
        imgui.BeginChild('##panel_2', imgui.ImVec2(347, 410), true)
            if info_update then
                aboutmod = false
                imgui.CenterTextColoredRGB('{4169E1}Доступно новое обновление v' ..data.name.. '.'); imgui.Separator()
                imgui.CenterTextColoredRGB('{73B461}Полный список изменений:')
                imgui.BeginChild('##update', imgui.ImVec2(330, 335), true)
                    local text = data.info
                    if text then
                        for line in text:gmatch('[^\r\n]+') do
                            imgui.Text(line)
                        end
                    else
                        imgui.SetCursorPosY(160)
                        imgui.CenterTextColoredRGB('{DCDCDC}Не удалось загрузить информацию об обновлении.')
                    end
                imgui.EndChild()
				imgui.ColorButton(35, 84, 25, 30, 70, 20, 48, 115, 34)
                if imgui.Button(u8'Скачать', imgui.ImVec2(163,20)) then os.execute('explorer "https://www.blast.hk/threads/76299/"') end
                imgui.PopStyleColor(3)
                if imgui.IsItemHovered() then imgui.BeginTooltip() imgui.TextUnformatted(u8('Нажав на кнопку, у вас откроется ссылка в браузере, где вы сможете скачать скрипт.')) imgui.EndTooltip() end
                imgui.SameLine()
                if imgui.Button(u8'Назад', imgui.ImVec2(163, 20)) then info_update = false end
            end
            if aboutmod then
                info_update = false
                imgui.CenterTextColoredRGB('{6495ED}Дополнительные функции'); imgui.Separator()
                if imgui.Checkbox(u8'Автоматически доставать ключи при выходе из т/c', CheckBox['enter']) then cfg.CheckBox.enter = CheckBox['enter'].v; inicfg.save(cfg, 'MyCar.ini') end
                if imgui.IsItemHovered() then imgui.BeginTooltip() imgui.TextUnformatted(u8('Скрипт за вас будет доставать ключи при выходе из транспортного средства,\nа также их вставлять при попытке завести двигатель.')) imgui.EndTooltip() end
                if imgui.Checkbox(u8'Выгружать весь транспорт при подключении', CheckBox['unloading']) then
                    if CheckBox['unloading'].v then cfg.CheckBox.save = false; CheckBox['save'].v = false end
                    cfg.CheckBox.unloading = CheckBox['unloading'].v
                    inicfg.save(cfg, 'MyCar.ini') 
                end
                if imgui.IsItemHovered() then imgui.BeginTooltip() imgui.TextUnformatted(u8('При входе в игру скрипт выгрузит все ваши транспортные средства с сервера.')) imgui.EndTooltip() end
                if imgui.Checkbox(u8'Сохранять статус загрузки/выгрузки транспорта', CheckBox['save']) then 
                    if CheckBox['save'].v then cfg.CheckBox.unloading = false; CheckBox['unloading'].v = false end
                    cfg.CheckBox.save = CheckBox['save'].v 
                    inicfg.save(cfg, 'MyCar.ini')
                end
                if imgui.IsItemHovered() then imgui.BeginTooltip() imgui.TextUnformatted(u8('Скрипт будет запоминать, какие у вас транспортные средства были загружены,\nа при заходе в игру вернёт статус, как это было в последний раз.')) imgui.EndTooltip() end
				if imgui.Checkbox(u8'Использовать команду "/fixmycar" перед спавном', CheckBox['fixmycar']) then cfg.CheckBox.fixmycar = CheckBox['fixmycar'].v; inicfg.save(cfg, 'MyCar.ini') end
				if imgui.IsItemHovered() then imgui.BeginTooltip() imgui.TextUnformatted(u8('При нажатии на кнопку "Заспавнить" будет перед спавном прописываться команда "/fixmycar [id транспорта]".\nИСПОЛЬЗОВАТЬ НА СВОЙ СТРАХ И РИСК.')) imgui.EndTooltip() end
				
                imgui.NewLine(); imgui.CenterTextColoredRGB('{73B461}Горячие клавиши'); imgui.Separator()
                if imadd.HotKey("##menu", ActiveMenu, tLastKeys, 80) then
                    rkeys.changeHotKey(bindMenu, ActiveMenu.v)
					cfg.HotKey.main1 = ActiveMenu.v[1]
                    cfg.HotKey.main2 = ActiveMenu.v[2]
					inicfg.save(cfg, 'MyCar.ini')
                end
                imgui.SameLine(); imgui.Text(u8' -   открыть меню скрипта (/cars)')
                if imadd.HotKey("##lock", ActiveLock, tLastKeys, 80) then
                    rkeys.changeHotKey(bindLock, ActiveLock.v)
					cfg.HotKey.lock1 = ActiveLock.v[1]
                    cfg.HotKey.lock2 = ActiveLock.v[2]
					inicfg.save(cfg, 'MyCar.ini')
                end
                imgui.SameLine(); imgui.Text(u8' -   открыть/закрыть транспорт (/lock)')
                if imadd.HotKey("##key", ActiveKey, tLastKeys, 80) then
                    rkeys.changeHotKey(bindKey, ActiveKey.v)
					cfg.HotKey.keys1 = ActiveKey.v[1]
                    cfg.HotKey.keys2 = ActiveKey.v[2]
					inicfg.save(cfg, 'MyCar.ini')
				end
                imgui.SameLine(); imgui.Text(u8' -   вставить/достать ключи (/key)')
                if imadd.HotKey("##interaction", ActiveInteraction, tLastKeys, 80) then
                    rkeys.changeHotKey(bindInteraction, ActiveInteraction.v)
					cfg.HotKey.interaction1 = ActiveInteraction.v[1]
                    cfg.HotKey.interaction2 = ActiveInteraction.v[2]
                    inicfg.save(cfg, 'MyCar.ini')
				end
                imgui.SameLine(); imgui.Text(u8' -   меню взаимодействия')
                if imgui.IsItemHovered() then imgui.BeginTooltip() imgui.TextUnformatted(u8('Необходимо будет выделить игрока нажатием ПКМ.')) imgui.EndTooltip() end
				
				imgui.SetCursorPosY(315)
                imgui.NewLine(); imgui.CenterTextColoredRGB('{A9A9A9}Обратная связь:'); imgui.Separator()
				imgui.ColorButton(11, 88, 230, 10, 80, 209, 12, 94, 245)
                if imgui.Button(u8'ВКонтакте', imgui.ImVec2(107,20)) then os.execute('explorer "https://vk.com/sd_scripts"') end
                imgui.PopStyleColor(3)
                if imgui.IsItemHovered() then imgui.BeginTooltip() imgui.TextUnformatted(u8('Нажав на кнопку, у вас откроется ссылка в браузере нашей группы ВКонтакте.')) imgui.EndTooltip() end
                imgui.SameLine()
                
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.19, 0.22, 0.26, 1.0))
                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.15, 0.18, 0.22, 1.0))
                imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.11, 0.14, 0.18, 1.0))
                if imgui.Button('BlastHack', imgui.ImVec2(107,20)) then os.execute('explorer "https://www.blast.hk/threads/76299/"') end
                imgui.PopStyleColor(3)
                if imgui.IsItemHovered() then imgui.BeginTooltip() imgui.TextUnformatted(u8('Нажав на кнопку, у вас откроется ссылка в браузере темы на портале BlastHack.')) imgui.EndTooltip() end
				imgui.SameLine()
				imgui.ColorButton(35, 84, 25, 30, 70, 20, 48, 115, 34)
				if imgui.Button(u8'Техподдержка', imgui.ImVec2(107,20)) then os.execute('explorer "https://vk.me/sd_scripts"') end
				imgui.PopStyleColor(3)
				if imgui.IsItemHovered() then imgui.BeginTooltip() imgui.TextUnformatted(u8('Нажав на кнопку, вы попадёте в техподдержку (личные сообщения нашей группы ВКонтакте).')) imgui.EndTooltip() end
				imgui.Separator()
				
                imgui.SetCursorPosY(385)
				imgui.ColorButton(120, 34, 34, 107, 30, 30, 135, 38, 38)
                if imgui.Button(u8'Выключить скрипт', imgui.ImVec2(165,20)) then thisScript():unload() end
				imgui.PopStyleColor(3)
                if imgui.IsItemHovered() then imgui.BeginTooltip() imgui.TextUnformatted(u8('Выключает скрипт до перезагрузки (CTRL+R) или перезахода в игру.')) imgui.EndTooltip() end
                imgui.SameLine()
                if imgui.Button(u8'Закрыть', imgui.ImVec2(165,20)) then aboutmod = false end
            end
            if reloadmod then
                imgui.SetCursorPosY(135)
                imgui.CenterTextColoredRGB('{808080}Вы можете иметь лишь два загруженных т/c.')
                imgui.CenterTextColoredRGB('{808080}Выберите, какой транспорт выгрузить взамен:')
                for i, v in ipairs(cars) do
                    if cars[i]['spawn'] then
                        if imgui.Button(v['name'], imgui.ImVec2(335,25)) then
                            recarid = carid; carid = i; state_spawn = false; work = true; state = 11; reloadmod = false; sampSendChat('/cars')
                        end
                    end
                end
                imgui.SetCursorPosX(223)
                imgui.ColorButton(112, 112, 112, 99, 99, 99, 130, 130, 130)
                if imgui.Button(u8'Назад', imgui.ImVec2(120, 20)) then reloadmod = false end
                imgui.PopStyleColor(3)
            end
            if parkingmod then
                imgui.SetCursorPosY(160)
				imgui.CenterTextColoredRGB('{808080}Выберите, где припарковать ваш транспорт.')
                if imgui.Button(u8'Припарковать в этом месте', imgui.ImVec2(335,25)) then
                    parkingmod = false
                    parkingstate = 0
                    state = 4
                    work = true
                    sampSendChat(command)
                end
                if imgui.Button(u8'Вернуть на стандартную парковку', imgui.ImVec2(335,25)) then
                    parkingmod = false
                    parkingstate = 1
                    state = 4
                    work = true
                    sampSendChat(command)
                end
                imgui.SetCursorPosX(223)
				imgui.ColorButton(112, 112, 112, 99, 99, 99, 130, 130, 130)
                if imgui.Button(u8'Назад', imgui.ImVec2(120, 20)) then parkingmod = false end
                imgui.PopStyleColor(3)
            end
            if state_spawn and not parkingmod and not reloadmod and not aboutmod and not info_update then
                imgui.BeginChild('##columns', imgui.ImVec2(330, 315), true)
                    imgui.CenterTextColoredRGB('Паспорт транспорта {C0C0C0}' ..tostring(car_info[1] and car_info[1].carname or ''))  
                    imgui.Separator()
                    imgui.Columns(2)
                    imgui.SetColumnWidth(-1, 170); imgui.CenterColumnText(u8'Владелец'); imgui.NextColumn()
                    imgui.SetColumnWidth(-1, 150); imgui.CenterColumnText(tostring(car_info[1] and car_info[1].owner or '--')); imgui.NextColumn()
                    imgui.Separator()
                    imgui.SetColumnWidth(-1, 170); imgui.CenterColumnText(u8'Посредник'); imgui.NextColumn()
                    imgui.SetColumnWidth(-1, 150); imgui.CenterColumnText(tostring(car_info[1] and car_info[1].intermediary or '--')); imgui.NextColumn()
                    imgui.Separator()
                    imgui.SetColumnWidth(-1, 170); imgui.CenterColumnText(u8'Пробег'); imgui.NextColumn()
                    imgui.SetColumnWidth(-1, 150); imgui.CenterColumnText(u8(tostring(car_info[1] and car_info[1].mileage or '--'))); imgui.NextColumn()
                    imgui.Separator()
                    imgui.SetColumnWidth(-1, 170); imgui.CenterColumnText(u8'Налог'); imgui.NextColumn()
                    imgui.SetColumnWidth(-1, 150); imgui.CenterColumnText(u8(tostring(car_info[1] and car_info[1].tax.. ' из 150000' or '--'))); imgui.NextColumn()
                    imgui.Separator()
                    imgui.SetColumnWidth(-1, 170); imgui.CenterColumnText(u8'Штраф'); imgui.NextColumn()
                    imgui.SetColumnWidth(-1, 150); imgui.CenterColumnText(u8(tostring(car_info[1] and car_info[1].fine.. ' из 80000' or '--'))); imgui.NextColumn()
                    imgui.Separator()
                    imgui.SetColumnWidth(-1, 170); imgui.CenterColumnText(u8'Штраф за восстановление'); imgui.NextColumn()
                    imgui.SetColumnWidth(-1, 150); imgui.CenterColumnText(tostring(car_info[1] and car_info[1].recovery_penalty or '--')); imgui.NextColumn()
                    imgui.Separator()
                    imgui.SetColumnWidth(-1, 170); imgui.CenterColumnText(u8'Государственная стоимость'); imgui.NextColumn()
                    imgui.SetColumnWidth(-1, 150); imgui.CenterColumnText(tostring(car_info[1] and car_info[1].price or '--')); imgui.NextColumn()
                    imgui.Separator()
                    imgui.SetColumnWidth(-1, 170); imgui.CenterColumnText(u8'Государственный номер'); imgui.NextColumn()
                    imgui.SetColumnWidth(-1, 150); imgui.CenterColumnText(u8(tostring(car_info[1] and car_info[1].car_number or '--'))); imgui.NextColumn()
                    imgui.Separator()
                    imgui.SetColumnWidth(-1, 170); imgui.CenterColumnText(u8'Здоровье'); imgui.NextColumn()
                    imgui.SetColumnWidth(-1, 150); imgui.CenterColumnText(tostring(car_info[1] and car_info[1].car_health_min.. ' / ' ..car_info[1].car_health_max or '--')); imgui.NextColumn()
                    imgui.Separator()
                    imgui.SetColumnWidth(-1, 170); imgui.CenterColumnText(u8'Техническое состояние'); imgui.NextColumn()
                    imgui.SetColumnWidth(-1, 150); imgui.CenterColumnText(tostring(car_info[1] and car_info[1].state.. ' / 100' or '--')); imgui.NextColumn()
                    imgui.Separator()
                    imgui.SetColumnWidth(-1, 170); imgui.CenterColumnText(u8'Состояние масла'); imgui.NextColumn()
                    imgui.SetColumnWidth(-1, 150); imgui.CenterColumnText(u8(tostring(car_info[1] and car_info[1].oil or '--'))); imgui.NextColumn()
                    imgui.Separator()
                    imgui.SetColumnWidth(-1, 170); imgui.CenterColumnText(u8'Страховка (на повреждение)'); imgui.NextColumn()
                    imgui.SetColumnWidth(-1, 150); imgui.CenterColumnText(u8(tostring(car_info[1] and car_info[1].insurance_damage or '--'))); imgui.NextColumn()
                    imgui.Separator()
                    imgui.SetColumnWidth(-1, 170); imgui.CenterColumnText(u8'Страховка (на слёт)'); imgui.NextColumn()
                    imgui.SetColumnWidth(-1, 150); imgui.CenterColumnText(u8(tostring(car_info[1] and car_info[1].insurance_meeting or 'отсутствует')))
                imgui.EndChild()
                imgui.Separator()
                imgui.ColButton(door_state)
                if imgui.Button(u8'DOOR', imgui.ImVec2(79,20)) then
                    state = 2
                    work = true
                    sampSendChat(command)
                end
                imgui.PopStyleColor(3)
                if imgui.IsItemHovered() then imgui.BeginTooltip() imgui.TextUnformatted(u8('Нажмите, чтобы ' .. (door_state and 'закрыть' or 'открыть') .. ' двери вашего транспортного средства.\n\nP.S. Используйте только стоя рядом с вашим т/c или находясь в нём.')) imgui.EndTooltip() end 
                imgui.SameLine()
                imgui.ColButton(key_state)
                if imgui.Button(u8'KEY', imgui.ImVec2(79,20)) and isCharInAnyCar(PLAYER_PED) and (tonumber(servercarid) == tonumber(select(2, sampGetVehicleIdByCarHandle(storeCarCharIsInNoSave(PLAYER_PED))))) then 
                    state = 3
                    work = true
                    sampSendChat(command) 
                end
                imgui.PopStyleColor(3)
                if imgui.IsItemHovered() then imgui.BeginTooltip() imgui.TextUnformatted(u8('Нажмите, чтобы ' .. (key_state and 'вытащить ключи из замка' or 'вставить ключ в замок') .. ' зажигания вашего транспортного средства.\n\nP.S. Используйте только находясь в транспорте.')) imgui.EndTooltip() end
                imgui.SameLine()
                imgui.ColButton(drive_state)
                if imgui.Button((drive_state and 'Comfort' or 'Sport'), imgui.ImVec2(79,20)) and isCharInAnyCar(PLAYER_PED) and (tonumber(servercarid) == tonumber(select(2, sampGetVehicleIdByCarHandle(storeCarCharIsInNoSave(PLAYER_PED))))) then
                    state = 8
                    work = true
                    sampSendChat(command) 
                end
                imgui.PopStyleColor(3)
                if imgui.IsItemHovered() then imgui.BeginTooltip() imgui.TextUnformatted(u8('Изменить режим езды [Sport, Comfort].\n\nP.S. Используйте только находясь в транспорте.')) imgui.EndTooltip() end
                imgui.SameLine()
                imgui.ColButton(abs_state)
                if imgui.Button(u8'ABS', imgui.ImVec2(79,20)) then 
                    state = 9
                    work = true
                    sampSendChat(command) 
                end
                imgui.PopStyleColor(3)
                if imgui.IsItemHovered() then imgui.BeginTooltip() imgui.TextUnformatted(u8('Нажмите, чтобы ' .. (abs_state and 'выключить' or 'включить') .. ' систему ABS вашего транспортного средства.\n\nP.S. Используйте только находясь в транспорте.')) imgui.EndTooltip() end
                imgui.Separator()
                if imgui.Button(u8'Припарковать', imgui.ImVec2(107,20)) then 
                    parkingmod = true 
                end
                imgui.SameLine()
                if imgui.Button(u8'Найти', imgui.ImVec2(107,20)) then 
                    state = 5
                    work = true
                    sampSendChat(command) 
                end
                imgui.SameLine()
                if imgui.Button(u8'Сигнализация', imgui.ImVec2(107,20)) then 
                    state = 6
                    work = true
                    sampSendChat(command) 
                end

                if command == '/cars' then 
                    button_key = 'Очистить посредников'; infotooltip = 'Забрать ключи у человека, которому вы их давали.'
                elseif command == '/keys' then 
                    button_key = 'Вернуть ключи'; infotooltip = 'Вернуть ключи владельцу.'
                end
                if imgui.Button(u8(button_key), imgui.ImVec2(143,20)) then 
                    state = 7
                    work = true
                    sampSendChat(command) 
                end
                if imgui.IsItemHovered() then imgui.BeginTooltip() imgui.TextUnformatted(u8(infotooltip)) imgui.EndTooltip() end
                imgui.SameLine()
                if imgui.Button(u8'Заспавнить', imgui.ImVec2(89,20)) then
					if CheckBox['fixmycar'].v then sampSendChat('/fixmycar ' ..servercarid) end
                    state = 10
                    work = true
                    sampSendChat(command) 
                end
                if imgui.IsItemHovered() then imgui.BeginTooltip() imgui.TextUnformatted(u8('Ваше транспортное средство переместится на место парковки.\nСтоимость услуги: 1.000$.')) imgui.EndTooltip() end
                imgui.SameLine()
                if command == '/cars' then
                    if imgui.Button(u8'Выгрузить', imgui.ImVec2(89,20)) then
                        state_spawn = false
                        state = 1
                        work = true
                        sampSendChat('/cars')
                    end
                end
            elseif not state_spawn and not parkingmod and not reloadmod and not aboutmod and not info_update then
                imgui.SetCursorPosY(180)
                if carid then
                    if not work then
                        imgui.CenterTextColoredRGB('Ваш транспорт {ffff00}' ..carname.. '{ffffff} не загружен.')
                        if imgui.Button(u8'Загрузить', imgui.ImVec2(335,30)) then
                            work = true
                            sampSendChat('/cars')
                        end
                    else
                        imgui.SetCursorPosY(150)
                        imgui.SetCursorPosX(165)
                        Spinner('##spinner', 12, 3, imgui.GetColorU32(imgui.GetStyle().Colors[imgui.Col.ButtonHovered]))
                        imgui.CenterTextColoredRGB('Подождите. Идёт загрузка транспорта {ffff00}' ..carname.. '{ffffff}.')
                        if imgui.Button(u8'Стоп', imgui.ImVec2(335,30)) then
                            work = false   
                        end
                    end
                else
                    imgui.CenterText('Выберите транспорт из списка слева.')
                end
            end
        imgui.EndChild()
        if data.version ~= thisScript().version_num then 
            imgui.TextColoredRGB('{808080}  Доступно обновление!')
            if imgui.IsItemClicked() then
                info_update = true
            end
            if imgui.IsItemHovered() then imgui.BeginTooltip() imgui.TextUnformatted(u8('Нажми, чтобы узнать информацию об обновлении.')) imgui.EndTooltip() end
            imgui.SameLine()
        end
        imgui.SetCursorPosX(345)
        imgui.TextColoredRGB('{4169E1}S&D Scripts™')
        if imgui.IsItemClicked() then
            aboutmod = true
        end
        if imgui.IsItemHovered() then imgui.BeginTooltip() imgui.TextUnformatted(u8('Дополнительные настройки скрипта.')) imgui.EndTooltip() end
        imgui.SameLine()
        imgui.TextColoredRGB(' {ffffff}Version: {808080}' ..thisScript().version)
        imgui.End()
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
 
function Spinner(label, radius, thickness, color)
    local style = imgui.GetStyle()
    local pos = imgui.GetCursorScreenPos()
    local size = imgui.ImVec2(radius * 2, (radius + style.FramePadding.y) * 2)
 
    imgui.Dummy(imgui.ImVec2(size.x + style.ItemSpacing.x, size.y))
 
    local DrawList = imgui.GetWindowDrawList()
    DrawList:PathClear()
 
    local num_segments = 30
    local start = math.abs(math.sin(imgui.GetTime() * 1.8) * (num_segments - 5))
 
    local a_min = 3.14 * 2.0 * start / num_segments
    local a_max = 3.14 * 2.0 * (num_segments - 3) / num_segments
 
    local centre = imgui.ImVec2(pos.x + radius, pos.y + radius + style.FramePadding.y)
 
    for i = 0, num_segments do
        local a = a_min + (i / num_segments) * (a_max - a_min)
        DrawList:PathLineTo(imgui.ImVec2(centre.x + math.cos(a + imgui.GetTime() * 8) * radius, centre.y + math.sin(a + imgui.GetTime() * 8) * radius))
    end
 
    DrawList:PathStroke(color, false, thickness)
    return true
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
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImColor(35, 84, 25, 255):GetVec4()) -- изначальный цвет RGBA
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImColor(30, 70, 20, 255):GetVec4()) -- цвет при наведении на кнопку (темнее)
        imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImColor(48, 115, 34, 255):GetVec4()) -- цвет при нажатии на кнопку (светлее)
    else --redButton
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImColor(120, 34, 34, 255):GetVec4()) -- изначальный цвет RGBA
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImColor(107, 30, 30, 255):GetVec4()) -- цвет при наведении на кнопку (темнее)
        imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImColor(135, 38, 38, 255):GetVec4()) -- цвет при нажатии на кнопку (светлее)
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