#  champion.rb
#  Copyright (c) 2016 Godwin Liu, All Rights Reserved.
#
#  Library singleton class for accessing static data
#  relating to champions.

require_relative 'riot_data_object'
require 'json'
require 'singleton'
require 'yaml'

# require_relative 'riot_data_connector'

module RiotData
  class Champion < RiotDataObject
    include Singleton
    # include RiotDataConnector

    VARS_DECODE = { 'attackdamage' => 'AD',
                    'spelldamage' => 'AP',
                    'bonusattackdamage' => 'bonus AD'}

    STATS_DECODE = {
      'armor' => 'Armor',
      'attackdamage' => 'Attack Damage (AD)',
      'attackrange' => 'Attack Range',
      'attackspeedoffset' => 'AA Delay',
      'crit' => 'Crit',
      'hp' => 'HP',
      'hpregen' => 'HP Regen',
      'movespeed' => 'Move Speed (MS)',
      'mp' => 'Mana/Energy',
      'mpregen' => 'Mana/Energy Regen',
      'spellblock' => 'Magic Resist (MR)'
    }
    
    def initialize
      @champ_data = Hash.new
    end
    
    def list
      @champ_list || load_champs_list
    end

    def search_name( name )
      raise "search_name needs string for search" unless name.is_a?( String )
      found = list.select {|k, v| v[:name].downcase == name.strip.downcase }
      return found.keys.first
    end
    
    def get( riot_champ_id, force_reload = false )
      raise "champion_id must be on riot's list" unless list.keys.include?( riot_champ_id )
      unless force_reload || @champ_data[riot_champ_id].nil?
        return @champ_data[riot_champ_id]
      else
        @champ_data[riot_champ_id] = fetch( riot_champ_id )
      end
    end

    def show( riot_champ_id, format = :text )
      raise "champion_id must be on riot's list" unless list.keys.include?( riot_champ_id )
      c = get( riot_champ_id )
      # puts "Data returned: #{c}\n\n"
      # out = "\nChampion Data for:\n"
      out = "\n\t#{c[:name].upcase} - #{c[:title]}\n"
      out << "\n\tStats:"
      c[:stats].each do |stat, v|
        out << "\n\t#{'%18.18s' % stat}: #{v[:base]}"
        out << " + (#{v[:perlevel]}/lvl)" if v[:perlevel]
        out << "\t= max: #{(v[:base] + (v[:perlevel].to_f * 17)).round(2)}" if v[:perlevel]
      end
      out << "\n"
      out << "\n\tPassive: #{c[:passive][:name]}\n"
      out << "\t"
      out << word_wrap(c[:passive][:desc], {separator: "\n\t"})
      out << "\n"
      c[:spells].each do |sk, sv|
        out << "\n\t#{sv[:name]} (#{sv[:hotkey]} - #{sk})\n"
        out << "\t"
        out << word_wrap(sv[:desc], {separator: "\n\t"})
        out << "\n\t\tCost: "
        out << word_wrap(sv[:cost], {separator: "\n\t\t"})
        out << "\n\t\tCooldown: #{sv[:cooldown]}\n"
        # raw data for debugging:
        # puts sv[:raw].to_yaml  # print to yaml
        # rawsplit = sv[:raw].to_s.gsub(/(\"\w+\"=>)/, "\n\\1")
        # out << "\n\tRAW:\n\t#{word_wrap(rawsplit, {separator: "\n\t"})}"
      end
      return out
    end
    
    private
    
    def fetch( riot_champ_id )
      uri = static_uri( CHAMP_DATA_PATH + '/' + riot_champ_id.to_s, {champData: 'all'} )
      r = fetch_response( uri, true )
      ro = JSON.parse(r.body )
      
      # # [2016-Apr-11 GYL] inspect the json object
      # puts "Keys: #{ro.keys}\n\n"
      # nosubkeys = %w{ id key name title image }
      # ro.each do |k, v|
      #   puts "\tKey: #{k}"
      #   puts "\t\tValues: #{v}\n\n"
      #   # puts "Subkeys: #{v.keys}\n" unless nosubkeys.include?( k )
      # end

      c = Hash.new
      if ro
        ro.each do |k, v|
          case k
          when 'id'
            c[:riot_id] = v
          when 'name'
            c[:name] = v
          when 'title'
            c[:title] = v
          when 'image'
            c[:image] = v['full']
          when 'stats'
            c[:stats] = process_stats( v )
          when 'spells'
            c[:spells] = process_spells( v )
          when 'passive'
            c[:passive] = process_passive( v )
          end
        end # processing json object
        # for debugging:
        # c[:raw] = ro
      end
      return c
    end
    
    def load_champs_list
      uri = static_uri( CHAMP_DATA_PATH, { champData: 'image'} )
      res = fetch_response( uri, true )
      champions = JSON.parse( res.body )
      @champ_list = Hash.new
      champions['data'].each do |k, v|
        @champ_list[v['id']] = {name: v['name'], image: v['image']['full']}
      end
      return @champ_list
    end

    def process_stats( stat_hash )
      raise "invalid stat_hash" unless stat_hash.is_a?( Hash )
      # process base stats first
      bstat = stat_hash.reject {|k, v| /perlevel/ =~ k }
      bstat.each do |k, v|
        bstat[k] = { base: v, perlevel: stat_hash.fetch(k+'perlevel', nil) }
      end

      # then rename with friendlier titles, if available
      STATS_DECODE.each do |k, v|
        if bstat.keys.include?( k )
          bstat[STATS_DECODE[k]] = bstat[k]
          bstat.delete(k)
        end
      end
      return bstat
    end

    def process_passive( pass_hash )
      raise "invalid passive data" unless pass_hash.is_a?( Hash )
      cpass = Hash.new
      pass_hash.each do |pk, pv|
        case pk
        when 'name'
          cpass[:name] = pv
        when 'sanitizedDescription'
          cpass[:desc] = pv
        when 'image'
          cpass[:image] = pv['full']
          cpass[:image_url] = Champion.champ_passive_icon_url( pv['full'] )
        end
      end
      return cpass
    end
    
    def process_spells( spells )
      raise "invalid spell data" unless spells.is_a?( Array )
      ckey = Hash.new
      spellbutton = %w{ Q W E R }
      spells.each do |s|
        skey = ckey[s['key']] = Hash.new
        s.each do |sk, sv|
          case sk
          when 'name'
            skey[:name] = sv
          when 'sanitizedDescription'  # sanitizedTooltip is another option
            skey[:desc_short] = sv
          when 'image'
            skey[:image] = sv['full']
            skey[:image_url] = Champion.champ_ability_icon_url( sv['full'])
          when 'cooldownBurn'
            skey[:cooldown] = sv
          end
        end # each key for an individual spell
        skey[:desc] = process_spell_desc( s )
        skey[:cost] = process_spell_cost( s )
        skey[:hotkey] = spellbutton.shift
        skey[:raw] = s   # for debugging
      end # each spell
      return ckey
    end
    
    def process_spell_desc( spell_hash )
      # p spell_hash
      raise "invalid spell data" unless spell_hash.is_a?( Hash)
      # spell_hash['sanitizedTooltip']
      s = effect_sub( spell_hash['sanitizedTooltip'], spell_hash['effectBurn'] )
      if spell_hash['vars']
        s = var_sub( s, spell_hash['vars'] )
      end
      return s
    end
    
    def effect_sub( desc, effect_burn )
      raise 'invalid effect data' unless effect_burn.is_a?( Array )
      # puts "Effectburn: #{effect_burn}"
      desc.gsub(/\{\{\se(\d)\s\}\}/) { effect_burn[$1.to_i] }
    end

    def var_sub( desc, vars )
      raise 'invalid vars data' unless vars.is_a?( Array )
      desc.gsub(/\{\{\s([af]\d)\s\}\}/) do
        v = (vars.select {|x| x['key'] == $1}).first
        if v && v['coeff'].size == 1
          "#{v['coeff'].first}*#{VARS_DECODE[v['link']] ? VARS_DECODE[v['link']] : v['link']}"
        else
          # puts "failed - matching '#{$1}' versus '#{vars.map {|x| x['key']}}'"
          # puts vars
          # puts "Failed decode - \ndesc: #{desc}\nvars:#{vars.to_yaml}"
          "UNKNOWN (decoding #{$1})"
        end
      end # var replacement
    end

    def process_spell_cost( spell_hash )
      raise "invalid spell data" unless spell_hash.is_a?( Hash )
      s = cost_sub( spell_hash['resource'], spell_hash['costBurn'] )
      s = effect_sub( s, spell_hash['effectBurn'] )
    end

    def cost_sub( cost_desc, cost_burn )
      raise 'invalid cost data' unless cost_burn.is_a?( String )
      cost_desc.gsub(/\{\{\scost\s\}\}/) { cost_burn }
    end
  end  # class Champion
end

