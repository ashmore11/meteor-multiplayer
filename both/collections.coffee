@Players = new Meteor.Collection 'players'
@Bullets = new Meteor.Collection 'bullets'

Players.allow

  update: ( userId, doc, fields, modifier ) ->
    
    return true

Bullets.allow

  update: ( userId, doc, fields, modifier ) ->
    
    return true