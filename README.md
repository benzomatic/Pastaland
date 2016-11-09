#What is this?

This repo contains the Lua modules for the **Pastaland** Sauerbraten server:

* The *stats* module, to gather and show user statistics
* The *jokes* module, to send random jokes to the client
* The *autospec* module, to put non-moving clients to spec
* The *authloader* module, to load auth keys from an external file and allow adding keys in real time
* The *db* module, to connect to the Pastalandjs service to save and load players statistics
* The *mapbattle_gst* module, that provides a slightly modified version of the regular spaghettimod matbattle
* The *rename* module, to allow auth holders to change other players names
* The *disconnect* module, to free game slots
* The *pastanames* module, to rename unnamed players to a delicious variety of pasta.
* The *1000-gustavo-config* file, the actual server configuration.

###Building
* Nothing to build here. Get **spaghettimod** from here: https://github.com/pisto/spaghettimod 
* Build spaghettimod according to Pisto's instructions.

###Installing the modules
* Just copy or link (ln -s) the Pastaland modules respecting the paths shown in this repo: *stats.lua*, *autospec.lua*, *authloader.lua*, *db.lua*, *disconnect.lua*, *mapbattle_gst.lua*, *rename.lua* and *jokes.lua* go in script/std, *1000-gustavo-config.lua* goes into script/load.d, *gustavo.auth* contains the authkeys for players and goes in the var directory.

###Running
* Once copied or linked the modules, there's no need to rebuild. Just move to spaghettimod's root dir and launch *#GST=1 ./sauer_server*

##PastalandJs
PastalandJs is a service based on NodeJs that communicates via UDP with the Pastaland server. Currently it is used to save and load player statistics and connection info, persisted in a Sqlite database.
PastalandJs will also run a webserver on port 8082, serving the statistics saved in the database.

###Installing PastalandJs
* Install NodeJs. PastalandJs has been tested with NodeJs 5.9 but any version > 0.10 should be fine.
* Copy the *pastalandjs* folder and its content wherever you want in your server.
* Open a terminal in the *pastalandjs* folder and issue *npm install*. This will automatically resolve NodeJs dependencies.

###Running PastalandJs
The easiest way is opening a terminal in *pastalandjs* folder and issue *node index.js*, but the recommended way is by means of a process manager like Pm2: https://github.com/Unitech/pm2
Since the connection between Pastaland and PastalandJs is via UDP, there is actually no connection. This means that one can run with or without the other, with no problems whatsoever.
When running in local mode, you can access the rank pages from your browser at the address http://localhost:8082/rankbymatches.

###License
All the files in this repository are released under the Zlib license

Copyright (C) 2016 Loris Pederiva

  This software is provided 'as-is', without any express or implied
  warranty.  In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
     claim that you wrote the original software. If you use this software
     in a product, an acknowledgment in the product documentation would be
     appreciated but is not required.
  2. Altered source versions must be plainly marked as such, and must not be
     misrepresented as being the original software.
  3. This notice may not be removed or altered from any source distribution.
