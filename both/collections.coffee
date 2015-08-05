@Players = new Meteor.Collection 'players'

Players.allow

  update: ( userId, doc, fields, modifier ) ->
    
    return true