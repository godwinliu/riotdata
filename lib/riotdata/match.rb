#  match.rb
#  Copyright (c) 2016 Godwin Liu, All Rights Reserved.

require_relative 'riot_data_object'
require 'json'

module RiotData

  MATCH_PATH = '/v2.2/match/'.freeze
  TEST_MATCH = 2157410441   # a test match where

  
  class Match < RiotDataObject
    attr_reader :match_id, :raw, :match_type, :match_date

    MATCH_MAPS = { 11 => "Summoner's Rift" }
    
    def initialize( match_id = TEST_MATCH )
      @match_id = match_id
      @raw = load_match
      raise "error loading match" unless @raw
      parse_match
    end

    def to_s
      out = "\nMatch Summary for match_id:" + match_id.to_s
      out << "\n\n\t" + match_type[:season] + " - " + match_type[:type] + " on " + match_type[:map]
      out << "\t(#{Match.convert_riot_time(match_date).strftime('%Y-%b-%e %l:%M%P')})\n"
    end
    
    private

    def load_match
      uri = api_uri( MATCH_PATH + @match_id.to_s )
      r = fetch_response(uri, true )
      JSON.parse( r.body )
    end

    def parse_match
      @match_type = {
        season: @raw['season'],
        version: @raw['matchVersion'],
        type: @raw['queueType'],
        map: MATCH_MAPS.fetch( @raw['mapId'], "unknown" )
      }
      @match_date = @raw['matchCreation']
    end
  end
end
