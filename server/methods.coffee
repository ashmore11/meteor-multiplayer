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