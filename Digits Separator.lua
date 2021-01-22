script_author('S&D Scripts')
script_name('Digits Separator')
script_version('1.0')
script_description("[EN] Separator of numbers by digits. Simplifies the appearance of large numbers.\n[RU] Разделитель чисел по разрядам. Упрощает вид больших чисел.")
script_dependencies('SAMPFUNCS; SampEvents')
script_url('https://sd-scripts.ru')

local ev = require('lib.samp.events')

function replace(text)
    local function comma(n)
        local v1, v2, v3 = string.match(n,'^([^%d]*%d)(%d*)(.-)$')
        return (v1 .. (v2:reverse():gsub('(%d%d%d)','%1.'):reverse()) .. v3)
    end
    
    if text:match('%$%d+%.0') or text:match('%d+%.0%$') then 
        text = text:gsub('%.0', '')
    end

    local list = {}
    for S in text:gmatch('(%d+)%$') do table.insert(list, S) end
    for S in text:gmatch('%$(%d+)') do table.insert(list, S) end
    
    for _, v in ipairs(list) do text = string.gsub(text, v, comma(v), 1) end
        
    return text
end

function ev.onShowDialog(id, style, title, button1, button2, text)
    if title:find('%$') or text:find('%$') then title = replace(title) end
    if text:find('%$') then text = replace(text) end
    return {id, style, title, button1, button2, text}
end

function ev.onShowTextDraw(id, data)
    if data.text and data.text:find('%$') then 
        data.text = replace(data.text)
        return {id, data}
    end
end

function ev.onTextDrawSetString(id, text)
    if text:find('%$') then
        return {id, replace(text)}
    end
end

function ev.onDisplayGameText(style, time, text)
    if text:find('%$') then 
        return {style, time, replace(text)}
    end
end

function ev.onCreate3DText(idObject, color, position, distance, testLOS, attachedPlayerId, attachedVehicleId, textObject)
    if textObject and textObject:find('%$') then 
        return {idObject, color, position, distance, testLOS, attachedPlayerId, attachedVehicleId, textObject and replace(textObject) or ''}
    end
end

function ev.onServerMessage(color, text)
    if text:find('%$') then
        return {color, replace(text)}
    end
end

function onScriptTerminate(LuaScript, quitGame)
    if LuaScript == thisScript() then
        sampAddChatMessage('[Digits Separator] {ffffff}Скрипт неожиданно прекратил работу. Если вы предполагаете, из-за чего это могло произойти,', 0xBBBBBB)
        sampAddChatMessage('{ffffff}и это не является выходом из игры/перезагрузка скриптов, свяжитесь с нами в сообществе ВК: vk.me/sd_scripts', 0xBBBBBB)
    end
end