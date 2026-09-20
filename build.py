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


def main():
    parts = [HEADER]
    for file in sorted(SRC.rglob("*.lua")):
        name = file.relative_to(SRC).with_suffix("").as_posix()
        source = file.read_text(encoding="utf-8").rstrip() + "\n"
        parts.append(f'\n__modules["{name}"] = function()\n{source}end\n')

    parts.append(
        "\nlocal KeySystem = {}\n\n"
        "function KeySystem.new(options)\n"
        f'\treturn import("{ENTRY}").new(options)\n'
        "end\n\n"
        'KeySystem.Jnkie = import("utilities/jnkie")\n\n'
        "return KeySystem\n"
    )

    OUT.parent.mkdir(exist_ok=True)
    OUT.write_text("".join(parts), encoding="utf-8")
    print(f"ok -> {OUT.relative_to(ROOT)} ({OUT.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
