
window.preferences =
    cutscene_1: true
    debug: false

# physics - Liam and Nina
# math - Katie
# bio - Miranda

window.game_over_text = ["Keish and her students found Log trapped in the Luddite castle. "+
  " They rescued him and snuck away.",
  "The students were given the rest of the day off, and Log and Keish lived together happily ever after.",
  "Happy Birthday Keisha!"
]

window.requirements = {
    obstacle1: {
        users: ['miranda']
        sub: 'bio'
        sprite: 'spider'
        kill: true
        scale: 1
        problem_text: 'Oh no, there\'s a spider blocking the path\nClick on a student to come up with a solution'
        finish_text: 'Miranda remembers hearing from bio class that many animals are afraid of smoke. '+
          'She lights a fire with some wet leaves to create smoke and scare the spider away.'
        # add success / fail callbacks here
    }
    obstacle2: {
        users:['katie']
        sub:'math'
        sprite: 'old_guy'
        scale: 2
        problem_text: 'This man needs help building a fence, but he wants to use his resources as efficiently as possible'
        finish_text_list: ['Katie uses her math skills to prove that a regular n-sided polygon has the largest area to '+
          'perimeter ratio.',  'She also proves that more sides also improves the ratio. She teaches the man that '+
          'building a circular fence will allow him to fence the largest area using the fewest resources.',
          'The man is thankful for their help and wishes them well on the rest of their journey']
    }
    obstacle3: {
        users: ['liam', 'nina']
        sub: 'physics'
        sprite: 'gear'
        additional: 'bridge'
        scale: 2
        problem_text: 'We need to find some way to cross this bridge'
        finish_text_list: ['Liam and Nina work together to determine how to get the bridge down.',
            'They tie two rocks together with a string. Nina calculates the vectors needed to hit the gear ' +
            'across the chasm, while Liam calculates the momentum the rocks must have to cause the bridge to lower',
            'Together they lower the bridge and the crew can continue their quest.'
        ]
    }
}

window.cutscene_font =
    font: "24px Arial"
    fill: "#FFFFFF"
    wordWrap: true
    wordWrapWidth: 600
    align:"center"

class Player
    constructor: (name, game, width) ->
        _.bindAll @, 'menu', 'createPlayer'
        @game = game
        @name = name
        @game.load.spritesheet(name, "/birthday/assets/#{name}.png", width, 25) # width, height
        # font
        @font =
            font: "16px Arial"
            fill: "#000000"
            wordWrap: true
            wordWrapWidth: 200
            align:"center"


    createPlayer: (scale, x, y, distance) ->
        @initial_y = y
        console.log window.preferences
        if window.preferences.debug
            console.log x
            x += 1100
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
        if button.params.sub == req.sub
            if _.contains(req.users, button.params.name)
                req.users = _.without(req.users, button.params.name)
                if _.isEmpty(req.users)
                    # great success!
                    @game.cur_obstacle_text.kill()
                    if req.finish_callback?
                        req.finish_callback()
                    if req.finish_text_list?
                        @game.multiscene(req.finish_text_list)
                    else
                        @game.cutscene(req.finish_text)

                else
                    @game.log("I don't think #{button.params.name} can do this alone")
            else
                @game.log("#{button.params.name} isn't strong enough at #{button.params.sub} to solve this problem")
        else
            @game.log("This doesn't look like a #{button.params.sub} problem")

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
        if @player.body.x > 1920 and !@game.game_end?
            @game.multiscene(window.game_over_text)
            @game.game_end = true
            return
        @player.body.velocity.x = 0;
        game.physics.arcade.collide @player, layers.collision       

        if (cursors.right.isDown or cursors.left.isDown) and @game.game_state == @game.const.movement
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
        @game = new Phaser.Game(800, 525, Phaser.AUTO, 'game-container',
            {preload: @preload, create: @create, update: @update, render: @render}, 
                                null, false, false)

        _.bind(@log, @game)
        _.bind(@cutscene, @game)
        _.bind(@multiscene, @game)
        @game.log = @log
        @game.cutscene = @cutscene
        @game.multiscene = @multiscene
        @game.const = {}
        @game.const.movement = "movement"
        @game.const.obstacle = "obstacle"
        @game.const.cutscene = "cutscene"
        @game.const.multiscene = "multiscene"
        @game.const.end = "end"
        @input_timeout = false

    preload: ->
        # katie - 22x25, nina - 19x25, miranda - 20x25, others - 17x25
        @player = new Player('keish', @game, 17)
        @player_list = []
        @player_list.push new Player('nina'  , @game, 19)
        @player_list.push new Player('liam' , @game, 17)
        @player_list.push new Player('miranda', @game, 20)
        @player_list.push new Player('katie', @game, 22)

        @game.load.image('tiles', '/birthday/tutorials/source/assets/images/tiles_spritesheet.png')
        @game.load.tilemap('level','/birthday/tutorials/v2.json', null, Phaser.Tilemap.TILED_JSON)
        @game.load.spritesheet('button', '/birthday/assets/flixel-button.png',80, 20)
        @game.load.image('spider','/birthday/assets/bio1.png')
        @game.load.image('old_guy', '/birthday/assets/old-guy.png')
        @game.load.image('gear','/birthday/assets/gear.png')
        @game.load.image('bridge', '/birthday/assets/bridge.png')
        @game.load.image('castle','/birthday/assets/castle.gif')
 
    create_object: (obj) ->
        if window.preferences.debug
            if obj.name == 'obstacle1' or obj.name == 'obstacle2'
                return
        position =
            x: obj.x + (@map.tileHeight / 2)
            y: obj.y - (@map.tileHeight / 2)
        ob_info = window.requirements[obj.name]
        # bridge only
        if ob_info.additional?
            raised_bridge = @game.add.sprite(position.x+60, position.y-28, ob_info.additional)
            raised_bridge.scale.setTo(3,3)
            raised_bridge.rotation = Math.PI/2
            lowered_bridge = @game.add.sprite(position.x-10, position.y+45, ob_info.additional)
            lowered_bridge.scale.setTo(3,3)
            lowered_bridge.visible = false
            ob_info.finish_callback = =>
                raised_bridge.kill()
                lowered_bridge.visible = true


        obstacle = @game.add.sprite(position.x, position.y, ob_info.sprite)
        obstacle.name = obj.name
        obstacle.scale.setTo(ob_info.scale, ob_info.scale)
        if ob_info.kill?
            ob_info.finish_callback = =>
                obstacle.kill()
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

        c = @game.add.sprite(1800,42, 'castle')
        c.scale.set(0.5, 0.5)

        # player
        @player.createPlayer 1.5, 80, 244, 0
        x = 50
        dist = 20
        for i in [0...@player_list.length]
            @player_list[i].createPlayer(1, 80 - i*10, 255, dist + i*dist)
            
        @game.physics.arcade.gravity.y = 250
        @player.player.body.collideWorldBounds = true
        @game.camera.follow @player.player

        # Text background
        if window.preferences.cutscene_1
            @game.multiscene([
                '(Click to continue)\n' +
                'Once upon a time there was a teacher named Keish. ' +
                'One day she had her boyfriend, Log, in to teach her kids computer ' +
                'science.',
                'Everything was going great until suddenly an evil Luddite mob broke in to the classroom. ',
                'The Luddites kidnapped Log in protest of computer science and all technology.',
                'Four brave students volunteered to help Keish rescue Log. She assigned the rest '+
                'practice problems to do while she was away.',
                'With that she rushed off with her students to ' +
                'find Log and save the day...\n(Use the arrows to move)'
            ])


        # game_state: start, movement, obstacle
        if not @game.game_state?
            @game.game_state = @game.const.movement

        # input
        @cursors = @game.input.keyboard.createCursorKeys()
        console.log "Game created"

    update: ->
        if (@game.game_state == @game.const.cutscene or @game.game_state == @game.const.multiscene or
          @game.game_end?) and @game.input.mousePointer.isDown
            if @input_timeout
                return
            else
                @input_timeout = true
                setTimeout((=>@input_timeout = false), 1000)

            @game.cutscene_screen.kill()
            @game.cutscene_text.kill()
            if @game.game_state == @game.const.cutscene
                @game.game_state = @game.const.movement
            else
                @game.multiscene(@game.multiscene_text_list)
        else
            for player in _.union @player_list, [@player]
                player.update @game, @cursors, @layers, @player
            for obstacle in @obstacles
                @game.physics.arcade.collide( @player.player, obstacle, (=>console.log "collision"),
                    (=>
                        @collide_with_obstacle(obstacle)
                        return false))
        for player in _.union(@player_list, [@player])
            player.player.body.y = player.initial_y

    collide_with_obstacle: (obstacle) ->
        @game.game_state = @game.const.obstacle
        @game.cur_obstacle = obstacle.name
        ob_info = window.requirements[obstacle.name]
        push_down = '\n\n\n\n\n'
        t = @game.log(push_down+ob_info.problem_text, {}, false)
        @game.cur_obstacle_text = t
        @obstacles = _.without(@obstacles, obstacle)


    render: ->
        # only for debugging, this can get removed from the game when completed
        if window.preferences.debug
            @game.debug.inputInfo(32, 32);

    log: (text, font_changes = {fill:'#000'}, exit=true) ->
        new_font = {}
        _.extend(new_font, window.cutscene_font, font_changes)
        t = @add.text(@camera.x + @camera.width/2, 70, text, new_font)
        t.anchor.set(0.5, 0.5)
        if exit
            setTimeout((=> t.kill()), 2500)
        return t

    cutscene: (text) ->
        if not @cutscene_background
            data = [ '3333', '3333', '3333']
            @cutscene_background = @create.texture('solid', data, 200, 200)
        @cutscene_screen = @add.sprite(@camera.x, 0, 'solid')
        @game_state = @const.cutscene
        t = @log(text, {}, false)
        @cutscene_text = t

    multiscene: (text_list) ->
        if text_list.length == 0
            @game_state = @const.movement
            return
        cur_text = text_list[0]
        @multiscene_text_list = _.without(text_list, cur_text)
        @cutscene(cur_text)
        @game_state = @const.multiscene

window.main =  =>
    window.game = new Game(Phaser)
