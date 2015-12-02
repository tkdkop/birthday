# TODO click on player

window.preferences =
    cutscene_1: false
    debug: true

# physics - Liam and Nina
# math - Katie
# bio - Miranda

window.requirements = {
    obstacle1: {
        users: ['miranda']
        sub: 'bio'
    }
    obstacle2: {
        users: ['liam', 'nina']
        sub: 'physics'
    }
}

class Player
    constructor: (name, game, width) ->
        _.bindAll @, 'menu', 'createPlayer'
        @game = game
        @name = name
        @game.load.spritesheet(name, "assets/#{name}.png", width, 25) # width, height
        # font
        @font =
            font: "16px Arial"
            fill: "#000000"
            wordWrap: true
            wordWrapWidth: 200
            align:"center"


    createPlayer: (scale, x, y, distance) ->
        @distance = distance
        @player = @game.add.sprite(x, y, @name)
        @player.anchor.setTo(0.5, 0.5)
        @player.scale.setTo(scale, scale)
        @player.animations.add('walk', [1, 2], 5, true)
#        @player.animations.add('talk', [0, 3], 2, true)
        @playerLeft = false
        @game.physics.arcade.enable @player
        #@game.physics.arcade.gravity.y = 250
        @player.body.gravity.y = 300
        @player.body.collideWorldBounds = true

        @subjects = ['math', 'physics', 'bio']
        @buttons = []
        @button_texts = []
        for sub in @subjects
            button = @game.add.button(0,0, 'button', @buttonClick, @, 1,0,2)
            button.params = {name: @name, sub:sub}
            button.anchor.set(0.5, 0.5)
            button.visible = false
            @buttons.push(button)
            button_text = @game.add.text(0,0, sub, @font)
            button_text.anchor.set(0.5, 0.4)
            button_text.visible = false
            @button_texts.push(button_text)
        title = @game.add.text(0,0, "#{@name} used:", @font)
        title.anchor.set(0.5, 0.4)
        title.visible = false
        @button_texts.push(title)

        @text = @game.add.text(0,0, @name, @font)
        @text.anchor.set(0.5, 0.5)
        @text.alpha = 0
        @player.inputEnabled = true
        @player.events.onInputUp.add @menu

    buttonClick: (button) ->
        console.log button.params.name
        console.log button.params.sub
        for b in @buttons
            b.visible = false
        for button_text in @button_texts
            button_text.visible = false
        @game.button_visible = false
        # obstacle passing
        req = window.requirements[@game.cur_obstacle]
        console.log button.params.sub, req.sub, req.users, button.params.name
        if button.params.sub == req.sub and _.contains(req.users, button.params.name)
            req.users = _.without(req.users, button.params.name)
            if _.isEmpty(req.users)
                @game.game_state = 'movement'
            # todo handle multiple
        # todo handle errors


    menu: ->
        if @game.button_visible or @name == 'keish'
            return
        pos = {}
        pos.x = Math.floor(@player.x + @player.width / 2)
        pos.y = Math.floor(@player.y + @player.height / 2)
        delta = 20
        initial = 40
        for button in @buttons
            button.x = pos.x
            button.y = pos.y - initial
            button.visible = true
            initial += delta
        initial = 40
        for button_text in @button_texts
            button_text.x = pos.x
            button_text.y = pos.y - initial
            button_text.visible = true
            initial += delta
        @game.button_visible = true

    update: (game, cursors, layers, p1) ->
        @player.body.velocity.x = 0;
        game.physics.arcade.collide @player, layers.collision       

        if (cursors.right.isDown or cursors.left.isDown) and @game.game_state == "movement"
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
        @text.y = Math.floor(@player.y + @player.height / 2 + 10)
        
        if @player.input.pointerOver()
            @text.alpha = 1
        else
            @text.alpha = 0


class Game
    constructor: (Phaser) ->
        _.bindAll @, 'preload', 'create', 'create_object', 'update', 'render', 'collide_with_obstacle'
        @game = new Phaser.Game(800, 600, Phaser.AUTO, 'game-container', 
            {preload: @preload, create: @create, update: @update, render: @render}, 
                                null, false, false)
    
    preload: ->
        # katie - 22x25, nina - 19x25, miranda - 20x25, others - 17x25
        @player = new Player('keish', @game, 17)
        @player_list = []
        @player_list.push new Player('nina'  , @game, 19)
        @player_list.push new Player('liam' , @game, 17)
        @player_list.push new Player('miranda', @game, 20)
        @player_list.push new Player('katie', @game, 22)

        @game.load.image('tiles', 'tutorials/source/assets/images/tiles_spritesheet.png')
        @game.load.tilemap('level','tutorials/v2.json', null, Phaser.Tilemap.TILED_JSON)
        @game.load.spritesheet('button', 'assets/flixel-button.png',80, 20)
 
    create_object: (obj) ->
        position =
            x: obj.x + (@map.tileHeight / 2)
            y: obj.y - (@map.tileHeight / 2)
        
        data = [ '3333', '3333', '3333']
        @game.create.texture('solid', data)
        obstacle = @game.add.sprite(position.x, position.y, 'solid')
        obstacle.name = obj.name
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

        # player
        @player.createPlayer 1.5, 80, 250, 0
        x = 50
        dist = 20
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
            @game.game_state = "start"
            cutscene_font = 
                font: "24px Arial"
                fill: "#FFFFFF"
                align:"center"
            @start_text = @game.add.text( @game.world.centerX, @game.world.centerY, 
                'Once upon a time\n...', cutscene_font )

        # game_state: start, movement, obstacle
        if not @game.game_state?
            @game.game_state = "movement"

        # input
        @cursors = @game.input.keyboard.createCursorKeys()
        console.log "Game created"

    update: ->
        if @game.game_state == "start" and @game.input.mousePointer.isDown
            @start_screen.kill()
            @start_text.kill()
            @game.game_state = "movement"
        else
            for player in _.union @player_list, [@player]
                player.update @game, @cursors, @layers, @player
            for obstacle in @obstacles
                @game.physics.arcade.collide( @player.player, obstacle, (=>console.log "collision"),
                    (=>
                        @collide_with_obstacle(obstacle)
                        return false))

    collide_with_obstacle: (obstacle) ->
        @game.game_state = 'obstacle'
        console.log "obstacle #{obstacle.name}"
        @game.cur_obstacle = obstacle.name
        @obstacles = _.without(@obstacles, obstacle)


    render: ->
        # only for debugging, this can get removed from the game when completed
        if window.preferences.debug
            @game.debug.inputInfo(32, 32);

        

window.main =  =>
    new Game(Phaser)
