--[[

  Configuration for Pastaland

]]--

if not os.getenv("GST") then return end     -- the shorter the better 
engine.writelog("Applying the Pastaland configuration.")

local servertag = require"utils.servertag"
servertag.tag = "gustavo"

local uuid = require"std.uuid"
local iterators = require"std.iterators"

local fp, L = require"utils.fp", require"utils.lambda"
local map, I = fp.map, fp.I
local abuse, playermsg, putf = require"std.abuse", require"std.playermsg", require"std.putf"

cs.maxclients = 26    -- with autospec we can afford a generous number here 
cs.serverport = 28785
spaghetti.later(10000, L'engine.requestmaster("\\n")', true)
spaghetti.addhook("masterin", L'if _.input:match("^failreg") then engine.lastupdatemaster = 0 end', true)

--make sure you delete the next two lines, or I'll have admin on your server.
cs.serverauth = "gustavo"
local auth = require"std.auth"

-- need at least an admin to edit keys using the authloader module
cs.adduser("GustavoLapasta", "gustavo", "+0f4edc6a81315c60974f532ddda9bbcf410a47559ffdd233", "a")

table.insert(auth.preauths, "gustavo")

local authloader = require"std.authloader"
authloader.loadAuths()

spaghetti.addhook(server.N_SETMASTER, L"_.skip = _.skip or (_.mn ~= _.ci.clientnum and _.ci.privilege < server.PRIV_AUTH)")

cs.serverdesc = "\f7:: Pastaland ::"

cs.lockmaprotation = 2
cs.ctftkpenalty = 1 -- teamkillers can't take the flag from flagholder 
cs.maprotationreset()

--copied from data/menus.cfg
local ctfmaps = table.concat({
  "abbey akroseum arbana asgard authentic autumn bad_moon berlin_wall bt_falls campo capture_night catch22 core_refuge core_transfer damnation desecration dust2",
  "eternal_valley europium face-capture flagstone forge forgotten garden hallo haste hidden infamy kopenhagen l_ctf mach2 mbt1 mbt12",
  "mbt4 mercury mill nitro nucleus recovery redemption reissen sacrifice shipwreck siberia snapper_rocks spcr subterra suburb tejen tempest",
  "tortuga turbulence twinforts urban_c valhalla wdcd xenon fc5 gubo duomo"
}, " ")
 
ctfmaps = map.uv(function(maps)
  local t = map.f(I, maps:gmatch("[^ ]+"))
  for i = 2, #t do
    local j = math.random(i)
    local s = t[j]
    t[j] = t[i]
    t[i] = s
  end
  return table.concat(t, " ")
end, ctfmaps)

cs.maprotation("instactf", ctfmaps)
--server.mastermask = server.MM_PUBSERV + server.MM_AUTOAPPROVE --old setting with open master
server.mastermask = server.MM_MODE + server.MM_AUTH --you need some authkey now to get master

--gamemods
spaghetti.addhook("changemap", L'require"gamemods.rugby".on(server.m_ctf)')

local commands = require"std.commands"
local nextflagswitch = false

--commands.add("flagswitch", function(info)
--  local arg = info.args == "" and 1 or tonumber(info.args)
--  if not arg then playermsg("Invalid flagswitch value", info.ci) end
--  local old = nextflagswitch
--  nextflagswitch = arg == 1
--  if old == nextflagswitch then return end
--  if nextflagswitch and (not server.m_ctf or server.m_hold) then playermsg("Mind that you still need to force the next mode to be ctf/protect.", info.ci) end
--  server.sendservmsg(server.colorname(info.ci, nil) .. (nextflagswitch and " activated" or " deactivated") .. " \f1flag switch mode\f7 for the next map (see #help flagswitch).")
--end, "Usage: #flagswitch [0|1]: activate flag switch (blue flag spawns in place of red and viceversa) for the next map if mode is ctf or protect (default 1, only masters)")

local flagswitch, currentflagswitch = require"gamemods.flagswitch", false
spaghetti.addhook("entsloaded", function()
  currentflagswitch = false
  nextflagswitch = nextflagswitch and server.m_ctf and not server.m_hold
  if not nextflagswitch then flagswitch.on(false) return end
  nextflagswitch = false
  flagswitch.on(true)
  currentflagswitch = true
end)

commands.add("maxclients", function(info)
  if info.ci.privilege < server.PRIV_ADMIN then return playermsg("Insufficient privilege to get IPs.", info.ci) end
  if not info.args then return playermsg("Invalid maxclients value", info.ci) end
  local n = tonumber(info.args)
  if not n then return playermsg("Invalid maxclients value", info.ci) end
  cs.maxclients = n
  playermsg("Maxclients set to " .. tostring(n), info.ci)
  end, "#maxclients <n>, change the maximum number of allowed clients"
)

commands.add("skipmap", function(info)
 if info.ci.privilege < (server.PRIV_MASTER) then playermsg("Insufficient privilege.", info.ci) return end
 server.gamelimit = server.gamemillis
 engine.sendpacket(-1, 1, putf({10, r=1}, server.N_TIMEUP, 0):finalize(), -1)
 server.sendservmsg(server.colorname(info.ci, nil) .. " changes to the next map.")
 end, "#skipmap, skip the current map."
)

local ents = require"std.ents", require"std.maploaded"

require"std.pm"       -- private messaging module
require"std.getip"    -- get ip module
require"std.jokes"    -- jokes module
require"std.stats"    -- statistics module
require"std.autospec" -- autospec module
require"std.db"       -- Pastalandjs module
require"std.mapbattle_gst"-- mapbattle module
require"std.rename"   -- rename module
require"std.disconnect" --disconnect module
require"std.pastanames" --pastanames module
require"std.speclock"   --speclock module
--require"std.settime"  -- USE ONLY DURING TESTING

spaghetti.addhook("entsloaded", function()
  if server.smapname ~= "thetowers" then return end
  for i, _, ment in ents.enum(server.JUMPPAD) do if ment.attr4 == 40 then
    ents.editent(i, server.JUMPPAD, ment.o, ment.attr1, ment.attr2, ment.attr3)
    break
  end end
end)

--moderation
cs.teamkillkick("*", 5, 30)     -- keep autokick quite low

--limit reconnects when banned, or to avoid spawn wait time
abuse.reconnectspam(1/60, 5)

--limit some message types
spaghetti.addhook(server.N_KICK, function(info)
  if info.skip or info.ci.privilege > server.PRIV_MASTER then return end
  info.skip = true
  playermsg("No. Use gauth.", info.ci)
end)
spaghetti.addhook(server.N_SOUND, function(info)
  if info.skip or abuse.clientsound(info.sound) then return end
  info.skip = true
  playermsg("I know I used to do that but... whatever.", info.ci)
end)
abuse.ratelimit({ server.N_TEXT, server.N_SAYTEAM }, 0.5, 10, L"nil, 'I don\\'t like spam.'")
abuse.ratelimit(server.N_SWITCHNAME, 1/30, 4, L"nil, 'You\\'re a pain.'")
abuse.ratelimit(server.N_MAPVOTE, 1/10, 3, L"nil, 'That map sucks anyway.'")
abuse.ratelimit(server.N_SPECTATOR, 1/30, 5, L"_.ci.clientnum ~= _.spectator, 'Can\\'t even describe you.'") --self spec
abuse.ratelimit(server.N_MASTERMODE, 1/30, 5, L"_.ci.privilege == server.PRIV_NONE, 'Can\\'t even describe you.'")
abuse.ratelimit({ server.N_AUTHTRY, server.N_AUTHKICK }, 1/60, 4, L"nil, 'Are you really trying to bruteforce a 192 bits number? Kudos to you!'")
abuse.ratelimit(server.N_SERVCMD, 0.5, 10, L"nil, 'Yes I\\'m filtering this too.'")
abuse.ratelimit(server.N_JUMPPAD, 1, 10, L"nil, 'I know I used to do that but... whatever.'")
abuse.ratelimit(server.N_TELEPORT, 1, 10, L"nil, 'I know I used to do that but... whatever.'")

--prevent masters from annoying players
local tb = require"utils.tokenbucket"
local function bullying(who, victim)
  local t = who.extra.bullying or {}
  local rate = t[victim.extra.uuid] or tb(1/30, 6)
  t[victim.extra.uuid] = rate
  who.extra.bullying = t
  return not rate()
end
spaghetti.addhook(server.N_SETTEAM, function(info)
  if info.skip or info.who == info.sender or not info.wi or info.ci.privilege == server.PRIV_NONE then return end
  local team = engine.filtertext(info.text):sub(1, engine.MAXTEAMLEN)
  if #team == 0 or team == info.wi.team then return end
  if bullying(info.ci, info.wi) then
    info.skip = true
    playermsg("...", info.ci)
  end
end)
spaghetti.addhook(server.N_SPECTATOR, function(info)
  if info.skip or info.spectator == info.sender or not info.spinfo or info.ci.privilege == server.PRIV_NONE or info.val == (info.spinfo.state.state == engine.CS_SPECTATOR and 1 or 0) then return end
  if bullying(info.ci, info.spinfo) then
    info.skip = true
    playermsg("...", info.ci)
  end
end)

--ratelimit just gobbles the packet. Use the selector to add a tag to the exceeding message, and append another hook to send the message
local function warnspam(packet)
  if not packet.ratelimited or type(packet.ratelimited) ~= "string" then return end
  playermsg(packet.ratelimited, packet.ci)
end
map.nv(function(type) spaghetti.addhook(type, warnspam) end,
  server.N_TEXT, server.N_SAYTEAM, server.N_SWITCHNAME, server.N_MAPVOTE, server.N_SPECTATOR, server.N_MASTERMODE, server.N_AUTHTRY, server.N_AUTHKICK, server.N_CLIENTPING
)

local sound = require"std.sound"
spaghetti.addhook(server.N_TEXT, function(info)
  if info.skip then return end
  local low = info.text:lower()
  if not low:match"cheat" and not low:match"hack" and not low:match"auth" and not low:match"kick" then return end
  local tellcheatcmd = info.ci.extra.tellcheatcmd or tb(1/30000, 1)
  info.ci.extra.tellcheatcmd = tellcheatcmd
  if not tellcheatcmd() then return end
  playermsg("\f2Problems with a cheater? Use Irc: #sauercom", info.ci)
  sound(info.ci, server.S_HIT, true) sound(info.ci, server.S_HIT, true)
end)

require"std.enetping"

local parsepacket = require"std.parsepacket"
spaghetti.addhook("martian", function(info)
  if info.skip or info.type ~= server.N_TEXT or info.ci.connected or parsepacket(info) then return end
  local text = engine.filtertext(info.text, true, true)
  engine.writelog(("limbotext: (%d) %s"):format(info.ci.clientnum, text))
  info.skip = true
end, true)

--simple banner

commands.add("info", function(info)
  playermsg("Pastaland is a server based on pisto's spaghettimod, brought to you with love by GustavoLapasta. Visit www.pastaland.ovh for more info.", info.ci)
end)

local function gamemoddesc()
  local msg
  if ents.active() and currentflagswitch then msg = "\n\f1Flag switch mode activated\f7! " .. (server.m_protect and "Your flag spawns in the enemy base!" or "Bring the enemy flag back to the enemy base!") end
  --if server.m_ctf then msg = (msg or "") .. "\n\f3Rugby mode activated\f7! Shoot a teammate to pass the flag you are carrying" end
  return msg
end

local function checkbalance(info)
  local evilTeam = 0
  local goodTeam = 0
  for ci in iterators.all() do
    if ((ci.team == "evil") and (ci.state.state ~= engine.CS_SPECTATOR)) then evilTeam = evilTeam + 1
    elseif ((ci.team == "good") and (ci.state.state ~= engine.CS_SPECTATOR)) then goodTeam = goodTeam + 1
    end
  end
  if info.ci.team == "good" and goodTeam <= evilTeam then info.skip = true
  elseif info.ci.team == "evil" and evilTeam <= goodTeam then info.skip = true
  end
  engine.writelog(("teamswitch from team %s; evil:%d good:%d from %s denied:%s"):format(info.ci.team, evilTeam, goodTeam, info.ci.name, tostring(info.skip)))
end
spaghetti.addhook(server.N_SWITCHTEAM, checkbalance)

local passes = {}
local function resetstreak(info) if not info.i then passes = {} else passes[info.i] = nil end end
spaghetti.addhook("changemap", resetstreak)
spaghetti.addhook("returnflag", resetstreak)
spaghetti.addhook("resetflag", resetstreak)

spaghetti.addhook("rugbypass", function(info)
  server.sendservmsg(server.colorname(info.actor, nil) .. " passed to " .. server.colorname(info.target, nil) .. "!")
  if server.m_hold or server.m_protect or info.actor.state.aitype ~= server.AI_NONE then return end   --sendresume with bots is problematic
  local i = next(info.flags)
  local streak = passes[i] or {}
  streak[info.actor.extra.uuid] = true
  passes[i] = streak
  
  if playerStats then --if global variable "players" is set, we are using std.stats
      playerStats:addPass(info.actor.clientnum)
       --need to correct the stats values
      playerStats:addDamage(info.actor.clientnum, server.GUN_RIFLE, -100)
      playerStats:subtractShot(info.actor.clientnum, server.GUN_RIFLE)
  end
end)

spaghetti.addhook("scoreflag", function(info)
  local streak = passes[info.relay] or {}
  streak[info.ci.extra.uuid] = nil
  passes[info.relay] = nil
  streak = map.gp(uuid.find, streak)
  if #streak == 0 then return end
  for _, ci in ipairs(streak) do ci.state.flags = ci.state.flags + 1 server.sendresume(ci) end
  server.sendservmsg("Passes in flagrun (+1 flag point): " .. table.concat(map.li(L"server.colorname(_2, nil)", streak), ", "))
end)

banner = "\n\f7Welcome to \f2Pastaland! \f7A rebrand of spaghettimod kindly brought to you by \f0Gustavo\f7La\f3Pasta\nctf/protect/hold have \f3RUGBY MODE\f7: shoot a teammate to pass the flag you are carrying!\nCome visit the forum: \f6www.pastaland.ovh\f7, we have cookies :-)"
spaghetti.addhook("maploaded", function(info)
  if info.ci.extra.bannershown then
    local moddesc = gamemoddesc()
    return moddesc and playermsg(moddesc, info.ci)
  end
  info.ci.extra.bannershown = true
  local ciuuid = info.ci.extra.uuid
  spaghetti.later(1000, function()
    local ci = uuid.find(ciuuid)
    if not ci then return end
    local moddesc = gamemoddesc()
    playermsg(banner .. (moddesc and moddesc or ""), ci)
  end)
end)

spaghetti.later(30000, function()
  return server.m_ctf and server.sendservmsg("Remember, it's RUGBY MODE: you \f6shoot a teammate\f7 with \f3rifle\f7 to \f6pass the flag\f7!")
end, true)

