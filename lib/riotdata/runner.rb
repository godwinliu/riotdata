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
      s = Summoner.new
      puts "\tSummonerID: #{s.summ_id}"
      s.ranked_champ_stats
    end

  end
end
