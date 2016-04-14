# runner.rb
#
#  runs the riotdata ruby application
#
#  Copyright (c) 2016 Godwin Liu, All Rights Reserved.

require_relative 'riot_data_object'
require_relative 'summoner'
require_relative 'champion'
require_relative 'match'

module RiotData
  class Runner
    def initialize( api_key )
      RiotData::RiotDataObject.api_key = api_key
      puts "\n\tRiot Data Initializing... using api_key: #{api_key}\n"
      # put options parser here
    end

    def summ( search_name )
      id = Summoner.search_name( search_name )
      unless id.nil?
        s = Summoner.new( id )
        puts "\tSummoner: #{s.name} (id=#{s.riot_id})"
        puts s.ranked_champ_stats_output
        puts s.recent_games_output
      else
        puts "Summoner '#{search_name}' not found."
      end
    end

    def champ( search_champ = "Nasus" )
      co = Champion.instance
      id = co.search_name( search_champ ) 
      unless id.nil?
        puts co.show( id )
      else
        puts "\n\n*** No champion found by that name"
      end
    end

    # show match information for summ_name, wtih recent_index, where 0 is most recent, and 9 is max
    def match( summ_name, recent_index = 1 )
      puts "match args: #{summ_name}, and #{recent_index}\n\n"
      raise "invalid search parameter" unless summ_name.is_a? String
      raise "can't get game past 10 games ago" unless (0...9) === (recent_index-1)
      gameago = recent_index - 1
      id = Summoner.search_name( summ_name )
      unless id.nil?
        s = Summoner.new( id )
        print "\tFetching match data..for Summoner: #{s.name}.."
        print ( gameago == 0 ? "most recent game..\n" : "#{recent_index} game(s) ago..\n")

        gid = s.recent_games[gameago][:game_id]

        if gid
          print "\n\tLooking for game... #{gid}\n"
          m = Match.new( gid )
          puts m
        else
          print "\n\tAborting... no game found!\n"
        end
      else
        puts "Summoner '#{summ_name}' not found."
      end
    end
  end
end
