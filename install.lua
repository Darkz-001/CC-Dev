program, extra = ...

if extra == "-r" or extra == "-u" then
    shell.run("delete", program .. ".lua")
end

shell.run("wget", "https://raw.githubusercontent.com/Darkz-001/CC-Dev/main/" .. program .. ".lua")
