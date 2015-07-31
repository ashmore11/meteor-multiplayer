Meteor.publish 'user',    -> return Meteor.users.find @userId
Meteor.publish 'users',   -> return Meteor.users.find {}, fields: profile: 1
Meteor.publish 'players', -> return Players.find()
Meteor.publish 'bullets', -> return Bullets.find()