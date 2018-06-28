--[[

  Rugby mode: pass the flag you hold to a teammate by shooting at him with rifle
  Addition for CTF: Set a limit on the pass range and dynamically highlight teammates that the flagholder can still pass to.

]]--

local ents, trackent, vec3  = require"std.ents", require"std.trackent", require"utils.vec3"
local playermsg, commands, iterators = require"std.playermsg", require"std.commands", require"std.iterators"

local module = {}


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
	It can be toggled if the particles are only visible to the flagholder or also the teammates themselves.
]]-- 

local highlights = true
commands.add("togglehl", function(info)
  if info.ci.privilege < server.PRIV_ADMIN then return playermsg("Access denied.", info.ci) end  
  highlights = not highlights
  playermsg("Radius highlights are " .. (highlights and "enabled" or "disabled") .. " from now on.", info.ci)
end)

local hidehl = true
commands.add("hidehl", function(info)
  if info.ci.privilege < server.PRIV_ADMIN then return playermsg("Access denied.", info.ci) end  
  hidehl = not hidehl
  playermsg("Radius highlights are now " .. (hidehl and "hidden" or "visible") .. " for teammates.", info.ci)
end)

local function blindcnlist(viewer)
  local blindlist = {}
  for p in iterators.all() do
    if hidehl then 
      if p.clientnum ~= viewer.clientnum then 
        blindlist[p.clientnum] = true 
      end 
    else 
      if p.team ~= viewer.team then 
        blindlist[p.clientnum] = true 
      end 
    end
  end
  return blindlist
end

local function radiuslist(actor)
  list = {}
  for target in iterators.all() do
    if vec3(actor.state.o):dist(target.state.o) <= (basedist * share) and actor.team == target.team and actor.clientnum ~= target.clientnum then list[target.clientnum] = true end
  end
  return list
end

particles = function(ci, viewer)
  ci.extra.hlpart = trackent.add(ci, function(i, lastpos)
    local o = vec3(lastpos.pos)
    o.z = o.z + 17
    ents.editent(i, server.PARTICLES, o, 11, 40, 30, 0x060)
  end, false, true, blindcnlist(viewer))
end

noparticles = function(ci)
  if ci.extra.hlpart then trackent.remove(ci, ci.extra.hlpart) end
end

local function highlightplayers(ci)
  if not highlights then return end
  local hl = {}
  hl.radiuslist = radiuslist(ci)
  hl.listupdate = spaghetti.addhook("positionupdate", function(player)
    if player.cp.team ~= ci.team then return end
    hl.radiuslist = radiuslist(ci)
  end)
  hl.updater = spaghetti.later(250, function()
  for p in iterators.all() do
    if p.team == ci.team then noparticles(p) end --lazy
    if hl.radiuslist[p.clientnum] then particles(p, ci) end
  end
  end, true)
  ci.extra.hl = hl
end

local function stophighlight(ci)
  local hl = ci.extra.hl
  if not hl then return end
  if hl.listupdate then spaghetti.removehook(hl.listupdate) end
  for p in iterators.all() do
    if hl.radiuslist[p.clientnum] then noparticles(p) end
  end
  if hl.radiuslist then for k,v in pairs(hl.radiuslist) do hl.radiuslist[k]=nil end end
  if hl.updater then spaghetti.cancel(hl.updater) end
  ci.extra.hl = nil
end


--[[ 
	Rugby implementation 
]]--

local dodamagehook
function module.on(state)
  if dodamagehook then spaghetti.removehook(dodamagehook) dodamagehook = nil end
  if not state then return end
  dodamagehook = spaghetti.addhook("dodamage", function(info)
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
    -- the new highlighter for info.target will be initiated in the takeflag-hook below
    local hooks = spaghetti.hooks.rugbypass
    if hooks then hooks{ actor = info.actor, target = info.target, flags = actorflags } end
  end, true)
end

spaghetti.addhook("takeflag", function(info) 
  stophighlight(info.ci)
  highlightplayers(info.ci)
end)
spaghetti.addhook("dropflag", function(info) 
  stophighlight(info.ci)
end)
spaghetti.addhook("scoreflag", function(info) 
  stophighlight(info.ci)
end)
spaghetti.addhook("changemap", function(info) 
  for p in iterators.all() do
    stophighlight(p)
    noparticles(p)
  end
end)

return module
