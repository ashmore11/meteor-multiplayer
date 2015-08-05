Template.home.helpers

  noUsername: ->

    return Players.find( username: Session.get('user') ).count() < 1

  players: ->

    return Players.find {}, sort: health: -1

  health: ->

    return Players.findOne( username: Session.get('user') )?.health

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

        color = randomColor( luminosity: 'light' )
        color = color.split('#')[1]

        Meteor.call 'createPlayer', name, color

        Session.set 'user', name

Template.home.rendered = =>

  @scene = new Scene $ '#scene'

class Scene

  win:
    w: $(window).width()
    h: $(window).height()

  constructor: ( @el ) ->

    @renderer = new PIXI.WebGLRenderer @win.w, @win.h, antialias: true
    @stage    = new PIXI.Container

    @renderer.resize @win.w, @win.h

    @el.append @renderer.view

    $( document ).on 'keydown keyup', @getKeyEvents
    $( document ).on 'mousemove', @getRotateAngle
    $( document ).on 'mousedown', @createBullet
    $(  window  ).on 'resize', @resize

    @createStats()
    @addCurrentUsers()
    @createUsers()
    @removeUsers()
    @addBulletsToStage()
    @removeBulletsFromStage()
    @updatePlayersPosition()
    @updatePlayersRotation()
    @animate()

  createStats: ->

    @stats = new Stats
    @stats.setMode( 0 )

    @stats.domElement.style.position = 'absolute'
    @stats.domElement.style.left     = '0px'
    @stats.domElement.style.top      = '0px'

    @el.append @stats.domElement

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

    x = event.pageX - @player.x
    y = event.pageY - @player.y

    angle    = Math.atan2( x, -y ) * ( 180 / Math.PI )
    rotation = angle * Math.PI / 180

    PlayerStream.emit 'client:send:rotation', @user._id, rotation

  createUsers: ->

    PlayerStream.on 'player:created', ( id, doc ) =>

      @generatePlayer id, doc.username, doc.color

  removeUsers: ->

    PlayerStream.on 'player:destroyed', ( id ) =>

      object = @getObjectFromStage( id )

      object.removeChildren()
      @stage.removeChild object

  addCurrentUsers: ->

    for player in Players.find().fetch()

      id     = player._id
      name   = player.username
      color  = player.color
      health = player.health

      @generatePlayer id, name, color, health

  generatePlayer: ( id, name, color, health ) ->

    circle = new PIXI.Graphics
    circle.beginFill "0x#{color}", 1
    circle.drawCircle 0, 0, 20

    cannon = new PIXI.Graphics
    cannon.beginFill "0x#{color}", 1
    cannon.drawRect -2, 5, 6, -30
    cannon.type = 'cannon'

    name   = new PIXI.Text name, font: '14px Avenir Next Condensed', fill: 'white'
    name.x = -( name.width / 2 )
    name.y = -45

    health      = new PIXI.Text ( health or 100 ), font: '14px Avenir Next Condensed', fill: 'black'
    health.x    = -( health.width / 2 )
    health.y    = -( health.height / 2 )
    health.type = 'health'

    user      = new PIXI.Container
    user._id  = id
    user.type = 'player'
    user.x    = @renderer.width / 2
    user.y    = @renderer.height / 2

    user.addChild circle
    user.addChild cannon
    user.addChild name
    user.addChild health

    @stage.addChild user

  updatePosition: ->

    return unless @player

    speed = 7.5

    x = @player.x
    y = @player.y

    x -= speed if Session.get 'move:left'
    y -= speed if Session.get 'move:up'
    x += speed if Session.get 'move:right'
    y += speed if Session.get 'move:down'

    if x < 20 then x = 20
    if y < 20 then y = 20
    
    if x > @renderer.width  - 20 then x = @renderer.width  - 20
    if y > @renderer.height - 20 then y = @renderer.height - 20

    pos =
      x: x / @win.w * 100
      y: y / @win.h * 100

    PlayerStream.emit 'client:send:position', @user._id, pos

  updatePlayersPosition: ->

    PlayerStream.on 'server:send:position', ( id, pos ) =>

      player = @getObjectFromStage( id )

      return unless player

      player.x = pos.x * @win.w / 100
      player.y = pos.y * @win.h / 100

  updatePlayersRotation: ->

    PlayerStream.on 'server:send:rotation', ( id, rotation ) =>

      player = @getObjectFromStage( id )

      return unless player

      for child in player.children

        if child.type is 'cannon'

          child.rotation = rotation

  createBullet: ( event ) =>

    return unless @player

    event.preventDefault()

    params =
      _id   : Random.id()
      user  : @user._id
      mx    : event.pageX / @win.w * 100
      my    : event.pageY / @win.h * 100
      x     : @player.x / @win.w * 100
      y     : @player.y / @win.h * 100
      color : @user.color

    BulletStream.emit 'client:create:bullet', params

  addBulletsToStage: ->

    BulletStream.on 'server:create:bullet', ( params ) =>

      circle = new PIXI.Graphics

      circle.beginFill "0x#{params.color}", 1
      circle.drawCircle 0, 0, 2

      bullet      = new PIXI.Container
      bullet._id  = params._id
      bullet.user = params.user
      bullet.type = 'bullet'

      bullet.x  = params.x  * @win.w / 100
      bullet.y  = params.y  * @win.h / 100
      bullet.mx = params.mx * @win.w / 100
      bullet.my = params.my * @win.h / 100

      x =  ( bullet.mx - bullet.x )
      y = -( bullet.my - bullet.y )

      angle   = Math.atan2( x, y ) * ( 180 / Math.PI )
      radians = angle * Math.PI / 180

      width  = @win.h * @win.w / ( @win.h * 100 )
      height = @win.w * @win.h / ( @win.w * 100 )
      speed  = ( width + height ) / 2

      bullet.direction =
        x: Math.cos( radians ) * speed
        y: Math.sin( radians ) * speed

      bullet.addChild circle
      @stage.addChild bullet

  removeBulletsFromStage: ->

    BulletStream.on 'server:destroy:bullet', ( id ) =>

      object = @getObjectFromStage( id )

      return unless object

      object.removeChildren()
      @stage.removeChild object

  updateBullets: ->

    for object in @stage.children

      if object.type is 'bullet'

        object.x += object.direction.y
        object.y -= object.direction.x

  updatePlayersHealth: ->

    for object in @stage.children

      if object.type is 'player'

        player = Players.findOne( _id: object._id )

        return unless player

        for child in object.children

          if child.type is 'health'

            child.text = player.health
            child.x = -( child.width / 2 )
            child.y = -( child.height / 2 )

  collisionDetection: ->

    return unless @player

    px = @player.x
    py = @player.y

    for object in @stage.children

      if object?.type is 'bullet'

        ox = object.x
        oy = object.y

        # Dont check for collision if bullet belongs to @user
        unless object.user is @user._id

          if ox > px - 20 and ox < px + 20 and oy > py - 20 and oy < py + 20

            # Remove bullet from the clients ui
            BulletStream.emit 'client:destroy:bullet', object._id

            # Increase health of the player who shot the bullet by 5
            Meteor.call 'increaseHealth', object.user

            # Decrease health of the player who was shot by 10
            Meteor.call 'decreaseHealth', @user._id

        else

          # Remove any bullets that leave the clients ui
          if ox > @renderer.width or ox < 0 or oy > @renderer.height or oy < 0

            BulletStream.emit 'client:destroy:bullet', object._id

  removeDeadPlayer: ->

    return unless @user

    if @user.health <= 0

      Meteor.call 'removePlayer', @user._id

  getObjectFromStage: ( id ) ->

    for child in @stage.children

      if child._id is id

        return child

  resize: =>

    @renderer.resize @win.w, @win.h

    console.log 'resizing'

  update: ->

    @user   = Players.findOne( username: Session.get 'user' )
    @player = @getObjectFromStage( @user?._id )

    @updatePosition()

    @updateBullets()

    @updatePlayersHealth()

    @collisionDetection()

    @removeDeadPlayer()

  animate: =>

    @stats.begin()

    @renderer.render @stage

    @update()

    @stats.end()

    requestAnimationFrame @animate
