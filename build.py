#!/usr/bin/env python3 

from pathlib import Path

ROOT = Path(__file__).parent
SRC = ROOT / "src"
OUT = ROOT / "dist" / "main.lua"

ENTRY = "components/window/ui"

HEADER = """\
local __modules = {}
local __cache = {}

local function import(path)
	local cached = __cache[path]
	if cached ~= nil then
		return cached
	end
	local loader = __modules[path]
	if not loader then
		error("module not found: " .. tostring(path))
	end
	local value = loader()
	__cache[path] = value
	return value
end
"""

FOOTER = """
local KeySystem = {}

function KeySystem.new(options)
\treturn import("__ENTRY__").new(options)
end

-- Works as KeySystem:SetGetkeyTitle("...") or KeySystem.SetGetkeyTitle("...")
local function firstArg(a, b)
\tif a == KeySystem then
\t\treturn b
\tend
\treturn a
end

function KeySystem.SetGetkeyTitle(a, b)
\timport("__ENTRY__").SetGetkeyTitle(firstArg(a, b))
\treturn KeySystem
end

function KeySystem.SetGetkeyIcon(a, b)
\timport("__ENTRY__").SetGetkeyIcon(firstArg(a, b))
\treturn KeySystem
end

-- Works as KeySystem:SetNotifStyle("3") / KeySystem:NotifStyle("3")
function KeySystem.SetNotifStyle(a, b)
\timport("__ENTRY__").SetNotifStyle(firstArg(a, b))
\treturn KeySystem
end

KeySystem.NotifStyle = KeySystem.SetNotifStyle

-- Works as KeySystem:GetMethod({...}) / KeySystem.GetMethod({...}), same as the
-- other Set* helpers above: usable standalone, before KeySystem.new(...) exists.
function KeySystem.GetMethod(a, b)
\treturn import("__ENTRY__").GetMethod(firstArg(a, b))
end

-- Works as KeySystem:SetUIFont("...") / KeySystem.SetUIFont("...")
function KeySystem.SetUIFont(a, b)
\timport("__ENTRY__").SetUIFont(firstArg(a, b))
\treturn KeySystem
end

-- Works as KeySystem:SetTitleFont("...") / KeySystem.SetTitleFont("...")
function KeySystem.SetTitleFont(a, b)
\timport("__ENTRY__").SetTitleFont(firstArg(a, b))
\treturn KeySystem
end

KeySystem.Jnkie = import("utilities/jnkie")

return KeySystem
"""


def main():
    parts = [HEADER]
    for file in sorted(SRC.rglob("*.lua")):
        name = file.relative_to(SRC).with_suffix("").as_posix()
        source = file.read_text(encoding="utf-8").rstrip() + "\n"
        parts.append(f'\n__modules["{name}"] = function()\n{source}end\n')

    parts.append(FOOTER.replace("__ENTRY__", ENTRY))

    OUT.parent.mkdir(exist_ok=True)
    OUT.write_text("".join(parts), encoding="utf-8")
    print(f"ok -> {OUT.relative_to(ROOT)} ({OUT.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
