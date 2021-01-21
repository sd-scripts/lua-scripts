script_author('S&D Scripts')
script_name('MyCar')
script_version('1.0.1')
 
local sampev = require 'samp.events'
local imgui = require 'imgui'
local encoding = require 'encoding'
 
encoding.default = 'CP1251'
u8 = encoding.UTF8
 
local cars = {}
local car_info = {}
 
local main_window = imgui.ImBool(false)
local work = false
local state = 0
 
function sampev.onShowDialog(id, style, title, b1,b2,text)
    if id == 162 then
        if work then
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
                    name = v:match('%{FFFFFF%} (%w+)'),
                    id = i,
                    spawn = true
                }
            else
                t = {
                    name = v:match('(%w+)'),
                    id = i,
                    spawn = true
                }
            end
            table.insert(cars, t)
            i = i + 1
        end
 
        main_window.v = true
        sampSendDialogResponse(id, 0, nil, nil) 
        return false
 
    end
    if id == 163 then
        if title:find('{BFBBBA}Инструменты для .+ %(%d+%)') then
            if work then 
                work = false
                if not state_spawn then
                    carid = nil
                end
            else 
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
    if id == 0 and style == 0 and title == '{BFBBBA}Информация' then
        car_info = {}
        local t = {
            carname = text:match('%{FFFFFF%}Транспорт%: %{73B461%}(.+)%{FFFFFF%}.+Владелец'),  
            owner = text:match('Владелец: {......}(%w+_%w+){......}'),
            intermediary = text:match('Посредник%: %{73B461%}(%D+)%{FFFFFF%}'),
            mileage = text:match('Пробег%: %{73B461%}(%d+) км.%{FFFFFF%}'),
            tax = text:match('Налог%: %{73B461%}(%d+)%{FFFFFF%} %/ 150 000'),
            fine = text:match('Штраф%: %{73B461%}(%d+)%{FFFFFF%} %/ 80 000'),
            recovery_penalty = text:match('Штраф за восстановление%: %{73B461%}$(%d+)%{FFFFFF%}'),
            price = text:match('Цена покупки с госа%: %{73B461%}$(%d+)'),
            car_number = text:match('Номер автомобиля%: {......}(.+){......}.+Здоровье'),
            car_health_min = text:match('Здоровье автомобиля%: %{F57449%}(%d+.%d)/%d+.%d%{FFFFFF%}'),
            car_health_max = text:match('Здоровье автомобиля%: %{F57449%}%d+.%d/(%d+.%d)%{FFFFFF%}'),
            state = text:match('Состояние авто%: %{F57449%}(%d+)/100%{FFFFFF%}'),
            oil = text:match('Состояния масла%: %{F57449%}%{......%}(%X+)%{FFFFFF%}'),
            insurance_damage = text:match('Страховка %(на повреждение%)%: %{......%}(%X+)%{FFFFFF%}'),
            insurance_meeting = text:match('Страховка %(на слёт%)%: %{......%}(%X+)%{FFFFFF%}'),
        }
        table.insert(car_info, t)
        sampSendDialogResponse(id, 0, nil, nil)
        return false
    end
end
 
function sampev.onServerMessage(color,text)
    if text:find('Загрузить транспорт не удалось') and work then return false end

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
 
    apply_custom_style()
    while true do
        wait(0)
        imgui.Process = main_window.v
    end
end
 
function imgui.OnDrawFrame()
    if main_window.v then
 
        imgui.CenterText = function(text)
            imgui.SetCursorPosX((imgui.GetWindowWidth() - imgui.CalcTextSize(u8(text)).x)/2)
            imgui.Text(u8(text))
        end
 
        local sw, sh = getScreenResolution()
        imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(515, 465))
        imgui.Begin('MyCar',  main_window, imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoCollapse)
        imgui.BeginChild('##panel_1', imgui.ImVec2(145, 410), true)
            imgui.CenterText('Список авто:')
            for i, v in ipairs(cars) do
                imgui.ColButton(cars[i]['spawn'])  
                if imgui.Button(v['name'] .. '##' .. i, imgui.ImVec2(130,20)) then 
                    carname = v['name']; car_info = {}; carid = i; sampSendChat('/cars'); sampSendDialogResponse(162, 1, cars[carid]['id'], -1); state_spawn = cars[carid]['spawn']
                end    
                imgui.PopStyleColor(3)
            end
        imgui.EndChild()

        imgui.SameLine()
        
        imgui.BeginChild('##panel_2', imgui.ImVec2(347, 410), true)
            if reloadmod then
                imgui.SetCursorPosY(120)
                imgui.CenterText('Вы можете иметь лишь два загруженных транспорта.')
                imgui.CenterText('Выберите из списка, какой т/c выгрузить взамен:')
                imgui.NewLine()
                for i, v in ipairs(cars) do
                    if cars[i]['spawn'] then
                        if imgui.Button(v['name'], imgui.ImVec2(335,30)) then
                            recarid = carid; carid = i; state_spawn = false; work = true; state = 11; reloadmod = false; sampSendChat('/cars')
                        end
                    end
                end
                imgui.NewLine()
                imgui.SetCursorPosX(223)
                if imgui.Button(u8'Назад', imgui.ImVec2(120, 20)) then
                    reloadmod = false
                end
            end
            if parkingmod then
                imgui.SetCursorPosY(170)
                if imgui.Button(u8'Припарковать в этом месте', imgui.ImVec2(335,25)) then
                    parkingmod = false
                    parkingstate = 0
                    state = 4
                    work = true
                    sampSendChat('/cars')
                end
                if imgui.Button(u8'Вернуть на стандартную парковку', imgui.ImVec2(335,25)) then
                    parkingmod = false
                    parkingstate = 1
                    state = 4
                    work = true
                    sampSendChat('/cars')
                end
                --imgui.NewLine()
                imgui.SetCursorPosX(223)
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImColor(119, 136, 153, 255):GetVec4()) -- изначальный цвет RGBA
                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImColor(119, 136, 133, 255):GetVec4()) -- цвет при наведении на кнопку (темнее)
                imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImColor(119, 136, 173, 255):GetVec4()) -- цвет при нажатии на кнопку (светлее)
                if imgui.Button(u8'Назад', imgui.ImVec2(120, 20)) then
                    parkingmod = false
                end
                imgui.PopStyleColor(3)
            end
            if state_spawn and not parkingmod and not reloadmod then
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
                    imgui.SetColumnWidth(-1, 150); imgui.CenterColumnText(tostring(car_info[1] and car_info[1].mileage or '--').. ' km'); imgui.NextColumn()
                    imgui.Separator()
                    imgui.SetColumnWidth(-1, 170); imgui.CenterColumnText(u8'Налог'); imgui.NextColumn()
                    imgui.SetColumnWidth(-1, 150); imgui.CenterColumnText(u8(tostring(car_info[1] and car_info[1].tax.. ' из 150000' or '--'))); imgui.NextColumn()
                    imgui.Separator()
                    imgui.SetColumnWidth(-1, 170); imgui.CenterColumnText(u8'Штраф'); imgui.NextColumn()
                    imgui.SetColumnWidth(-1, 150); imgui.CenterColumnText(u8(tostring(car_info[1] and car_info[1].fine.. ' из 80000' or '--'))); imgui.NextColumn()
                    imgui.Separator()
                    imgui.SetColumnWidth(-1, 170); imgui.CenterColumnText(u8'Штраф за восстановление'); imgui.NextColumn()
                    imgui.SetColumnWidth(-1, 150); imgui.CenterColumnText(tostring(car_info[1] and car_info[1].recovery_penalty.. '$' or '--')); imgui.NextColumn()
                    imgui.Separator()
                    imgui.SetColumnWidth(-1, 170); imgui.CenterColumnText(u8'Государственная стоимость'); imgui.NextColumn()
                    imgui.SetColumnWidth(-1, 150); imgui.CenterColumnText(tostring(car_info[1] and car_info[1].price.. '$' or '--')); imgui.NextColumn()
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
                    imgui.SetColumnWidth(-1, 150); imgui.CenterColumnText(u8(tostring(car_info[1] and car_info[1].insurance_meeting or '--')))
                imgui.EndChild()
                imgui.Separator()
                if imgui.Button(u8'DOOR', imgui.ImVec2(79,20)) then
                    state = 2
                    work = true
                    sampSendChat('/cars') 
                end
                if imgui.IsItemHovered() then imgui.BeginTooltip() imgui.TextUnformatted(u8('Открыть/закрыть двери транспортного средства.')) imgui.EndTooltip() end 
                imgui.SameLine()
                if imgui.Button(u8'KEY', imgui.ImVec2(79,20)) then 
                    state = 3
                    work = true
                    sampSendChat('/cars') 
                end
                if imgui.IsItemHovered() then imgui.BeginTooltip() imgui.TextUnformatted(u8('Вставить/вытащить ключи из замка зажигания.')) imgui.EndTooltip() end
                imgui.SameLine()
                if imgui.Button(u8'DRIVE', imgui.ImVec2(79,20)) then 
                    state = 8
                    work = true
                    sampSendChat('/cars') 
                end
                if imgui.IsItemHovered() then imgui.BeginTooltip() imgui.TextUnformatted(u8('Изменить режим езды [Sport, Comfort].')) imgui.EndTooltip() end
                imgui.SameLine()
                if imgui.Button(u8'ABS', imgui.ImVec2(79,20)) then 
                    state = 9
                    work = true
                    sampSendChat('/cars') 
                end
                if imgui.IsItemHovered() then imgui.BeginTooltip() imgui.TextUnformatted(u8('Включить/выключить систему ABS.')) imgui.EndTooltip() end
                imgui.Separator()
                if imgui.Button(u8'Припарковать', imgui.ImVec2(107,20)) then 
                    parkingmod = true 
                end
                imgui.SameLine()
                if imgui.Button(u8'Найти', imgui.ImVec2(107,20)) then 
                    state = 5
                    work = true
                    sampSendChat('/cars') 
                end
                imgui.SameLine()
                if imgui.Button(u8'Сигнализация', imgui.ImVec2(107,20)) then 
                    state = 6
                    work = true
                    sampSendChat('/cars') 
                end
                if imgui.Button(u8'Очистить посредников') then 
                    state = 7
                    work = true
                    sampSendChat('/cars') 
                end
                if imgui.IsItemHovered() then imgui.BeginTooltip() imgui.TextUnformatted(u8('Забрать ключи у человека, которому вы их давали.')) imgui.EndTooltip() end
                imgui.SameLine()
                if imgui.Button(u8'Заспавнить', imgui.ImVec2(89,20)) then 
                    state = 10
                    work = true
                    sampSendChat('/cars') 
                end
                if imgui.IsItemHovered() then imgui.BeginTooltip() imgui.TextUnformatted(u8('Ваше транспортное средство переместится на место парковки.\nСтоимость услуги: 1.000$.')) imgui.EndTooltip() end
                imgui.SameLine()
                if imgui.Button(u8'Выгрузить', imgui.ImVec2(89,20)) then
                    state_spawn = false
                    state = 1
                    work = true
                    sampSendChat('/cars')
                end
            elseif not state_spawn and not parkingmod and not reloadmod then
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
        imgui.SetCursorPosX(345)
        imgui.TextColoredRGB('{4169E1}S&D Scripts™  {ffffff}Version: {808080}' ..thisScript().version)
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
 
function imgui.CenterColumnText(text)
    imgui.SetCursorPosX((imgui.GetColumnOffset() + (imgui.GetColumnWidth() / 2)) - imgui.CalcTextSize(text).x / 2)
    imgui.Text(text)
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