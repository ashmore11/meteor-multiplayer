Meteor.methods

  createPlayer: ( name, color ) ->

    Players.insert

      username : name
      position : x: 750, y: 500
      rotation : 0
      color    : color
      health   : 100

  removePlayer: ( id ) ->

    Players.remove id

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

  increaseHealth: ( id ) ->

    Players.update _id: id,

      $inc: 

        health: 5

  decreaseHealth: ( id ) ->

    Players.update _id: id,

      $inc: 

        health: -10

  createBullet: ( params ) ->

    Bullets.insert

      user : params.user
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