--[[

  This module provides the following functionality:
  - add the #disconnect command, to disconnect clients giving the "Server FULL" message
  - the #disconnect command can also accept multiple cn's: : #disconnect <cn> [<cn> <cn>...]

]]--


local commands, playermsg, client = require("std.commands"), require("std.playermsg"), require("std.n_client")

local dc_clientnums = {}
local dc_invalid = false

commands.add("disconnect", function(info)

  if info.ci.privilege < server.PRIV_MASTER then return playermsg("Insufficient privilege.", info.ci) end

  -- check args for numbers and put them into table
  for result in engine.filtertext(info.args, true, true):gmatch("%d+") do
    table.insert(dc_clientnums, tonumber(result));
  end
  if next(dc_clientnums) == nil then playermsg("Insert which clientnumber(s) to disconnect.", info.ci) return end

  -- only disconnect cn's which exist, don't disconnect yourself
  for i,cn in ipairs(dc_clientnums) do
    who = engine.getclientinfo(cn)
    if who and who.clientnum ~= info.ci.clientnum then
      engine.writelog(("disconnecting %s (%d) from %s"):format(who.name, who.clientnum, info.ci.name))
      engine.disconnect_client(who.clientnum, engine.DISC_MAXCLIENTS)
    else
      dc_invalid = true
    end
  end 

  if dc_invalid then 
    playermsg("At least one of the cn's you entered could not be disconnected.", info.ci)
    dc_invalid = false 
  end

  -- reset table
  for cn in pairs (dc_clientnums) do
    dc_clientnums[cn] = nil
  end

end, "#disconnect <cn> [<cn> <cn>...]: Disconnect player(s) <cn> sending the message 'server FULL'.")
