class @AppRouter

	Router.configure

		loadingTemplate  : 'loading'
		layoutTemplate   : 'layout'
		notFoundTemplate : '404'

		waitOn: ->
			
			Meteor.subscribe 'user'
			Meteor.subscribe 'users'
			Meteor.subscribe 'players'
			Meteor.subscribe 'bullets'

		onBeforeAction: ->

			if Meteor.userId()

				do @next

			else

				@redirect '/'

				do @next

	Router.map ->

		### 
		@ROUTE HOME
		###
		@route 'home',
			path: '/'
			
			action: ->
				
				return unless @ready()
				
				@render 'home'

					

