# summoner.rb
#
#  Copyright (c) 2016 Godwin Liu, All Rights Reserved.
require 'json'
require_relative 'riot_api_connect'
require_relative 'champion_data'

module RiotData
  class Summoner
    include RiotAPIConnect

    SUMMONER_STATS_URL = '/v1.3/stats/by-summoner/'.freeze
      
    attr_reader :summ_id
    
    def initialize( riotkey, summ_id = 31287954 )
      @riotkey = riotkey
      @summ_id = summ_id
    end

    # return array with hash per champ in the current ranked season
    #  i.e. [{champ_id, wins, losses, played}, ..]
    def ranked_champ_stats
      rcr = self.ranked_champs
      rcs = rcr.map do |r|
        {id: r['id'], wins: r['stats']['totalSessionsWon'], losses: r['stats']['totalSessionsLost'], played: r['stats']['totalSessionsPlayed']}
      end
    end

    def ranked_champs
      params = {:api_key => @riotkey }
      uri = api_uri( SUMMONER_STATS_URL + @summ_id.to_s + '/ranked', params)
      r = get_json( uri )

      ro = JSON.parse(r.body)
      # puts ro['champions']

      rcr = ro['champions']
    end

  end
end
