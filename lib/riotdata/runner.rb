# runner.rb
#
#  runs the riotdata ruby application
#
#  Copyright (c) 2016 Godwin Liu, All Rights Reserved.

require_relative 'riot_data_object'
require_relative 'summoner'

module RiotData
  class Runner
    def initialize( api_key )
      RiotData::RiotDataObject.api_key = api_key
      puts "\n\tRiot Data Initializing... using api_key: #{api_key}\n"
      # put options parser here
    end

    def run
      s = Summoner.new( 31287954 )  # summoner: grandfromage
      puts "\tSummoner: #{s.name} (id=#{s.riot_id})"
      puts s.ranked_champ_stats_output
      puts s.recent_games_output
    end

  end
end
