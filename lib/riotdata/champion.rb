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

