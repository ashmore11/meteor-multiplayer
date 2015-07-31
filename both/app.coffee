# Root path
@base_path = Meteor.absoluteUrl replaceLocalhost: true

# Timers
@_delay    = ( delay, func ) -> Meteor.setTimeout  func, delay
@_interval = ( delay, func ) -> Meteor.setInterval func, delay