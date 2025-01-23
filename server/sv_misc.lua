local sender = 'Tow'

function SendMsg(dest, msg)
    TriggerClientEvent('chat:addMessage', dest, {
        color = {255, 255, 255},
        template = '<div>{0}^r: {1}</div>',
        args = {sender, msg},
    })
end
function SendMsgAll(msg)
    SendMsg(-1, sender, msg)
end