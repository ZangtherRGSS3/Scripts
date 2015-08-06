#==============================================================================
# ** Ring Menu - RPG Maker VX ACE
#------------------------------------------------------------------------------
#  This is a simple ring menu.
#          - Core classes are in module Zangther including
#                  - Scene_RingMenu
#                  - Spriteset_Iconring
#                  - Sprite_Icon
#          - Configuration is in the module Zangther::RingMenu::Config
#          - You can change fade_in and fade_out methods, they are into
#              Zangther::RingMenu::Config::Fade
#          - Some edits to Scene_Map, Scene_Item, Scene_File and Scene_End are
#              made at the end of the file in order to make them compatible
#              with this ring menu.
#             (#call_menu for Scene_Map and #return_scene for the others)
#------------------------------------------------------------------------------
# Version : 1.4.2 by Zangther
#     If you have any questions, contact me at zangther[AT]gmail.com
#------------------------------------------------------------------------------
# Changelog :
#     v1.4.2 : Menu text wasn't displayed after comming back from another menu
#     v1.4.1 : Fix icons that were visible before being placed at the
#                correct location
#     v1.4.0 : Add speed configuration for menus
#     v1.3.1 : Fix text drawing, draw only when needed
#     v1.3.0 : Add enable/disable menu choices
#     v1.2.0 : Inclusion into RMEBuilder
#     v1.1.2 : Make non selected icon grayish
#     v1.1.0 : Add Scene_HeroFormation
#     v1.0.1 : Cleaning
#     v1.0.0 : Base script
#------------------------------------------------------------------------------
#       Special thanks to Raho, Nuki, S4suk3 and Grim from Funkywork
#         for advises and constant support ! [ http://funkywork.jeun.fr ]
#------------------------------------------------------------------------------
#  Enable/Disable choices -
#         You can enable or disable menus choices by using the following 
#            commands into the Call Script event command :
#                 - disable_menu_choice(choice_name)
#                 - enable_menu_choice(choice_name)
#         Example :
#             Disable items menu : disable_menu_choice(:items)
#             Enable items menu  : enable_menu_choice(:items)
#         Note : 
#             You can still use the events commands for Save/Formation menus
#
#==============================================================================
module Zangther
  module RingMenu
    module Config
      # Menus' commands
      MENU_COMMAND = [
        # You should not change any choice_name from defaults
        # { choice_name: :scene, name: "Name", icon: ID, action: -> {Scene}, prepare: -> {SceneManager.scene.prepare(arguments)} }
        { choice_name: :items, name: "Items", icon: 261, action: -> {Scene_Item}},
        { choice_name: :skills, name: "Skills", icon: 116, action: -> {Scene_HeroMenu}, prepare: -> {SceneManager.scene.prepare(Scene_Skill)} },
        { choice_name: :equip, name: "Equip", icon: 434, action: -> {Scene_HeroMenu}, prepare: -> {SceneManager.scene.prepare(Scene_Equip)} },
        { choice_name: :status, name: "Status", icon: 121, action: -> {Scene_HeroMenu}, prepare: -> {SceneManager.scene.prepare(Scene_Status)} },
        { choice_name: :formation, name: "Formation", icon: 11, action: -> {Scene_HeroFormation}},
        { choice_name: :file, name: "File", icon: 117, action: -> {Scene_Save}},
        { choice_name: :exit, name: "Exit", icon: 12, action: -> {Scene_End}}
      ]
      # Angle de base
      START_ANGLE = 1.5 * Math::PI
      # Distance
      DISTANCE = 50
      # Setting save variable (chose a variable not used by any event or script)
      SETTINGS_VARIABLE = 5001 # It can be outside the RPG Maker bounds.
      # Ring menu spin speed
      RING_MENU_SPEED = 10
      # Hero menu spin speed
      HERO_MENU_SPEED = 10
    end
    #==============================================================================
    # ** Settings
    #------------------------------------------------------------------------------
    #  Contains methods about getting and saving settings
    #==============================================================================
    module Settings
      class << self
        #--------------------------------------------------------------------------
        # * Is scene choice enabled ?
        #--------------------------------------------------------------------------
        def choice_enabled?(choice_name)
          state = get[:choice_enabled][choice_name]
          state.nil? ? true : state
        end
        #--------------------------------------------------------------------------
        # * Set if is scene choice is enabled or not ?
        #--------------------------------------------------------------------------
        def set_choice_state(choice_name, state)
          get[:choice_enabled][choice_name] = state
        end
        #--------------------------------------------------------------------------
        # * Get settings
        #--------------------------------------------------------------------------
        def get
          settings = $game_variables[Config::SETTINGS_VARIABLE]
          (initialize_settings and return get) unless settings.is_a? Hash

          settings
        end
        #--------------------------------------------------------------------------
        # * Initialize settings with a hash if needed
        #--------------------------------------------------------------------------
        def initialize_settings
          $game_variables[Config::SETTINGS_VARIABLE] = Hash.new { |hash, key| hash[key] = {} }
        end
      end
    end
    #==============================================================================
    # ** Fade
    #------------------------------------------------------------------------------
    #  Contains methods about fade in and fade out for ring menu.
    #==============================================================================
    module Fade
      #--------------------------------------------------------------------------
      # * Fade in
      #--------------------------------------------------------------------------
      def fade_in(distance)
        distance = distance.to_i
        total_spin
        dist_step = (distance - @distance) / (6.28 / @step)
        opa_step = 255 / (6.28 / @step)
        recede(distance,  dist_step)
        change_opacity(255, opa_step)
        @state = :openning
      end
      #--------------------------------------------------------------------------
      # * Fade out
      #--------------------------------------------------------------------------
      def fade_out(distance)
        distance = distance.to_i
        total_spin
        dist_step = (distance - @distance) / (6.28 / @step)
        opa_step = 255 / (6.28 / @step)
        approach(distance,  dist_step)
        change_opacity(0, -opa_step)
        @state = :closing
      end
    end

    #==============================================================================
    # ** Icon
    #------------------------------------------------------------------------------
    #  Add sevreal methods related to icons
    #==============================================================================
    module Icon
      #--------------------------------------------------------------------------
      # * Place the sprite
      #--------------------------------------------------------------------------
      def place(x, y, distance, angle)
        # Force values to numeric
        distance = distance.to_i
        angle = angle.to_f
        # Polar coordinations calculation
        self.x = x.to_i + (Math.cos(angle)*distance)
        self.y = y.to_i + (Math.sin(angle)*distance)
        self.visible = true
        update
      end
    end
  end

  #==============================================================================
  # ** Sprite_Icon
  #------------------------------------------------------------------------------
  #  Just inherit from Sprite and Icon
  #==============================================================================
  class Sprite_Icon < Sprite_Base
    include RingMenu::Icon
  end

  #==============================================================================
  # ** Game_CharacterIcon
  #------------------------------------------------------------------------------
  #  Inherits from Game_Character, add some utility methods and changes
  #    move_speed default value
  #==============================================================================
  class Game_CharacterIcon < Game_Character
    #--------------------------------------------------------------------------
    # * Object Initialization
    #--------------------------------------------------------------------------
    def initialize
      super
      @move_speed = 1
    end
    #--------------------------------------------------------------------------
    # * Stop movement
    #--------------------------------------------------------------------------
    def stand_still
      @step_anime = false
      straighten
    end
    #--------------------------------------------------------------------------
    # * Make walk
    #--------------------------------------------------------------------------
    def walk
      @step_anime = true
    end

  end

  #==============================================================================
  # ** Sprite_Character_Icon
  #------------------------------------------------------------------------------
  #  Just inherit from Sprite_Character and Icon, changes update to prevent
  #    placement issues
  #==============================================================================
  class Sprite_Character_Icon < Sprite_Icon
    #--------------------------------------------------------------------------
    # * Public Instance Variables
    #--------------------------------------------------------------------------
    attr_reader :character
    #--------------------------------------------------------------------------
    # * Object Initialization
    #     viewport  : viewport
    #     character : character (Game_Character)
    #--------------------------------------------------------------------------
    def initialize(viewport, character = nil)
      super(viewport)
      @character = character
    end
    #--------------------------------------------------------------------------
    # * Update
    #--------------------------------------------------------------------------
    def update
      super
      @character.update
      update_bitmap
      update_src_rect
      self.z = @character.screen_z
    end

    private
    #--------------------------------------------------------------------------
    # * Update Transfer Origin Bitmap
    #--------------------------------------------------------------------------
    def update_bitmap
      if graphic_changed?
        @character_name = @character.character_name
        @character_index = @character.character_index
        set_character_bitmap
      end
    end
    #--------------------------------------------------------------------------
    # * Determine if Graphic Changed
    #--------------------------------------------------------------------------
    def graphic_changed?
      @character_name != @character.character_name ||
        @character_index != @character.character_index
    end
    #--------------------------------------------------------------------------
    # * Set Character Bitmap
    #--------------------------------------------------------------------------
    def set_character_bitmap
      self.bitmap = Cache.character(@character_name)
      sign = @character_name[/^[\!\$]./]
      if sign && sign.include?('$')
        @cw = bitmap.width / 3
        @ch = bitmap.height / 4
      else
        @cw = bitmap.width / 12
        @ch = bitmap.height / 8
      end
      self.ox = @cw / 2
      self.oy = @ch
    end
    #--------------------------------------------------------------------------
    # * Update Transfer Origin Rectangle
    #--------------------------------------------------------------------------
    def update_src_rect
      index = @character.character_index
      pattern = @character.pattern < 3 ? @character.pattern : 1
      sx = (index % 4 * 3 + pattern) * @cw
      sy = (index / 4 * 4 + (@character.direction - 2) / 2) * @ch
      self.src_rect.set(sx, sy, @cw, @ch)
    end
  end

  #==============================================================================
  # ** Spriteset_Iconring
  #------------------------------------------------------------------------------
  #  This class manages Sprite_Icon and make then spin around a point.
  #==============================================================================
  class Spriteset_Iconring
    #--------------------------------------------------------------------------
    # * Module inclusions
    #--------------------------------------------------------------------------
    include RingMenu::Fade
    #--------------------------------------------------------------------------
    # * Public Instance Variables
    #--------------------------------------------------------------------------
    attr_reader :x
    attr_reader :y
    attr_reader :distance
    attr_reader :angle
    attr_reader :direction
    attr_reader :actual_direction
    attr_reader :index
    #--------------------------------------------------------------------------
    # * Constants
    #--------------------------------------------------------------------------
    PI_2 = 6.28
    #--------------------------------------------------------------------------
    # * Object Initialization
    #     x, y, distance, speed : int
    #     angle : int (radians)
    #     sprites : Enumeration of RingMenu::Icon
    #     index : int
    #     direction :  :trigo, :antitrigo, :+, :-, :positif, :negatif
    #--------------------------------------------------------------------------
    def initialize(x, y, distance, speed, angle, sprites, index = 0, direction=:trigo)
      # Argument test
      sprites = Array(sprites)
      unless sprites.all? { |sp| (sp.is_a?(RingMenu::Icon)) }
        raise(ArgumentError, "sprite isn't an array of Sprite_Icons")
      end
      # Adjust numeric arguments
      @x = x.to_i + 16
      @y = y.to_i + 16
      @distance = @future_distance = 0
      @speed = speed.to_i
      @angle = (angle.to_f - (index.to_f * (PI_2 / sprites.size))).modulo PI_2
      # Settings
      @shift = {:trigo => 0, :antitrigo => 0}
      @direction = @actual_direction = direction
      @index = index.to_i
      @opacity = @future_opacity = 0
      @icons = sprites
      @state = :closed
      self.step = :default
      fade_in(distance)
    end
    #--------------------------------------------------------------------------
    # * Update
    #  need_refresh : force refresh
    #--------------------------------------------------------------------------
    def update(current_is_gray, need_refresh=false)
      return unless @icons
      if moving?
        if spinning?
          reverse_direction if need_reverse?
          update_angle
        end
        update_distance
        need_refresh = true
      end
      update_opacity
      update_state
      refresh(current_is_gray) if need_refresh
    end
    #--------------------------------------------------------------------------
    # * Prepare terminate method
    #--------------------------------------------------------------------------
    def pre_terminate
      fade_out(0)
    end
    #--------------------------------------------------------------------------
    # * Dispose
    #--------------------------------------------------------------------------
    def dispose
      @icons.each {|icon| icon.dispose}
    end
    #--------------------------------------------------------------------------
    # * Refresh
    #--------------------------------------------------------------------------
    def refresh(current_is_gray)
      @icons.size.times do |i|
        icon = @icons[i]
        angle = @angle + ((PI_2/(@icons.size))*i)
        icon.place(@x,@y,@distance,angle)
        icon.opacity = @opacity
        icon.tone.gray = (i == @index) && !current_is_gray ? 0 : 255
        icon.update
      end
    end
    #--------------------------------------------------------------------------
    # * Spin
    #--------------------------------------------------------------------------
    def spin
      unless spinning?
        number_of_icons = @icons.size
        @shift[@direction] += PI_2/number_of_icons
        if @direction == :trigo
          @index += 1
        else
          @index -= 1
        end
        @index = @index.modulo number_of_icons
      end
    end
    #--------------------------------------------------------------------------
    # * Change direction
    #     direction :  :trigo, :antitrigo, :+, :-, :positif, :negatif
    #--------------------------------------------------------------------------
    def change_direction(direction)
      case direction
      when :trigo, :+, :positif
        @direction = :trigo
      when :antitrigo, :-, :negatif
        @direction = :antitrigo
      end
    end
    #--------------------------------------------------------------------------
    # * Change center
    #   x,y : Entiers
    #--------------------------------------------------------------------------
    def changer_centre(x, y)
      @x = x.to_i
      @y = y.to_i
    end
    #--------------------------------------------------------------------------
    # * Set angle
    #--------------------------------------------------------------------------
    def angle=(angle)
      if angle > PI_2 || angle < 0
        angle = 0
      end
      @angle = angle.to_f
    end
    #--------------------------------------------------------------------------
    # * Maj step
    #--------------------------------------------------------------------------
    def step=(step=1)
      if step == :default
        number_of_icons = @icons.size
        @step = PI_2 / (number_of_icons*100) * @speed
      else
        @step = step.to_f * @speed
      end
    end
    #--------------------------------------------------------------------------
    # * Spin right
    #--------------------------------------------------------------------------
    def spin_right
      change_direction(:+)
      spin
    end
    #--------------------------------------------------------------------------
    # * Spin left
    #--------------------------------------------------------------------------
    def spin_left
      change_direction(:-)
      spin
    end
    #--------------------------------------------------------------------------
    # * Move away from center
    #--------------------------------------------------------------------------
    def recede(distance, step = 1)
      @future_distance = distance.to_i
      @distance_step = step.abs
    end
    #--------------------------------------------------------------------------
    # * Move back to center
    #--------------------------------------------------------------------------
    def approach(distance, step = 1)
      @future_distance = distance.to_i
      @distance_step = - step.abs
    end
    #--------------------------------------------------------------------------
    # * Changes opacity
    #--------------------------------------------------------------------------
    def change_opacity(opacity, step = 1)
      if opacity > 255
        @future_opacity = 255
      elsif opacity < 0
        @future_opacity = 0
      else
        @future_opacity = opacity.to_i
      end
      @opacity_step = step.to_i
    end
    #--------------------------------------------------------------------------
    # * Is closed ?
    #--------------------------------------------------------------------------
    def closed?
      @state == :closed
    end
    #--------------------------------------------------------------------------
    # * Is opened ?
    #--------------------------------------------------------------------------
    def opened?
      @state == :opened
    end
    #--------------------------------------------------------------------------
    # * Is closing ?
    #--------------------------------------------------------------------------
    def closing?
      @state == :closing
    end
    #--------------------------------------------------------------------------
    # * Is openning ?
    #--------------------------------------------------------------------------
    def openning?
      @state == :openning
    end

    private
    #--------------------------------------------------------------------------
    # * Updates angle positionning
    #--------------------------------------------------------------------------
    def update_angle
      direction = @actual_direction
      shift = @shift[direction]
      step = @step > shift ? shift : @step
      step *= -1 if direction == :trigo
      temp = @angle + step
      if direction == :trigo && temp < 0
        temp += PI_2
      elsif direction == :antitrigo && temp > PI_2
        temp -= PI_2
      end
      @angle = temp
      @shift[direction] = shift - @step
      @shift[direction] = 0 if @shift[direction] < 0
    end
    #--------------------------------------------------------------------------
    # * Updates distance positionning
    #--------------------------------------------------------------------------
    def update_distance
      return if @future_distance == @distance
      temp = @distance + @distance_step
      # Checks if @future_distance is between temp and @distance
      # If so, that's mean that @distance_step is bigger than the gap between @distance & @future_distance
      if (@distance..temp).include?(@future_distance) || (temp..@distance).include?(@future_distance)
        @distance = @future_distance
      else
        @distance += @distance_step
      end
    end
    #--------------------------------------------------------------------------
    # * Updates opacity
    #--------------------------------------------------------------------------
    def update_opacity
      shift = @future_opacity - @opacity
      return if shift == 0
      @opacity += @opacity_step
      if shift > 0
        @opacity = @future_opacity if @opacity > @future_opacity
      else
        @opacity = @future_opacity if @opacity < @future_opacity
      end
    end
    #--------------------------------------------------------------------------
    # * Updates state
    #--------------------------------------------------------------------------
    def update_state
      unless spinning?
        if @state == :closing
          @state = :closed
        elsif @state == :openning
          @state = :opened
        end
      end
    end
    #--------------------------------------------------------------------------
    # * Reverse the direction
    #--------------------------------------------------------------------------
    def reverse_direction
      @actual_direction = (@actual_direction == :trigo ? :antitrigo : :trigo)
    end
    #--------------------------------------------------------------------------
    # * Need revesing direction ?
    #--------------------------------------------------------------------------
    def need_reverse?
      @shift[@actual_direction] <= 0
    end
    #--------------------------------------------------------------------------
    # * Spinning
    #--------------------------------------------------------------------------
    def spinning?
      @shift.any? {|key,val| val > 0}
    end
    #--------------------------------------------------------------------------
    # * Moving ?
    #--------------------------------------------------------------------------
    def moving?
      spinning? || (@future_distance != @distance)
    end
    #--------------------------------------------------------------------------
    # * Make one complete spin
    #--------------------------------------------------------------------------
    def total_spin
      @shift[@direction] += PI_2 unless spinning?
    end
  end

  #==============================================================================
  # ** Spriteset_IconCrescent
  #------------------------------------------------------------------------------
  #  This class manages Sprite_Icon and place them as a crescent.
  #==============================================================================
  class Spriteset_IconCrescent
    #--------------------------------------------------------------------------
    # * Fade in
    #--------------------------------------------------------------------------
    attr_reader :index
    attr_reader :pending_index
    #--------------------------------------------------------------------------
    # * Object Initialization
    #     x, y : int
    #     sprites : RingMenu::Icon array
    #--------------------------------------------------------------------------
    def initialize(x, y, sprites)
      unless sprites.all? { |sp| (sp.is_a?(RingMenu::Icon)) }
        raise(ArgumentError, "sprite isn't an array of Sprite_Icons")
      end
      @sprites = sprites
      @distance = RingMenu::Config::DISTANCE
      @x = x
      @y = y
      @index = 0
      @pending_index = 0
      select(0)
      update
    end
    #--------------------------------------------------------------------------
    # * Update
    #--------------------------------------------------------------------------
    def update
      @sprites.each_with_index do |sprite, i|
        update_position(sprite, i)
        sprite.update
      end
    end
    #--------------------------------------------------------------------------
    # * Move
    #--------------------------------------------------------------------------
    def move(direction)
      unselect
      case direction
      when :right
        increment_index
      when :left
        decrement_index
      end
      select(@index)
    end
    #--------------------------------------------------------------------------
    # * Chose a char
    #--------------------------------------------------------------------------
    def chose
      half = @sprites.size / 2
      if @index + 1 > half
        @sprites[@index].character.set_direction(4) # Face left
      else
        @sprites[@index].character.set_direction(6) # Face right
      end
    end
    #--------------------------------------------------------------------------
    # * Unchose a char
    #--------------------------------------------------------------------------
    def unchose
      @sprites[@index].character.set_direction(2)
    end
    #--------------------------------------------------------------------------
    # * Can two swap ?
    #     direction : :right, :left
    #--------------------------------------------------------------------------
    def can_swap?(direction)
      case direction
      when :right
        can_swap_right?
      when :left
        can_swap_left?
      end
    end
    #--------------------------------------------------------------------------
    # * Swap
    #     direction : :right, :left
    #--------------------------------------------------------------------------
    def swap(direction)
      case direction
      when :right
        @pending_index = @index
        swap_right
      when :left
        @pending_index = @index
        swap_left
      end
      chose
    end

    private
    #--------------------------------------------------------------------------
    # * Can swap right
    #--------------------------------------------------------------------------
    def can_swap_right?
      @index < @sprites.size - 1
    end
    #--------------------------------------------------------------------------
    # * Can swap left
    #--------------------------------------------------------------------------
    def can_swap_left?
      @index != 0
    end
    #--------------------------------------------------------------------------
    # * Swap right
    #--------------------------------------------------------------------------
    def swap_right
      animated_swap(@sprites[@index], @sprites[@index+1])
      @sprites[@index], @sprites[@index+1] = @sprites[@index+1], @sprites[@index]
      increment_index
    end
    #--------------------------------------------------------------------------
    # * Swap left
    #--------------------------------------------------------------------------
    def swap_left
      animated_swap(@sprites[@index-1], @sprites[@index])
      @sprites[@index-1], @sprites[@index] = @sprites[@index], @sprites[@index-1]
      decrement_index
    end
    #--------------------------------------------------------------------------
    # * Animatte swap
    #     (it's empty but you can fill it fellah)
    #--------------------------------------------------------------------------
    def animated_swap(sprite_left, sprite_right)
    end
    #--------------------------------------------------------------------------
    # * Select char
    #--------------------------------------------------------------------------
    def select(index)
      @sprites[index].character.walk
    end
    #--------------------------------------------------------------------------
    # * Unselect char
    #--------------------------------------------------------------------------
    def unselect
      @sprites[@index].character.stand_still
    end
    #--------------------------------------------------------------------------
    # * Update position of a sprite
    #--------------------------------------------------------------------------
    def update_position(sprite, i)
      angle_gap = Math::PI / @sprites.size
      start_angle = angle_gap / 2 + Math::PI
      angle = start_angle + (angle_gap * i)
      sprite.place(@x,@y,@distance,angle)
    end
    #--------------------------------------------------------------------------
    # * Increment index
    #--------------------------------------------------------------------------
    def increment_index
      @index = (@index + 1) % @sprites.size
    end
    #--------------------------------------------------------------------------
    # * Decrement index
    #--------------------------------------------------------------------------
    def decrement_index
      @index -= 1
      @index = 0 if @index == @sprites.size
    end

  end

  #==============================================================================
  # ** Scene_RingMenu
  #------------------------------------------------------------------------------
  #  This scene used to be an adventurer like you, but then it took an arrow in the knee.
  #==============================================================================
  class Scene_RingMenu < Scene_MenuBase
    #--------------------------------------------------------------------------
    # * Start processing
    #--------------------------------------------------------------------------
    def start
      super
      create_background
      create_command_ring
      create_command_name
    end
    #--------------------------------------------------------------------------
    # * Termination Processing
    #--------------------------------------------------------------------------
    def terminate
      super
      dispose_background
      dispose_command_name
    end
    #--------------------------------------------------------------------------
    # * Frame Update
    #--------------------------------------------------------------------------
    def update
      super
      if @command_ring.closed?
        @command_ring.dispose
        @current_text = nil
        change_scene
      else
        @command_ring.update(current_choice_disabled?)
        update_command_name
        update_command_selection unless @command_ring.closing?
      end
    end
    #--------------------------------------------------------------------------
    # * Is current choice disabled ?
    #--------------------------------------------------------------------------
    def current_choice_disabled?
      !RingMenu::Settings.choice_enabled? current_choice[:choice_name]
    end

    private
    #--------------------------------------------------------------------------
    # * Create Command Ring
    #--------------------------------------------------------------------------
    def create_command_ring
      icons = Array.new
      RingMenu::Config::MENU_COMMAND.each do |command|
        icons.push(icon = Sprite_Icon.new)
        icon.visible = false
        icon.bitmap = Cache.system("Iconset")
        index = command[:icon]
        x = index % 16 * 24
        y = (index / 16).truncate * 24
        icon.src_rect = Rect.new(x,y,24,24)
      end
      x = $game_player.screen_x - 28
      y = $game_player.screen_y - 44
      distance = RingMenu::Config::DISTANCE
      angle = RingMenu::Config::START_ANGLE
      speed = RingMenu::Config::RING_MENU_SPEED
      @command_ring = Spriteset_Iconring.new(x, y, distance, speed, angle, icons, @index)
    end
    #--------------------------------------------------------------------------
    # * Create Command Text
    #--------------------------------------------------------------------------
    def create_command_name
      @command_name = Sprite.new
      distance = RingMenu::Config::DISTANCE
      width = distance * 2
      @command_name.bitmap = Bitmap.new(width, 24)
      @command_name.x = $game_player.screen_x  - distance
      @command_name.y = $game_player.screen_y + distance
    end
    #--------------------------------------------------------------------------
    # * Update Command Selection
    #--------------------------------------------------------------------------
    def update_command_selection
      if Input.trigger?(Input::B)
        Sound.play_cancel
        do_return
      elsif Input.trigger?(Input::LEFT)
        @command_ring.spin_left
      elsif Input.trigger?(Input::RIGHT)
        @command_ring.spin_right
      elsif Input.trigger?(Input::C)
        if current_choice_disabled?
          Sound.play_buzzer
        else
          Sound.play_ok
          prepare_next_scene
        end
      end
    end
    #--------------------------------------------------------------------------
    # * Update Command Text
    #--------------------------------------------------------------------------
    def update_command_name
      rect = @command_name.src_rect
      command = RingMenu::Config::MENU_COMMAND[@command_ring.index]
      return if @current_text == command[:name]

      @current_text = command[:name]
      bitmap = @command_name.bitmap
      bitmap.clear
      bitmap.font.color.alpha = current_choice_disabled? ? 160 : 255
      bitmap.draw_text(rect, @current_text, 1)
    end
    #--------------------------------------------------------------------------
    # * Dispose Command Text
    #--------------------------------------------------------------------------
    def dispose_command_name
      @command_name.dispose
    end
    #--------------------------------------------------------------------------
    # * Prepare transition for new scene
    #--------------------------------------------------------------------------
    def prepare_next_scene
      @index = @command_ring.index
      command = current_choice
      @scene = command[:action].call
      @prepare = command.fetch(:prepare) { |el| -> {} }
      @command_ring.pre_terminate
    end
    #--------------------------------------------------------------------------
    # * Execute transition to new scene
    #--------------------------------------------------------------------------
    def change_scene
      if @scene == :none
        SceneManager.return
      else
        SceneManager.call(@scene)
        @prepare.call
      end
    end
    #--------------------------------------------------------------------------
    # * Load the next scene
    #--------------------------------------------------------------------------
    def do_return
      @scene = :none
      @command_ring.pre_terminate
    end
    #--------------------------------------------------------------------------
    # * Current choice
    #--------------------------------------------------------------------------
    def current_choice
      RingMenu::Config::MENU_COMMAND[@command_ring.index]
    end
  end

  #==============================================================================
  # ** Scene_HeroMenu
  #------------------------------------------------------------------------------
  #  Dance like it hurts, Love like you need money, Work when people are watching.
  #==============================================================================
  class Scene_HeroMenu < Scene_RingMenu
    #--------------------------------------------------------------------------
    # * Initialize
    #--------------------------------------------------------------------------
    def prepare(scene)
      raise "scene must be a Class object !" unless scene.is_a?(Class)
      @scene = scene
    end

    private
    #--------------------------------------------------------------------------
    # * Create Command Ring
    #--------------------------------------------------------------------------
    def create_command_ring
      icons = $game_party.members.map do |actor|
        char = Game_Character.new
        char.set_graphic(actor.character_name,actor.character_index)
        Sprite_Character_Icon.new(@viewport, char)
      end
      x = $game_player.screen_x - 16
      y = $game_player.screen_y - 16
      distance = RingMenu::Config::DISTANCE
      angle = RingMenu::Config::START_ANGLE
      speed = RingMenu::Config::HERO_MENU_SPEED
      @command_ring = Spriteset_Iconring.new(x, y, distance, speed, angle, icons)
      @command_ring.update(current_choice_disabled?, true)
    end
    #--------------------------------------------------------------------------
    # * Create Command Text
    #--------------------------------------------------------------------------
    def create_command_name
      @command_name = Sprite.new
      distance = RingMenu::Config::DISTANCE
      width = distance * 2
      @command_name.bitmap = Bitmap.new(width, 24)
      @command_name.x = $game_player.screen_x - distance
      @command_name.y = $game_player.screen_y + distance
    end
    #--------------------------------------------------------------------------
    # * Update Command Text
    #--------------------------------------------------------------------------
    def update_command_name
      rect = @command_name.src_rect
      hero = $game_party.members[@command_ring.index]
      bitmap = @command_name.bitmap
      bitmap.clear
      bitmap.draw_text(rect, hero.name, 1)
    end
    #--------------------------------------------------------------------------
    # * Load the next scene
    #--------------------------------------------------------------------------
    def prepare_next_scene
      $game_party.menu_actor = $game_party.members[@command_ring.index]
      @command_ring.pre_terminate
    end
    #--------------------------------------------------------------------------
    # * Execute transition to new scene
    #--------------------------------------------------------------------------
    def change_scene
      if @scene == :none
        SceneManager.return
      else
        SceneManager.goto(@scene)
      end
    end
  end
  #==============================================================================
  # ** Scene_HeroFormation
  #------------------------------------------------------------------------------
  #  A ring menu to handle formation issues.
  #==============================================================================
  class Scene_HeroFormation < Scene_MenuBase
    #--------------------------------------------------------------------------
    # * Start
    #--------------------------------------------------------------------------
    def start
      super
      create_command_crescent
      @chosing = false
    end
    #--------------------------------------------------------------------------
    # * Update
    #--------------------------------------------------------------------------
    def update
      super
      update_command_selection
      @command_ring.update
    end

    private
    #--------------------------------------------------------------------------
    # * Create command crescent
    #--------------------------------------------------------------------------
    def create_command_crescent
      icons = $game_party.members.map do |actor|
        char = Game_CharacterIcon.new
        char.set_graphic(actor.character_name,actor.character_index)
        Zangther::Sprite_Character_Icon.new(@viewport, char)
      end
      x = $game_player.screen_x
      y = $game_player.screen_y
      distance = Zangther::RingMenu::Config::DISTANCE
      angle = Zangther::RingMenu::Config::START_ANGLE
      @command_ring = Zangther::Spriteset_IconCrescent.new(x, y, icons)
    end
    #--------------------------------------------------------------------------
    # * Update Command Selection
    #--------------------------------------------------------------------------
    def update_command_selection
      if Input.trigger?(Input::B)
        Sound.play_cancel
        do_return
      elsif Input.trigger?(Input::LEFT)
        update_selection(:left)
      elsif Input.trigger?(Input::RIGHT)
        update_selection(:right)
      elsif Input.trigger?(Input::C)
        Sound.play_ok
        if @chosing
          @command_ring.unchose
        else
          @command_ring.chose
        end
        @chosing = !@chosing
      end
    end
    #--------------------------------------------------------------------------
    # * Load the next scene
    #--------------------------------------------------------------------------
    def do_return
      SceneManager.return
    end

    private
    #--------------------------------------------------------------------------
    # * Fade in
    #--------------------------------------------------------------------------
    def update_selection(direction)
      if @chosing
        if @command_ring.can_swap?(direction)
          Sound.play_escape
          @command_ring.swap(direction)
          $game_party.swap_order(@command_ring.index,
                                 @command_ring.pending_index)
        else
          Sound.play_buzzer
        end
      else
        Sound.play_cursor
        @command_ring.move(direction)
      end
    end
  end
end
#==============================================================================
# ** Game_Interpreter
#------------------------------------------------------------------------------
#  An interpreter for executing event commands. This class is used within the
# Game_Map, Game_Troop, and Game_Event classes.
#==============================================================================
class Game_Interpreter
  #--------------------------------------------------------------------------
  # * Change Save Access
  #--------------------------------------------------------------------------
  alias change_save_availability command_134
  def command_134
    Zangther::RingMenu::Settings.set_choice_state(:file, !change_save_availability)
  end
  #--------------------------------------------------------------------------
  # * Change Formation Access
  #--------------------------------------------------------------------------
  alias change_form_availability command_137
  def command_137
    Zangther::RingMenu::Settings.set_choice_state(:formation, !change_form_availability)
  end
  #--------------------------------------------------------------------------
  # * Disable access to a specific choice into the menu
  #--------------------------------------------------------------------------
  def disable_menu_choice(menu_choice)
    Zangther::RingMenu::Settings.set_choice_state(menu_choice, false)
  end
  #--------------------------------------------------------------------------
  # * Enable access to a specific choice into the menu
  #--------------------------------------------------------------------------
  def enable_menu_choice(menu_choice)
    Zangther::RingMenu::Settings.set_choice_state(menu_choice, true)
  end
end

#==============================================================================
# ** Scene_Map
#------------------------------------------------------------------------------
#  This class performs the map screen processing.
#==============================================================================
class Scene_Map
  #--------------------------------------------------------------------------
  # * Call Menu Screen
  #--------------------------------------------------------------------------
  def call_menu
    Sound.play_ok
    SceneManager.call(Zangther::Scene_RingMenu)
  end
end
