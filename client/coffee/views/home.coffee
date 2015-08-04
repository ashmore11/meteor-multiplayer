Template.home.helpers

  noUsername: ->

    return Players.find( username: Session.get('user') ).count() < 1

  players: ->

    return Players.find {}, sort: health: -1

  bullets: ->

    return Bullets.find().count()

  health: ->

    return Players.findOne( username: Session.get('user') ).health

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

        color = randomColor( luminosity: 'bright' )
        color = color.split('#')[1]

        Meteor.call 'createPlayer', name, color

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

    PIXI.RESOLUTION = window.devicePixelRatio

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

      object = @getObjectFromStage( id )

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
    user.x    = x or @renderer.width / 2
    user.y    = y or @renderer.height / 2

    user.addChild circle
    user.addChild cannon
    user.addChild name
    user.addChild health

    @stage.addChild user

  updatePlayerPosition: ->

    return unless @user

    speed = 7.5

    x = @user.position.x
    y = @user.position.y

    x -= speed if Session.get 'move:left'
    y -= speed if Session.get 'move:up'
    x += speed if Session.get 'move:right'
    y += speed if Session.get 'move:down'

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
    speed   = 1000

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
      bullet.user = doc.user
      bullet.type = 'bullet'

      bullet.direction =
        x: doc.direction.x
        y: doc.direction.y

      bullet.addChild circle
      @stage.addChild bullet

  removeBulletsFromStage: ->

    BulletStream.on 'bullet:destroyed', ( id ) =>

      object = @getObjectFromStage( id )

      return unless object

      object.removeChildren()
      @stage.removeChild object

  updateBullets: ->

    for object in @stage.children

      if object.type is 'bullet'

        object.x = object.x + object.direction.y
        object.y = object.y - object.direction.x

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
            child.x = -( child.width / 2 )
            child.y = -( child.height / 2 )

  collisionDetection: ->

    return unless @user

    px = @user.position.x
    py = @user.position.y

    for object in @stage.children

      if object.type is 'bullet'

        ox = object.x
        oy = object.y

        # Dont check for collision if bullet belongs to @user
        unless object.user is @user._id

          if ox > px - 20 and ox < px + 20 and oy > py - 20 and oy < py + 20

            # Increase the health of the player who shot the bullet by 5
            Meteor.call 'increaseHealth', object.user

            # Decrease the health of the player who was shot by 10
            Meteor.call 'decreaseHealth', @user._id

            # Remove the bullet from the collection and clients ui
            Meteor.call 'removeBullet', object._id

        else

          # Remove any bullets that leave the clients ui
          if ox > @renderer.width or ox < 0 or oy > @renderer.height or oy < 0

            Meteor.call 'removeBullet', object._id

  removeDeadPlayer: ->

    return unless @user

    if @user.health <= 0

      Meteor.call 'removePlayer', @user._id

  getObjectFromStage: ( id ) ->

    for child in @stage.children

      if child._id is id

        return child

  update: ->

    @user = Players.findOne( username: Session.get 'user' )

    @updatePlayerPosition()

    @updateBullets()

    @updateObjectsOnStage()

    @collisionDetection()

    @removeDeadPlayer()

  animate: =>

    @stats.begin()

    @renderer.render @stage

    @update()

    @stats.end()

    requestAnimationFrame @animate
