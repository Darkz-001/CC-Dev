Channel = ...
Channel = tonumber(Channel)
modem = peripheral.find("modem")

function main()
    modem.open(Channel)
    command = nil
    while command ~= "terminate" do
        command = io.read()
        modem.transmit(Channel, Channel, command)
        local event, modemSide, senderChannel, replyChannel, message, senderDistance = os.pullEvent("modem_message")
        if senderChannel ~= Channel then
            modem.close(senderChannel)
            print("message", message, "recived from different channel:", senderChannel)
        else
            print(message)
        end
    end
end


main()