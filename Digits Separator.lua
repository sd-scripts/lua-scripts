script_author('S&D Scripts')
script_name('Digits Separator')
script_version('1.0')
script_description("[EN] Separator of numbers by digits. Simplifies the appearance of large numbers.\n[RU] Разделитель чисел по разрядам. Упрощает вид больших чисел.")
script_dependencies('SAMPFUNCS; SampEvents')
script_url('https://sd-scripts.ru')

local ev = require('lib.samp.events')

function replace(text)
    local function comma(n)
        local v1,v2,v3 = string.match(n,'^([^%d]*%d)(%d*)(.-)$')
        return (v1 .. (v2:reverse():gsub('(%d%d%d)','%1.'):reverse()) .. v3)
    end
    for S in string.gmatch(text, "%$%d+") do
        text = string.gsub(text, S, comma(S))
    end
    for S in string.gmatch(text, "%d+%$") do
        S = string.sub(S, 0, #S-1)
        text = string.gsub(text, S, comma(S))
    end
    return text
end

function ev.onShowDialog(id, style, title, button1, button2, text)
    if text:find('%$') then 
        return {id, style, title, button1, button2, replace(text)}
    end
end

function ev.onShowTextDraw(id, data)
    if data.text:find('%$') then 
        return {id, replace(data.text)}
    end
end

function ev.onCreate3DText(idObject, color, position, distance, testLOS, attachedPlayerId, attachedVehicleId, textObject)
    if textObject:find('$') then 
        return {idObject, color, position, distance, testLOS, attachedPlayerId, attachedVehicleId, replace(textObject)}
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
        sampAddChatMessage('{ffffff}и это не выход из игры/перезагрузка скриптов, свяжитесь с нами в сообществе ВК: vk.me/sd_scripts', 0xBBBBBB)
    end
end