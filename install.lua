local program, extra = ...

if extra == "-r" or extra == "-u" then
    local name = program
    while string.find(name, "/") do
        name = string.sub(name, string.find(name, "/") + 1, -1)
    end
    shell.run("delete", name .. ".lua")
end

shell.run("wget", "https://raw.githubusercontent.com/Darkz-001/CC-Dev/main/" .. program .. ".lua")
