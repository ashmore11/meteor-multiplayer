###
Stream read / write rules
###
PlayerStream.permissions.write ( eventName ) -> return true
PlayerStream.permissions.read ( eventName )  -> return true

BulletStream.permissions.write ( eventName ) -> return true
BulletStream.permissions.read ( eventName )  -> return true

randomColor = ->

  letters = '0123456789ABCDEF'.split ''
  color   = ''

  for i in [ 0...6 ]

    color += letters[ Math.floor( Math.random() * 16 ) ]

  return color

###
Create player
###
PlayerStream.on 'create:user', ( name ) ->

  color = randomColor()

  Players.insert
    username : name
    position : x: 750, y: 500
    rotation : 0
    color    : color
    health   : 100

  id = Players.find( 'username': name ).fetch()[0]._id

  PlayerStream.emit 'user:created', id, name, color

###
Create bullet
###
BulletStream.on 'create:bullet', ( params ) ->

  Bullets.insert

    uid: params.uid
    user: params.user
    color: params.color

    position:
      x: params.x
      y: params.y

    direction:
      x: params.vx
      y: params.vy

###
Listen for updates in the bullet collection
###
Bullets.find().observeChanges
  
  added: ( id, doc ) ->

    BulletStream.emit 'bullet:created', id, doc

###
Game loop for collision detection
###
_interval ( 1000 / 60 ), ->

  for bullet in Bullets.find().fetch()

    x = bullet.position.x
    y = bullet.position.y

    # Remove any bullets that leave the clients ui
    if x > 1500 or x < 0 or y > 1000 or y < 0

      BulletStream.emit 'destroy:bullet', bullet._id
      Bullets.remove bullet._id

    for user in Players.find().fetch()

      px = user.position.x
      py = user.position.y

      # Detect bullet / player collision
      if x > px - 20 and x < px + 20 and y > py - 20 and y < py + 20

        unless user._id is bullet.user

          # Increase the health of the player who shot the bullet by 5
          Players.update { _id: bullet.user }, { $inc: health: 5 }

          # Decrease the health of the player who was shot by 10
          Players.update { _id: user._id }, { $inc: health: -10 }

          # Remove the bullet from the collection and clients ui
          BulletStream.emit 'destroy:bullet', bullet._id
          Bullets.remove bullet._id

          # Remove dead players from the collection and clients ui
          if user.health <= 10

            PlayerStream.emit 'destroy:player', user._id
            Players.remove user._id