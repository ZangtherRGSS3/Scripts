# -*- coding: utf-8 -*-
#==============================================================================
# ** Custom Battle Kit - RPG Maker VX ACE / RME
#------------------------------------------------------------------------------
#  
#------------------------------------------------------------------------------
# Version : 0.0.0
#------------------------------------------------------------------------------
# Changelog :
#     v0.0.0 : Start Script
#==============================================================================

class GameBattle
	def update
	end
	
	def terminate
	end
	
  
  attr_accessor :turn_count
  
  delegate :@enemies, :enemy_names
  delegate :@enemies, :gold_total
  delegate :@enemies, :exp_total
  delegate :@enemies, :make_drop_items
  
  private
  
  def start
    @turn_count = 0
  end
  
end

class Game_Enemies < Game_Unit
  #--------------------------------------------------------------------------
  # * Characters to be added to the end of enemy names
  #--------------------------------------------------------------------------
  LETTER_TABLE_HALF = [' A',' B',' C',' D',' E',' F',' G',' H',' I',' J',
                       ' K',' L',' M',' N',' O',' P',' Q',' R',' S',' T',
                       ' U',' V',' W',' X',' Y',' Z']  
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_reader   :name_counts              # hash for enemy name appearance
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize(troop_id)
    super
    @troop_id = troop_id
    setup
  end
  #--------------------------------------------------------------------------
  # * Get Members
  #--------------------------------------------------------------------------
  def members
    @enemies
  end
  #--------------------------------------------------------------------------
  # * Clear
  #--------------------------------------------------------------------------
  def clear
    @enemies = []
    @names_count = {}
  end
  #--------------------------------------------------------------------------
  # * Get Troop Objects
  #--------------------------------------------------------------------------
  def troop
    $data_troops[@troop_id]
  end
  #--------------------------------------------------------------------------
  # * Setup
  #--------------------------------------------------------------------------
  def setup
    clear
    @enemies = []
    troop.members.each do |member|
      next unless $data_enemies[member.enemy_id]
      enemy = Game_Enemy.new(@enemies.size, member.enemy_id)
      enemy.hide if member.hidden
      enemy.screen_x = member.x
      enemy.screen_y = member.y
      @enemies.push(enemy)
    end
    make_unique_names
  end
  #--------------------------------------------------------------------------
  # * Add letters (ABC, etc) to enemy characters with the same name
  #--------------------------------------------------------------------------
  def make_unique_names
    members.each do |enemy|
      next unless enemy.alive?
      next unless enemy.letter.empty?
      n = @names_count[enemy.original_name] || 0
      enemy.letter = letter_table[n % letter_table.size]
      @names_count[enemy.original_name] = n + 1
    end
    members.each do |enemy|
      n = @names_count[enemy.original_name] || 0
      enemy.plural = true if n >= 2
    end
  end
  #--------------------------------------------------------------------------
  # * Get Text Table to Place Behind Enemy Name
  #--------------------------------------------------------------------------
  def letter_table
    LETTER_TABLE_HALF
  end
  #--------------------------------------------------------------------------
  # * Get Enemy Name Array
  #    For display at start of battle. Overlapping names are removed.
  #--------------------------------------------------------------------------
  def enemy_names
    names = []
    members.each do |enemy|
      next unless enemy.alive?
      next if names.include?(enemy.original_name)
      names.push(enemy.original_name)
    end
    names
  end
  #--------------------------------------------------------------------------
  # * Calculate Total Experience
  #--------------------------------------------------------------------------
  def exp_total
    dead_members.inject(0) {|r, enemy| r += enemy.exp }
  end
  #--------------------------------------------------------------------------
  # * Calculate Total Gold
  #--------------------------------------------------------------------------
  def gold_total
    dead_members.inject(0) {|r, enemy| r += enemy.gold } * gold_rate
  end
  #--------------------------------------------------------------------------
  # * Create Array of Dropped Items
  #--------------------------------------------------------------------------
  def make_drop_items
    dead_members.inject([]) {|r, enemy| r += enemy.make_drop_items }
  end
end

class Game_Party
  
  alias_method :initialize_200815, :initialize
  attr_accessor :won_battles
  attr_accessor :loss_battles
  attr_accessor :run_away_battles
  
  def initialize
    initialize_200815
    @won_battles = 0
    @loss_battles = 0
    @ran_away_battles = 0
  end

end
