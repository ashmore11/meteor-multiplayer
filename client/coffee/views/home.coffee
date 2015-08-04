Template.home.helpers

  noUsername: ->

    return Players.find( 'username': Session.get('user') ).fetch().length < 1

  players: ->

    return Players.find {}, sort: health: -1

  bullets: ->

    return Bullets.find().count()

Template.home.events

  'keyup input': ( event ) ->

    if $('input').val().length >= 3
      $('button').removeClass 'disabled'
    else
      $('button').addClass 'disabled'

  'submit .username': ( event ) =>

    event.preventDefault()

    name       = event.target.text.value.toUpperCase()
    nameExists = Players.find( 'username': name ).fetch().length > 0

    if $('button').hasClass 'disabled'

      alert 'Your username must be at least 3 characters...'

    else

      if nameExists

        alert 'This name is already taken...'

      else

        Meteor.call 'createPlayer', name, randomColor( luminosity: 'bright' )

        Session.set 'user', name

Template.home.rendered = =>

  @scene = new Scene $ '#scene'

class Scene

  constructor: ( @el ) ->

    @stats = new Stats
    @stats.setMode( 0 )

    @stats.domElement.style.position = 'absolute'
    @stats.domElement.style.left = '0px'
    @stats.domElement.style.top = '0px'

    @renderer = new PIXI.WebGLRenderer 1500, 1000, antialias: true
    @stage    = new PIXI.Container

    @el.append @renderer.view
    @el.append @stats.domElement

    $( document ).on 'keydown keyup', @getKeyEvents
    $( document ).on 'mousemove', @getRotateAngle
    $( document ).on 'mousedown', @createBullet

    @addCurrentUsers()
    @createUsers()
    @removeUsers()
    @addBulletsToStage()
    @removeBulletsFromStage()
    @animate()

  getKeyEvents: ( event ) =>

    return unless @user

    event.preventDefault()

    if event.type is 'keydown'

      switch event.which

        when 87 then Session.set 'move:up',    true
        when 83 then Session.set 'move:down',  true
        when 65 then Session.set 'move:left',  true
        when 68 then Session.set 'move:right', true

    else

      switch event.which

        when 87 then Session.set 'move:up',    false
        when 83 then Session.set 'move:down',  false
        when 65 then Session.set 'move:left',  false
        when 68 then Session.set 'move:right', false

  getRotateAngle: ( event ) =>

    return unless @user

    pageX = event.pageX - @el.offset().left
    pageY = event.pageY - @el.offset().top

    x = pageX - @user.position.x
    y = pageY - @user.position.y

    angle   = Math.atan2( x, -y ) * ( 180 / Math.PI )
    radians = angle * Math.PI / 180

    Meteor.call 'updateRotation', @user._id, radians

  createUsers: ->

    PlayerStream.on 'player:created', ( id, doc ) =>

      @generatePlayer id, doc.username, doc.color

  removeUsers: ->

    PlayerStream.on 'player:destroyed', ( id ) =>

      object = @getObjectFromScene( id )

      return unless object

      object.removeChildren()
      @stage.removeChild object

  addCurrentUsers: ->

    for player in Players.find().fetch()

      id     = player._id
      name   = player.username
      color  = player.color
      health = player.health
      x      = player.position.x
      y      = player.position.y

      @generatePlayer id, name, color, health, x, y

  generatePlayer: ( id, name, color, health, x, y ) ->

    circle = new PIXI.Graphics
    circle.beginFill "0x#{color}", 1
    circle.drawCircle 0, 0, 20

    cannon = new PIXI.Graphics
    cannon.beginFill "0x#{color}", 1
    cannon.drawRect -2, 5, 6, -30
    cannon.type = 'cannon'

    name = new PIXI.Text name, font: '12px Oswald', fill: 'white'
    name.x = -( name.width / 2 )
    name.y = -50

    health = new PIXI.Text ( health or 100 ), font: '12px Oswald', fill: 'black'
    health.x = -( health.width / 2 )
    health.y = -( health.height / 2 )
    health.type = 'health'

    user       = new PIXI.Container
    user._id   = id
    user.type  = 'player'
    user.x     = x or 750
    user.y     = y or 500

    user.addChild circle
    user.addChild cannon
    user.addChild name
    user.addChild health

    @stage.addChild user

  updatePlayerPosition: ->

    return unless @user

    x = @user.position.x
    y = @user.position.y

    x -= 5 if Session.get 'move:left'
    y -= 5 if Session.get 'move:up'
    x += 5 if Session.get 'move:right'
    y += 5 if Session.get 'move:down'

    if x < 20 then x = 20
    if y < 20 then y = 20
    
    if x > @renderer.width  - 20 then x = @renderer.width  - 20
    if y > @renderer.height - 20 then y = @renderer.height - 20

    pos =
      x: x
      y: y

    Meteor.call 'updatePosition', @user._id, pos

  createBullet: ( event ) =>

    return unless @user

    event.preventDefault()

    pageX = event.pageX - @el.offset().left
    pageY = event.pageY - @el.offset().top
    pos   = @user.position

    angle   = Math.atan2( pageX - pos.x, - ( pageY - pos.y ) ) * ( 180 / Math.PI )
    radians = angle * Math.PI / 180
    speed   = 1500

    params =
      user : @user._id
      x    : @user.position.x
      y    : @user.position.y
      vx   : Math.cos( radians ) * speed / 60
      vy   : Math.sin( radians ) * speed / 60
      color: @user.color

    Meteor.call 'createBullet', params

  addBulletsToStage: ->

    BulletStream.on 'bullet:created', ( id, doc ) =>

      circle = new PIXI.Graphics

      circle.beginFill "0x#{doc.color}", 1
      circle.drawCircle 0, 0, 2

      bullet      = new PIXI.Container
      bullet.x    = doc.position.x
      bullet.y    = doc.position.y
      bullet._id  = id
      bullet.type = 'bullet'

      bullet.addChild circle
      @stage.addChild bullet

  removeBulletsFromStage: ->

    BulletStream.on 'bullet:destroyed', ( id ) =>

      object = @getObjectFromScene( id )

      return unless object

      object.removeChildren()
      @stage.removeChild object

  updateBullets: ->

    return unless @user

    px = @user.position.x
    py = @user.position.y

    for bullet in Bullets.find().fetch()

      x = bullet.position.x
      y = bullet.position.y

      if bullet.user is @user?._id

        x += bullet.direction.y
        y -= bullet.direction.x

        pos =
          x: x
          y: y

        Meteor.call 'updateBullets', bullet._id, pos

  updateObjectsOnStage: ->

    for object in @stage.children

      if object?.type is 'player'

        player = Players.findOne( _id: object._id )

        return unless player

        object.x = player.position.x
        object.y = player.position.y

        for child in object.children
          
          if child.type is 'cannon'
          
            child.rotation = player.rotation

          if child.type is 'health'

            child.text = player.health
            child.x    = -( child.width / 2 )
            child.y    = -( child.height / 2 )

      if object?.type is 'bullet'

        bullet = Bullets.findOne( _id: object._id )

        return unless bullet

        object.x = bullet.position.x
        object.y = bullet.position.y

  collisionDetection: ->

    return unless @user

    px = @user.position.x
    py = @user.position.y

    for bullet in Bullets.find().fetch()

      x = bullet.position.x
      y = bullet.position.y

      if bullet.user is @user?._id

        if x > 1500 or x < 0 or y > 1000 or y < 0

          # Remove any bullets that leave the clients ui
          Meteor.call 'removeBullet', bullet._id

      else

        if x > px - 20 and x < px + 20 and y > py - 20 and y < py + 20

          # Increase the health of the player who shot the bullet by 5
          Meteor.call 'increaseHealth', bullet.user

          # Decrease the health of the player who was shot by 10
          Meteor.call 'decreaseHealth', @user._id

          # Remove the bullet from the collection and clients ui
          Meteor.call 'removeBullet', bullet._id

          # Remove dead players from the collection and clients ui
          if @user.health <= 10

            Meteor.call 'removePlayer', @user._id

  getObjectFromScene: ( id ) ->

    for child in @stage.children

      if child._id is id

        return child

  update: ->

    @user = Players.findOne( username: Session.get 'user' )

    @updatePlayerPosition()

    @updateBullets()

    @updateObjectsOnStage()

    @collisionDetection()

  animate: ( time ) =>

    @stats.begin()

    @renderer.render @stage

    @update()

    @stats.end()

    requestAnimationFrame @animate
