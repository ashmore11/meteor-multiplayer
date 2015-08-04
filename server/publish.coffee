Meteor.publish 'players', -> return Players.find()
Meteor.publish 'bullets', -> return Bullets.find()