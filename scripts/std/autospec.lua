--[[

  The autospec module introduces the following:
  - Users are put to spec if they are in the (almost) exact same position after a predefined time 

]]--

local iterators = require("std.iterators");
local vec3 = require("utils.vec3");

local TIME_BETWEEN_CHECKS = 1000*35 -- how many milliseconds between each position check
local DELTA = 0.2 -- if the position difference between checks is lower than this value, put client to spec

-- Called every TIME_BETWEEN_CHECKS milliseconds.
local function updateClientPosition()
  if server.interm > 0 then return end
  for ci in iterators.players() do
        
    if not ci.extra.curPos then
      ci.extra.curPos = vec3()
    end
    
    local curVec = vec3(ci.state.o)
    local oldVec = vec3(ci.extra.curPos)
    
    if curVec:dist(oldVec) < DELTA then
      server.forcespectator(ci)
      engine.writelog(("autospec %d(%s)"):format(ci.clientnum, ci.name))
      server.sendservmsg("Server puts to spec " .. ci.name .. " for inactivity")
    end
    
    ci.extra.curPos = curVec
            
  end
end 

spaghetti.addhook("changemap",
  function(info)
    -- reset all players positions at map change
    for ci in iterators.players() do
      ci.extra.curPos = vec3()
    end
    spaghetti.latergame(TIME_BETWEEN_CHECKS, updateClientPosition, true)
  end
)


