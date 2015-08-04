###
Stream read / write rules
###
PlayerStream.permissions.write ( eventName ) -> return true
PlayerStream.permissions.read ( eventName )  -> return true

BulletStream.permissions.write ( eventName ) -> return true
BulletStream.permissions.read ( eventName )  -> return true

###
Listen for updates in the Players collection
###
Players.find().observeChanges

  added: ( id, doc ) ->

    PlayerStream.emit 'player:created', id, doc
  
  removed: ( id ) ->

    PlayerStream.emit 'player:destroyed', id

###
Listen for updates in the Bullets collection
###
Bullets.find().observeChanges
  
  added: ( id, doc ) ->

    BulletStream.emit 'bullet:created', id, doc

  removed: ( id ) ->

    BulletStream.emit 'bullet:destroyed', id