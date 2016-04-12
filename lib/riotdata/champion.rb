#  champion.rb
#  Copyright (c) 2016 Godwin Liu, All Rights Reserved.
#
#  Library singleton class for accessing static data
#  relating to champions.

require_relative 'riot_data_object'
require 'json'
require 'singleton'

# require_relative 'riot_data_connector'

module RiotData
  class Champion < RiotDataObject
    include Singleton
    # include RiotDataConnector
    
    def list
      @champ_list || load_champs_list
    end

    def fetch( riot_champ_id )
      raise "champion_id must be on riot's list" unless list.keys.include?( riot_champ_id )
      uri = static_uri( CHAMP_DATA_PATH + '/' + riot_champ_id.to_s, {champData: 'all'} )
      r = fetch_response( uri, true )
      ro = JSON.parse(r.body )
      
      # [2016-Apr-11 GYL] inspect the json object
      #    puts "Keys: #{ro.keys}\n\n"
      #    nosubkeys = %w{ id key name title image }
      #    ro.each do |k, v|
      #      puts "\tKey: #{k}"
      #      puts "\t\tValues: #{v}\n\n"
      #      # puts "Subkeys: #{v.keys}\n" unless nosubkeys.include?( k )
      #    end

      c = Hash.new
      if ro
        ro.each do |k, v|
          case k
          when 'key'
            c[:key] = v
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
                when 'tooltip'
                  skey[:desc] = sv
                end
              end
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
    
    private
    
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

  end  # class Champion
end

