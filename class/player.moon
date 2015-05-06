export class Player extends Physical
  new: (world, x, y, character, @playerNum) =>
    super world, x, y, 16, 16

    @filter = (other) =>
      --collide with walls and other players
      if other.__class == Wall or other.__class == Player
        return 'slide'

    @vx = 0
    @vy = 0

    @onGround = false
    @jumping = false
    @time = 0
    @won = false

    --tweak these!
    @gravity = 1500
    @quickFall = 3000
    @walkAcceleration = 1000
    @horizontalDrag = 500
    @horizontalMaxSpeed = 300
    @baseJumpPower = 450
    @additionalJumpPower = 100

    --animation stuff
    @animation =
      walk: animation[character].walk\clone!
      run: animation[character].run\clone!
      jump: animation[character].jump\clone!
    @facingDirection = 1
    @drawDepth = 100

    --signals
    game.signal.register 'player-walk', (playerNum, dt, v) ->
      if playerNum == @playerNum
        @walk dt, v
    game.signal.register 'player-jump', (playerNum) ->
      if playerNum == @playerNum
        @jump!
    game.signal.register 'player-end-jump', (playerNum) ->
      if playerNum == @playerNum
        @endJump!

  walk: (dt, v) =>
    @vx += v * @walkAcceleration * dt

  jump: =>
    if @onGround
      @vy = -@baseJumpPower - @additionalJumpPower * (math.abs(@vx) / @horizontalMaxSpeed)
      @jumping = true
      --@animation.jump\gotoFrame 2

  endJump: =>
    @jumping = false

  update: (dt) =>
    super dt

    --reset on ground status
    @onGround = false

    --horizontal drag
    if @vx < 0
      @vx += @horizontalDrag * dt
      if @vx > 0
        @vx = 0
    if @vx > 0
      @vx -= @horizontalDrag * dt
      if @vx < 0
        @vx = 0

    --limit horizontal speed
    @vx = lume.clamp @vx, -@horizontalMaxSpeed, @horizontalMaxSpeed

    --gravity
    if @vy < 0 and @jumping == false
      @vy += (@gravity + @quickFall) * dt
    else
      @vy += @gravity * dt

    --apply movement
    _, _, cols = @move @vx * dt, @vy * dt

    for col in *cols
      if col.other.__class == Wall or col.other.__class == Player
        --horizontal collisions
        if col.normal.x ~= 0
          @vx = 0
        --vertical collisions
        if col.normal.y ~= 0
          @vy = 0
          if col.normal.y < 0
            @onGround = true

    --check for win condition
    if (not @won) and @time >= 60
      @won = true
      game.signal.emit 'player-win', @playerNum

    --reset walking animation
    if math.abs(@vx) < 10
      @animation.walk\gotoFrame 1
      @animation.run\gotoFrame 1
    --face the right direction
    if math.abs(@vx) > 10
      @facingDirection = lume.sign @vx
    --falling animation
    if @vy > 0
      @animation.jump\gotoFrame 3

    --update animations
    @animation.walk\update dt * (math.abs(@vx) / @horizontalMaxSpeed) ^ .3
    @animation.run\update dt * (math.abs(@vx) / @horizontalMaxSpeed) ^ .3
    @animation.jump\update dt

  draw: =>
    x, y = @getCenter!
    with love.graphics
      .setColor 255, 255, 255, 255
      if @onGround
        --draw walking animation
        if math.abs(@vx) / @horizontalMaxSpeed > 0.6
          @animation.run\draw image.spritesheet, x, y - 7, 0, 1 * @facingDirection, 1, 16, 16
        else
          @animation.walk\draw image.spritesheet, x, y - 7, 0, 1 * @facingDirection, 1, 16, 16
      else
        --draw jumping animation
        @animation.jump\draw image.spritesheet, x, y - 7, 0, 1 * @facingDirection, 1, 16, 16

      --draw timer below player
      text = tostring @time
      if text\find '%.'
        text = text\match '(.*%.%d)'
      .setColor 255, 255, 255, 255
      .printCentered text, font.default, x, y + 16

  drawDebug: =>
    --draw hitbox
    if false
      x, y, w, h = @world\getRect self
      with love.graphics
        .setColor 255, 255, 255, 100
        .rectangle 'fill', x, y, w, h
