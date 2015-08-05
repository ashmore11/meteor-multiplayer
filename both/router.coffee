class @AppRouter

	Router.configure

		loadingTemplate  : 'loading'
		layoutTemplate   : 'layout'
		notFoundTemplate : '404'

		waitOn: ->
			
			Meteor.subscribe 'players'

	Router.map ->

		@route 'home',
			path: '/'
			
			action: ->
				
				return unless @ready()
				
				@render 'home'

					

