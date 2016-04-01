# summoner.rb
#
#  Copyright (c) 2016 Godwin Liu, All Rights Reserved.

require_relative 'riot_data_object'
require 'json'

module RiotData
  class Summoner < RiotDataObject
    SUMMONER_PATH = '/v1.4/summoner/'.freeze
    SUMMONER_STATS_PATH = '/v1.3/stats/by-summoner/'.freeze
    attr_reader :summ_id, :riot_id, :name, :ppic, :level, :revdate
    
    def initialize( summ_id = 31287954, load_remote = true )
      @summ_id = summ_id
      load_summoner( load_remote )
    end

    # return array with hash per champ in the current ranked season
    def ranked_champ_stats( force_update = false )
      unless force_update || @rcs
        uri = Summoner.api_uri( SUMMONER_STATS_PATH + @summ_id.to_s + '/ranked' )
        r = Summoner.fetch_response( uri, true )
        ro = JSON.parse(r.body)
        # puts ro['champions']
        rcr = ro['champions']

        # [2016-Mar-31 GYL] much more data to be had here, but start simply:
        @rcs = rcr.map do |r|
          { id: r['id'],
            wins: r['stats']['totalSessionsWon'],
            losses: r['stats']['totalSessionsLost'],
            played: r['stats']['totalSessionsPlayed'] }
        end
      end
      return @rcs
    end

    # Does simple text processing to show the ranked champ stats
    def ranked_champ_stats_output( force_update = false )
      rcs = ranked_champ_stats( force_update )
      summ = rcs.select {|v| v[:id]==0}
      out = "\nRanked results for #{name} (at #{revdate.strftime('%Y%b%d,%l:%M%P')}) with #{rcs.size-1} champions, #{winloss(summ[0])}:\n"

      rcs.sort! {|a, b| b[:wins] <=> a[:wins] }
      rcs.each do |c|
        next if c[:id] == 0
        out << "\t\t #{'%-12.12s' % Summoner.champs[c[:id]]}:\t#{winloss(c)})\n"
      end
      return out
    end

    private

    # load the base summoner data
    #    TODO - handle summoner not found
    #    TODO - handle forbidden/denied response
    def load_summoner( use_remote )
      return unless use_remote
      uri = Summoner.api_uri( SUMMONER_PATH + @summ_id.to_s )
      r = Summoner.fetch_response( uri, true )
      ro = JSON.parse(r.body)
      raise "malformed summoner data response" unless ro.size == 1
      parse_summoner(ro.values.first)
    end
    
    def parse_summoner( summ_rdata )
      raise "can't parse summoner data" unless summ_rdata.is_a?( Hash )
      @riot_id = summ_rdata['id']
      @name = summ_rdata['name']
      @ppic = summ_rdata['profileIconId']
      @level = summ_rdata['summonerLevel']
      @revdate = Summoner.convert_riot_time( summ_rdata[ 'revisionDate'])
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
