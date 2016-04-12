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
      out << "\n\tPassive: #{c[:passive][:name]}\n"
      out << "\t"
      out << word_wrap(c[:passive][:desc], {separator: "\n\t"})
      out << "\n"
      c[:spells].each do |sk, sv|
        out << "\n\t#{sv[:name]} (#{sv[:hotkey]})\n"
        out << "\t"
        out << word_wrap(sv[:desc], {separator: "\n\t"})
        out << "\n"
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
            c[:stats] = v
          when 'spells'
            ckey = c[:spells] = Hash.new
            v.each do |s|
              skey = ckey[s['key']] = Hash.new
              s.each do |sk, sv|
                case sk
                when 'name'
                  skey[:name] = sv
                when 'sanitizedDescription'
                  skey[:desc_short] = sv
                # when 'sanitizedTooltip'  # tooltip also available with color suggestion
                #  skey[:desc] = sv
                end
              end
              skey[:desc] = process_spell( s )
              skey[:hotkey] = decode_spellkey( s['key'] )
              # for debugging:
              skey[:raw] = s
            end
          when 'passive'
            cpass = c[:passive] = Hash.new
            v.each do |pk, pv|
              case pk
              when 'name'
                cpass[:name] = pv
              when 'sanitizedDescription'
                cpass[:desc] = pv
              when 'image'
                cpass[:image] = pv['full']
              end
            end
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

    def process_spell( spell_hash )
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
          puts "failed - matching '#{$1}' versus '#{vars.map {|x| x['key']}}'"
          puts vars
          puts "Failed decode - \ndesc: #{desc}\nvars:#{vars.to_yaml}"
          "UNKNOWN (decoding #{$1})"
        end
      end # var replacement
    end

    def decode_spellkey( spell_key )
      raise "invalid spell_key" unless spell_key.is_a?( String )
      spell_key[-1]
    end
  end  # class Champion
end

