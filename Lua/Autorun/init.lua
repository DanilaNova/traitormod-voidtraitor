if CLIENT then return end

Traitormod = {}
Traitormod.VERSION = "2.5.8a"

print(">> Traitor Mod VoidTraitor v" .. Traitormod.VERSION)
print(">> Github Contributors: evilfactory, MassCraxx, Philly-V, Qunk1, mc-oofert, DanilaNova.")
print(">> Special thanks to Qunk, Femboy69 and JoneK for helping in the development of this mod.")

local path = table.pack(...)[1]

--- Path to a mod folder
Traitormod.Path = path

dofile(Traitormod.Path .. "/Lua/traitormod.lua")