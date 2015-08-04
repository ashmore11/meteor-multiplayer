Meteor.methods

  createPlayer: ( name, color ) ->

    color = color.split('#')[1]

    Players.insert
      username : name
      position : x: 750, y: 500
      rotation : 0
      color    : color
      health   : 100

  updatePosition: ( id, pos ) ->

    @unblock()

    Players.update _id: id,

      $set: 
        
        position : pos

  updateRotation: ( id, angle ) ->

    @unblock()

    Players.update _id: id,

      $set: 
        
        rotation: angle

  createBullet: ( params ) ->

    Bullets.insert

      user: params.user
      color: params.color

      position:
        x: params.x
        y: params.y

      direction:
        x: params.vx
        y: params.vy

  updateBullets: ( id, pos ) ->

    @unblock()

    Bullets.update _id: id,

      $set: 
        
        position: pos

  removeBullet: ( id ) ->

    Bullets.remove id

  increaseHealth: ( id ) ->

    Players.update _id: id,

      $inc: 

        health: 5

  decreaseHealth: ( id ) ->

    Players.update _id: id,

      $inc: 

        health: -10

  removePlayer: ( id ) ->

    Players.remove id