###
Stream read / write rules
###
PlayerStream.permissions.write ( eventName ) -> return true
PlayerStream.permissions.read ( eventName )  -> return true

BulletStream.permissions.write ( eventName ) -> return true
BulletStream.permissions.read ( eventName )  -> return true

###
Create player
###
PlayerStream.on 'create:user', ( name ) ->

  Players.insert
    username : name
    position : x: 750, y: 500
    rotation : 0
    health   : 100

  id = Players.find( 'username': name ).fetch()[0]._id

  PlayerStream.emit 'user:created', id, name

###
Create bullet
###
BulletStream.on 'create:bullet', ( params ) ->

  Bullets.insert

    uid: params.uid

    position:
      x: params.x
      y: params.y

    direction:
      x: params.vx
      y: params.vy

Bullets.find().observeChanges
  
  added: ( id, doc ) ->

    BulletStream.emit 'bullet:created', id, doc