local dfpwm = require("cc.audio.dfpwm")
local speaker = peripheral.find("speaker")

local song = "songs/elevator_music.dfpwm"

local decoder = dfpwm.make_decoder()
for chunk in io.lines(song, 16 * 1024) do
    local buffer = decoder(chunk)

    while not speaker.playAudio(buffer) do
        os.pullEvent("speaker_audio_empty")
    end
end