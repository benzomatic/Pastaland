--[[

	A jail for ignorant, blunt or nasty players

]]--

local commands, playermsg = require"std.commands", require"std.playermsg"

-- current collection of inmates, which is checked at connect and unspec.
-- format: inmates = { ["1.2.3.4"] = "PlayerName" }
local inmates = {} 

-- set the default jailtime in hours here
local jailtime = 1

local function spec_player (ci)
    server.forcespectator(ci)
end

local function bailout (arg) -- arg = { ci = who, ip = "1.2.3.4." }
	if not (arg.ci or arg.ip) then return end
	local bailee = arg.ip or engine.getclientip(arg.ci.clientnum)
	if inmates[bailee] then	
		local name = inmates[bailee]
		inmates[bailee] = nil
		if arg.ci then 
			server.unspectate(arg.ci) 
			server.sendservmsg(string.format("\f3[\f7JAIL\f3]\f7 Bailed %s out!", name))
			engine.writelog(string.format("[JAIL] Bailed %s out!", name))
		end
	end
end

-- Major commands
local function jail (info)
	if info.ci.privilege < server.PRIV_MASTER then playermsg("Insufficient privileges to use this command.", info.ci) return end
	
	local cn = info.args:match("^(%d+)%s*$")
	if not cn then playermsg("Missing argument!", info.ci) return end

	local who = engine.getclientinfo(cn)
	if not who then playermsg("Cannot find cn " .. cn .. ".", info.ci) return end

	if not inmates[engine.getclientip(cn)] then	
		inmates[engine.getclientip(cn)] = who.name
		spec_player(who)
	    server.sendservmsg(string.format("\f3[\f7JAIL\f3]\f7 Jailed %s to spectator!", who.name))
	    engine.writelog(string.format("[JAIL] Jailed %s to spectator!", who.name))
		spaghetti.later(jailtime*60*60*1000, function() bailout{ip = engine.getclientip(who.clientnum)} end)
	else playermsg("\f3[\f7JAIL\f3]\f7 Player is already locked up!", info.ci) return end
end
commands.add("jail", jail, "#jail <cn>\nForce a player to stay in spectator (reconnect safe).")

local function free (info)
	if info.ci.privilege < server.PRIV_MASTER then playermsg("Insufficient privileges to use this command.", info.ci) return end
	local cn = info.args:match("^(%d+)%s*$")
	if not cn then playermsg("Missing argument!", info.ci) return end

	local who = engine.getclientinfo(cn)
	if not who then playermsg("Cannot find cn " .. cn .. ".", info.ci) return end
	bailout{ci = who}
end
commands.add("free", free, "#free <cn>\nFreeing someone from jail is always a good movie plot!")

-- Captain hooks
local function checkjailed (info)
	if inmates[engine.getclientip(info.spectator)] then 
		playermsg("\f3[\f7JAIL\f3]\f7 Nuh uh! You stay right where you are.", info.ci)
		info.skip = true 
	end
end
spaghetti.addhook(server.N_SPECTATOR, checkjailed)

local function checkjailed_c (info)
	if inmates[info.ip] then 
		spec_player(info.ci)
		playermsg("\f3[\f7JAIL\f3]\f7 Huh, where did you go? You belong in jail!", info.ci)
	end
end
spaghetti.addhook("clientconnect", checkjailed_c)