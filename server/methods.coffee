Meteor.methods

  updatePosition: ( id, pos ) ->

    Players.update _id: id,

      $set: 
        
        position : pos

  updateRotation: ( id, angle ) ->

    Players.update _id: id,

      $set: 
        
        rotation: angle

  updateBullets: ( id, pos ) ->

    Bullets.update _id: id,

      $set: 
        
        position: pos

  removeBullet: ( id ) ->

    Bullets.remove id