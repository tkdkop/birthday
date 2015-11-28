# TODO click on player

window.preferences =
    cutscene_1: false
    debug: true

# physics - Liam and Nina
# math - Katie
# bio - Naomi

class Player
    constructor: (name, game) ->
        _.bindAll @, 'menu', 'createPlayer'
        @game = game
        @name = name
        @game.load.spritesheet(name, "assets/#{name}-v1.1-sheet.png", 15, 32)

    createPlayer: (scale, x, y, distance, font) ->
        @distance = distance
        @player = @game.add.sprite(x, y, @name)
        @player.anchor.setTo(0.5, 0.5)
        @player.scale.setTo(scale, scale)
        @player.animations.add('walk', [1, 2], 5, true)
        @player.animations.add('talk', [0, 3], 2, true)
        @playerLeft = false
        @game.physics.arcade.enable @player
        #@game.physics.arcade.gravity.y = 250
        @player.body.gravity.y = 300
        @player.body.collideWorldBounds = true
        @text = @game.add.text(0,0, @name, font)
        @text.anchor.set(0.5)
        @text.alpha = 0
        @player.inputEnabled = true
        @player.events.onInputUp.add @menu
    
    menu: ->
        console.log " click #{@name}"

    update: (game, cursors, layers, p1) ->
        @player.body.velocity.x = 0;
        game.physics.arcade.collide @player, layers.collision       

        if cursors.right.isDown or cursors.left.isDown
            if cursors.left.isDown
                if @ != p1 
                    if @player.body.position.x - p1.player.body.position.x > @distance + 10
                        @player.body.velocity.x = -80
                else
                    @player.body.velocity.x = -80
                if !@playerLeft
                    @player.scale.x *= -1
                @playerLeft = true
            else
                if @ != p1
                    if @player.body.position.x - p1.player.body.position.x < -@distance
                        @player.body.velocity.x = 80
                else 
                    @player.body.velocity.x = 80
                if @playerLeft
                    @player.scale.x *= -1
                @playerLeft = false
            @player.animations.play 'walk'
        else if cursors.down.isDown
            @player.animations.play 'talk'
        else
            @player.animations.stop null, true
            @player.frame = 0
        @text.x = Math.floor(@player.x + @player.width / 2)
        @text.y = Math.floor(@player.y + @player.height / 2)
        
        if @player.input.pointerOver()
            @text.alpha = 1
        else
            @text.alpha = 0


class Game
    constructor: (Phaser) ->
        _.bindAll @, 'preload', 'create', 'create_object', 'update', 'render'
        @game = new Phaser.Game(800, 600, Phaser.AUTO, 'game-container', 
            {preload: @preload, create: @create, update: @update, render: @render}, 
                                null, false, false)
    
    preload: ->
        @player = new Player('keish', @game)
        @player_list = []
        @player_list.push new Player('red'  , @game)
        @player_list.push new Player('blue' , @game)
        @player_list.push new Player('green', @game)
        
        @game.load.image('tiles', 'tutorials/source/assets/images/tiles_spritesheet.png')
        @game.load.tilemap('level','tutorials/v2.json', null, Phaser.Tilemap.TILED_JSON)
 
    create_object: (obj) ->
        position = 
            x: obj.x + (@map.tileHeight / 2)
            y: obj.y - (@map.tileHeight / 2)
        
        data = [ '3333', '3333', '3333']
        @game.create.texture('solid', data)
        obstacle = @game.add.sprite(position.x, position.y, 'solid')
        @game.physics.enable obstacle
        obstacle.body.allowGravity = false
        return obstacle

    create: ->
        # start physics
        @game.physics.startSystem Phaser.Physics.P2JS

        # experimenting
        # @game.stage.backgroundColor = '#787878'
        @map = @game.add.tilemap 'level'
        @map.addTilesetImage 'tiles_spritesheet', 'tiles'
        # ogres are like onions... they have layers!
        @layers = {}
        @map.layers.forEach (layer) =>
            name = layer.name
            @layers[name] = @map.createLayer name
            if layer.properties.collision
                collision_tiles = []
                layer.data.forEach (row) =>
                    row.forEach (tile) =>
                        if tile.index > 0 and collision_tiles.indexOf(tile.index) == -1
                            collision_tiles.push tile.index
                @map.setCollision collision_tiles, true, name 
        @layers[@map.layer.name].resizeWorld()

        # add objects
        @obstacles = []
        for obj in @map.objects.objects
            obstacle = @create_object(obj)
            @obstacles.push obstacle
        console.log @obstacles
        # font
        font = 
            font: "12px Arial"
            fill: "#000000"
            wordWrap: true
            wordWrapWidth: 20
            align:"center"
        
        # player
        @player.createPlayer 1.5, 80, 250, 0, font
        x = 50
        dist = 10
        for i in [0...@player_list.length]
            @player_list[i].createPlayer(1, 80 - i*10, 260, dist + i*dist)
            
        @game.physics.arcade.gravity.y = 250
        @player.player.body.collideWorldBounds = true
        @game.camera.follow @player.player

        # Text background
        if window.preferences.cutscene_1
            data = [ '3333', '3333', '3333']
            @game.create.texture('solid', data, 200, 200)
            console.log "adding shit"
            @start_screen = @game.add.sprite(0, 0, 'solid')
            @game_state = "start"
            cutscene_font = 
                font: "24px Arial"
                fill: "#FFFFFF"
                align:"center"
            @start_text = @game.add.text( @game.world.centerX, @game.world.centerY, 
                'Once upon a time\n...', cutscene_font )

        # game_state: start, movement, obstacle
        if not @game_state?
            @game_state = "movement"

        # input
        @cursors = @game.input.keyboard.createCursorKeys()
        console.log "Game created"

    update: ->
        if @game_state == "start" and @game.input.mousePointer.isDown
            @start_screen.kill()
            @start_text.kill()
            @game_state = "movement"
        if @game_state == "obstacle"
            @game_state = "obstacle"
            for player in _.union @player_list, [@player]
                player.player.body.velocity.x = 0
                player.player.body.velocity.y = 0
                player.player.animations.stop null, true
                @game.physics.arcade.collide player.player, @layers.collision

            console.log "obstacle encountered"
        if @game_state == "movement"
            for player in _.union @player_list, [@player]
                player.update @game, @cursors, @layers, @player
            for obstacle in @obstacles
                @game.physics.arcade.collide( @player.player, obstacle, (=>console.log "collision"),
                    (=>
                        @game_state = "obstacle"
                        return false))
            
    render: ->
        # only for debugging, this can get removed from the game when completed
        if window.preferences.debug
            @game.debug.inputInfo(32, 32);

        

window.main =  =>
    new Game(Phaser)
