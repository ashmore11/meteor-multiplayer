###
Stream read / write rules
###
PlayerStream.permissions.write ( eventName ) -> return true
PlayerStream.permissions.read ( eventName )  -> return true

BulletStream.permissions.write ( eventName ) -> return true
BulletStream.permissions.read ( eventName )  -> return true

###
Emit player position to all clients
###
PlayerStream.on 'client:send:position', ( id, pos ) ->

  PlayerStream.emit 'server:send:position', id, pos

###
Emit player rotation to all clients
###
PlayerStream.on 'client:send:rotation', ( id, rotation ) ->

  PlayerStream.emit 'server:send:rotation', id, rotation

###
Send bullets to all clients
###
BulletStream.on 'client:create:bullet', ( params ) ->

  BulletStream.emit 'server:create:bullet', params

###
Destroy bullet on all clients
###
BulletStream.on 'client:destroy:bullet', ( id ) ->

  BulletStream.emit 'server:destroy:bullet', id

###
Listen for updates in the Players collection
###
Players.find().observeChanges

  added: ( id, doc ) ->

    PlayerStream.emit 'player:created', id, doc
  
  removed: ( id ) ->

    PlayerStream.emit 'player:destroyed', id