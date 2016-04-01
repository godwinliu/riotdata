# summoner.rb
#
#  Copyright (c) 2016 Godwin Liu, All Rights Reserved.

require_relative 'riot_data_object'
require 'json'

module RiotData
  class Summoner < RiotDataObject
    SUMMONER_STATS_PATH = '/v1.3/stats/by-summoner/'.freeze
    attr_reader :summ_id
    
    def initialize( summ_id = 31287954 )
      @summ_id = summ_id
    end

    # return array with hash per champ in the current ranked season
    #  i.e. [{champ_id, wins, losses, played}, ..]
    def ranked_champ_stats
      rcs = ranked_champs
      summ = rcs.select {|v| v[:id]==0}
      puts "\nRanked results with #{rcs.size-1} champions, #{winloss(summ[0])}\n"

      rcs.sort! {|a, b| b[:wins] <=> a[:wins] }
      rcs.each do |c|
        next if c[:id] == 0
        print "\t\t #{'%-12.12s' % Summoner.champs[c[:id]]}:\t#{winloss(c)})"
        print "\n"
      end
    end

    private

    def ranked_champs
      uri = Summoner.api_uri( SUMMONER_STATS_PATH + @summ_id.to_s + '/ranked' )
      r = Summoner.fetch_response( uri, true )
      ro = JSON.parse(r.body)
      # puts ro['champions']
      rcr = ro['champions']

      # [2016-Mar-31 GYL] much more data to be had here, but start simply:
      rcs = rcr.map do |r|
        {id: r['id'], wins: r['stats']['totalSessionsWon'], losses: r['stats']['totalSessionsLost'], played: r['stats']['totalSessionsPlayed']}
      end
    end

    # return a win/loss string from a summoner stat hash
    def winloss( s )
      # puts s.inspect
      return nil if !s.is_a?( Hash )
      win = s.fetch(:wins, 0)
      loss = s.fetch(:losses, 0)
      n = s.fetch(:played)
      return "#{win}/#{loss}\t(n=#{n},\t#{(win.to_f*100/n).round(1)}%)"
    end

  end
end
