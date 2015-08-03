Template.home.helpers

  noUsername: ->

    return Players.find( 'username': Session.get('user') ).fetch().length < 1

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

        PlayerStream.emit 'create:user', name

        Session.set 'user', name

Template.home.rendered = =>

  @scene = new Scene $ '#scene'

class Scene

  constructor: ( @el ) ->

    @renderer = new PIXI.WebGLRenderer 1500, 1000, antialias: true
    @stage    = new PIXI.Container

    @el.append @renderer.view

    $( document ).on 'keydown keyup', @getKeyEvents
    $( document ).on 'mousemove', @getRotateAngle
    $( document ).on 'mousedown', @createBullet

    @addCurrentUsers()
    @createUsers()
    @addBulletsToStage()
    @animate()

  getKeyEvents: ( event ) =>

    user = Players.find( 'username': Session.get('user') ).fetch()[0]

    return unless user

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

  addCurrentUsers: ->

    for player in Players.find().fetch()

      id   = player._id
      name = player.username
      x    = player.position.x
      y    = player.position.y

      @generatePlayer id, name, x, y

  createUsers: =>

    PlayerStream.on 'user:created', ( id, name ) =>

      @generatePlayer id, name

  generatePlayer: ( id, name, x, y ) ->

    circle = new PIXI.Graphics
    circle.beginFill 0xFFCC00, 1
    circle.drawCircle 0, 0, 20

    cannon = new PIXI.Graphics
    cannon.beginFill 0xFFCC00, 1
    cannon.drawRect -2, 5, 6, -30
    cannon.type = 'cannon'

    text = new PIXI.Text name, font: '12px Oswald', fill: 'white'
    text.rotation = 0
    text.x = -( text.width / 2 )
    text.y = -50

    user      = new PIXI.Container
    user._id  = id
    user.type = 'player'

    if x and y

      user.x = x
      user.y = y

    user.addChild circle
    user.addChild cannon
    user.addChild text

    @stage.addChild user

  createBullet: ( event ) =>

    user = Players.find( 'username': Session.get('user') ).fetch()[0]

    return unless user

    event.preventDefault()

    pageX = event.pageX - @el.offset().left
    pageY = event.pageY - @el.offset().top
    pos   = user.position

    angle   = Math.atan2( pageX - pos.x, - ( pageY - pos.y ) ) * ( 180 / Math.PI )
    radians = angle * Math.PI / 180
    speed   = 500

    params =
      uid  : Random.id()
      x    : user.position.x
      y    : user.position.y
      vx   : Math.cos( radians ) * speed / 60
      vy   : Math.sin( radians ) * speed / 60

    BulletStream.emit 'create:bullet', params

  addBulletsToStage: ->

    BulletStream.on 'bullet:created', ( id, doc ) =>

      circle = new PIXI.Graphics

      circle.beginFill 0xFFCC00, 1
      circle.drawCircle 0, 0, 2

      bullet = new PIXI.Container

      bullet.x = doc.position.x
      bullet.y = doc.position.y

      bullet._id  = id
      bullet.type = 'bullet'

      bullet.addChild circle

      @stage.addChild bullet

  getRotateAngle: ( event ) =>

    user = Players.find( 'username': Session.get('user') ).fetch()[0]

    return unless user

    pageX = event.pageX - @el.offset().left
    pageY = event.pageY - @el.offset().top

    x = pageX - user.position.x
    y = pageY - user.position.y

    angle   = Math.atan2( x, -y ) * ( 180 / Math.PI )
    radians = angle * Math.PI / 180

    id = Players.find( 'username': Session.get('user') ).fetch()[0]._id

    Meteor.call 'updateRotation', id, radians

  updateUserPosition: ->

    user = Players.find( 'username': Session.get('user') ).fetch()[0]

    return unless user

    x = user.position.x
    y = user.position.y

    x -= 5 if Session.get 'move:left'
    y -= 5 if Session.get 'move:up'
    x += 5 if Session.get 'move:right'
    y += 5 if Session.get 'move:down'

    if x < 20   then x = 20
    if x > 1480 then x = 1480

    if y < 20  then y = 20
    if y > 980 then y = 980

    pos =
      x: x
      y: y

    Meteor.call 'updatePosition', user._id, pos

  updatePlayersAndBullets: ->

    for child in @stage.children

      if child?.type is 'player'

        player = Players.findOne( _id: child._id )

        if player

          child.x = player.position.x
          child.y = player.position.y

          for ch in child.children
            
            if ch.type is 'cannon'
            
              ch.rotation = player.rotation

      if child?.type is 'bullet'

        bullet = Bullets.findOne( _id: child._id )

        if bullet

          child.x += bullet.direction.y
          child.y -= bullet.direction.x

          if child.x > @renderer.width or child.x < 0 or child.y > @renderer.height or child.y < 0

            child.removeChildren()
            @stage.removeChild child

            Meteor.call 'removeBullet', child._id

  update: ->

    @updateUserPosition()
    @updatePlayersAndBullets()

  animate: =>

    requestAnimationFrame @animate

    @renderer.render @stage

    @update()
