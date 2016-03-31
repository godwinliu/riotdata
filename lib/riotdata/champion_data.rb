# champion_data.rb
#
#  Copyright (c) 2016 Godwin Liu, All Rights Reserved.
require_relative 'riot_api_connect'
require 'json'

module RiotData
  class ChampionData
    include RiotAPIConnect
    
    CHAMP_URL = '/v1.2/champion'.freeze
    
    attr_reader :champs
    
    def initialize( riotkey )
      params = {:api_key => riotkey }
      # puts "\n\tAssembled URI: #{static_url( CHAMP_URL, params )}\n"
      uri = static_uri( CHAMP_URL, params )
      r = get_json( uri )
      champions = JSON.parse(r.body)
      # puts "\n Keys: #{champions.keys}\n\n"
      @champs = Hash.new
      champions['data'].each {|k, v| @champs[v['id']] = v['name'] }
      # puts "\t #{@champs.inspect}\n\n"
    end
    
  end
end
