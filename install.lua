local program, extra = ...

if extra == "-r" or extra == "-u" then
    while string.find(program, "/") do
        program = string.sub(program, string.find(program, "/") + 1, -1)
    end
    shell.run("delete", program .. ".lua")
end

shell.run("wget", "https://raw.githubusercontent.com/Darkz-001/CC-Dev/main/" .. program .. ".lua")
