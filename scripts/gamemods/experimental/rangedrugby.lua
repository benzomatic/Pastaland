--[[

  Rugby mode: pass the flag you hold to a teammate by shooting at him with rifle
  Addition for CTF: Set a limit on the pass range and dynamically highlight teammates that the flagholder can still pass to.

  Warning: This mod will cause high CPU usage.

]]--

local ents, trackent = require"std.ents", require"std.trackent"
local playermsg, commands, iterators = require"std.playermsg", require"std.commands", require"std.iterators"
local fp, L, vec3  = require"utils.fp", require"utils.lambda", require"utils.vec3"
local map = fp.map

local module, hooks = {}, {}


--[[ 
    Pass range restriction 
]]--

local basedist, share = 1500, 2/5

local function specialmap()
  return (server.smapname == "recovery" or server.smapname == "mercury" or server.smapname == "l_ctf") and 1500 or nil
end

spaghetti.addhook("entsloaded", function(info) 
  if not server.m_ctf or server.m_hold or server.m_protect then return end
  local base1, base2 = nil, nil
  for i, _, ment in ents.enum(server.FLAG) do
    if base1 then base2 = ment.o else base1 = ment.o end
  end
  if not base1 or not base2 then return end
  basedist = specialmap() or (vec3(base1):dist(base2) + 300) -- try to calculate max map size, including space behind bases [lazy]
  base1, base2 = nil, nil
end)

local function allowpass(actor, target)
  if server.m_hold or server.m_protect then return true end -- only restrict passing in ctf
  local playerdist = vec3(actor.state.o):dist(target.state.o)
  if playerdist <= (basedist * share) then return true end
  playermsg("\f6Info\f7: This player is \f3out of range\f7! You can only pass to teammates \f6close to you\f7! Close teammates have a \f0green indicator\f7!", actor)
  return false
end


--[[ 
    Particle effects: Assign particles to the teammates in pass-range.
]]-- 

local highlights = true
commands.add("togglehl", function(info)
  if info.ci.privilege < server.PRIV_ADMIN then return playermsg("Access denied.", info.ci) end  
  highlights = not highlights
  playermsg("Radius highlights are " .. (highlights and "enabled" or "disabled") .. " from now on.", info.ci)
end)

local function blindcnlist(viewer)
  local blindlist = {}
  for p in iterators.all() do
    if (p.clientnum ~= viewer.clientnum) then
      blindlist[p.clientnum] = true 
    end
  end
  return blindlist
end

local function particles(ci, viewer)
  ci.extra.hlpart = trackent.add(ci, function(i, lastpos)
    local o = vec3(lastpos.pos)
    o.z = o.z + 17
    ents.editent(i, server.PARTICLES, o, 11, 40, 30, 0x060)
  end, false, true, blindcnlist(viewer))
end

local function noparticles(ci)
  if ci.extra.hlpart then trackent.remove(ci, ci.extra.hlpart) end
end

local function highlightplayers(ci)
  if not highlights then return end
  ci.extra.hl = {}
  ci.extra.hl.updater = spaghetti.later(200, function()
    for p in iterators.inteam(ci.team) do
      noparticles(p) 
      if (vec3(ci.state.o):dist(p.state.o) <= (basedist * share)) and (ci.clientnum ~= p.clientnum) then 
        particles(p, ci)
      end
    end
  end, true)
end

local function stophighlight(ci)
  local hl = ci.extra.hl
  if not hl then return end
  if hl.updater then spaghetti.cancel(hl.updater) end
  for p in iterators.inteam(ci.team) do
    noparticles(p)
  end
end


--[[ 
    Rugby implementation 
]]--

function module.on(state)
  map.np(L"spaghetti.removehook(_2)", hooks)
  if not state then return end
  hooks.dodamagehook = spaghetti.addhook("dodamage", function(info)
    if info.skip or not server.m_ctf or info.target.team ~= info.actor.team or info.gun ~= server.GUN_RIFLE then return end
    local flags, actorflags = server.ctfmode.flags, {}
    for i = 0, flags:length() - 1 do if flags[i].owner == info.actor.clientnum then actorflags[i] = true end end
    if not next(actorflags) then return end
    info.skip = true
    if not allowpass(info.actor, info.target) then return end
    for flag in pairs(actorflags) do
      server.ctfmode:returnflag(flag, 0)
      server.ctfmode:takeflag(info.target, flag, flags[flag].version)
    end
    stophighlight(info.actor)
    -- a rugby pass also constitutes a takeflag event for info.target, so the highlight is initialized below instead of here
    local hooks = spaghetti.hooks.rugbypass
    if hooks then hooks{ actor = info.actor, target = info.target, flags = actorflags } end
  end, true)
  hooks.diedhook = spaghetti.addhook("servmodedied", function(info) 
    stophighlight(info.target)
  end)
  hooks.takeflag = spaghetti.addhook("takeflag", function(info) 
    stophighlight(info.ci)
    highlightplayers(info.ci)
  end)
  hooks.dropflag = spaghetti.addhook("dropflag", function(info) 
    stophighlight(info.ci)
  end)
  hooks.scoreflag = spaghetti.addhook("scoreflag", function(info) 
    stophighlight(info.ci)
  end)
  hooks.changemap = spaghetti.addhook("changemap", function(info) 
    for p in iterators.all() do
      stophighlight(p)
      noparticles(p)
    end
  end)
end

return module

