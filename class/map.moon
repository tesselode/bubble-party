export class Map extends Common
  new: (levelname) =>
    @world = bump.newWorld!
    @player = {}

    --load level
    for line in love.filesystem.lines 'level/'..levelname..'.oel'
      if line\find '<rect'
        x = tonumber line\match 'x="(.-)"'
        y = tonumber line\match 'y="(.-)"'
        w = tonumber line\match 'w="(.-)"'
        h = tonumber line\match 'h="(.-)"'
        Wall @world, x, y, w, h
      elseif line\find '<Player'
        x = tonumber line\match 'x="(.-)"'
        y = tonumber line\match 'y="(.-)"'
        table.insert @player, Player @world, x, y, #@player + 1
      elseif line\find '<Bubble'
        x = tonumber line\match 'x="(.-)"'
        y = tonumber line\match 'y="(.-)"'
        @bubble = Bubble @world, x, y

    --"load tiles"
    if love.filesystem.exists 'level/'..levelname..'.png'
      @environment = love.graphics.newImage 'level/'..levelname..'.png'

  update: (dt) =>
    for item in *@world\getItems!
      item\update dt

  clearSignals: =>
    for item in *@world\getItems!
      item\clearSignals!

  draw: =>
    --draw tiles
    with love.graphics
      .setColor 150, 150, 150, 255
      --.rectangle 'fill', 0, 0, WIDTH, HEIGHT
      .setColor 255, 255, 255, 255
      .draw @environment if @environment

    --draw all physical objects
    items = @world\getItems!
    table.sort items, (a, b) -> return a.drawDepth < b.drawDepth
    for item in *items
      item\draw!
      --item\drawDebug!
