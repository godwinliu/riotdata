# summoner.rb
#
#  Copyright (c) 2016 Godwin Liu, All Rights Reserved.

require_relative 'riot_data_object'
require_relative 'riot_data_connector'
require 'json'

module RiotData
  SUMMONER_PATH = '/v1.4/summoner/'.freeze
  SUMMONER_ICON_PATH = '/img/profileicon/'.freeze  # on static server
  SUMMONER_SEARCHNAME_PATH = SUMMONER_PATH + 'by-name/'.freeze
  SUMMONER_STATS_PATH = '/v1.3/stats/by-summoner/'.freeze
  RECENT_GAMES_PATH = '/v1.3/game/by-summoner/'.freeze
    
  class Summoner < RiotDataObject
    include RiotDataConnector
    attr_reader :summ_id, :riot_id, :name, :ppic, :level, :revdate

    # class methods

    def self.search_name( name )
      raise "search_name needs string for search" unless name.is_a?( String )
      uri = api_uri( SUMMONER_SEARCHNAME_PATH + name )
      r = fetch_response( uri, true )
      ro = JSON.parse( r.body )
      if ro['status'] && ro['status']['status_code'] == 404
        return nil
      else
        return ro[name]['id']
      end
    end

    def self.icon_url
      return STATIC_SERVER_URL + '/' + self.current_version + SUMMONER_ICON_PATH
    end
    
    # instance methods
    
    def initialize( summ_id = 31287954, load_remote = true )
      @summ_id = summ_id
      load_summoner( load_remote )
    end

    # return a url to the profile icon
    def icon_url
      return Summoner.icon_url + self.ppic.to_s + ".png"
    end
    
    # return array with hash per champ in the current ranked season
    def ranked_champ_stats( force_update = false )
      if force_update || @rcs.nil?
        uri = api_uri( SUMMONER_STATS_PATH + @summ_id.to_s + '/ranked' )
        r = fetch_response( uri, true )
        ro = JSON.parse(r.body)
        rcr = ro['champions']

        unless rcr
          @rcs = []  # handle case: no ranked data
        else
          # [2016-Mar-31 GYL] much more data to be had here, but start simply:
          @rcs = rcr.map do |r|
            { champ_id: r['id'],
              champ: (Summoner.champs[r['id']] ? Summoner.champs[r['id']][:name] : ''),
              wins: r['stats']['totalSessionsWon'],
              losses: r['stats']['totalSessionsLost'],
              played: r['stats']['totalSessionsPlayed'] }
          end
        end # no data
      end
      return @rcs
    end

    # Does simple text processing to show the ranked champ stats
    def ranked_champ_stats_output( force_update = false )
      rcs = ranked_champ_stats( force_update )
      summ = rcs.select {|v| v[:champ_id]==0}
      out = "\nRanked results for #{name} (at #{revdate.strftime('%Y%b%d,%l:%M%P')}) with #{rcs.size-1} champions, #{winloss(summ[0])}:\n"

      rcs.sort! {|a, b| b[:wins] <=> a[:wins] }
      rcs.each do |c|
        next if c[:champ_id] == 0
        out << "\t\t #{'%-12.12s' % [c[:champ]]}:\t#{winloss(c)})\n"
      end
      return out
    end

    # return array with hash per game for recent games
    def recent_games( force_update = false )
      if force_update || @rg.nil?
        uri = api_uri( RECENT_GAMES_PATH + @summ_id.to_s + '/recent' )
        r = fetch_response( uri, true )
        ro = JSON.parse(r.body)
        unless ro['games']
          @rg = []
        else
          @rg = ro['games'].map do |g|
            { gametype: g['subType'],
              gamelength: g['stats']['timePlayed'],
              gamedate: g['createDate'],
              champ_id: g['championId'],
              champ: Summoner.champs[g['championId']][:name],
              role: g['stats']['playerRole'],
              win: g['stats']['win'],
              kills: g['stats']['championsKilled'],
              deaths: g['stats']['numDeaths'],
              assists: g['stats']['assists'],
              kda: kda( g['stats']['championsKilled'], g['stats']['numDeaths'], g['stats']['assists']),
              gold: g['stats']['goldEarned'],
              cs: g['stats']['minionsKilled'].to_i + g['stats']['neutralMinionsKilled'].to_i,
              champ_dmg: g['stats']['totalDamageDealtToChampions'] }
          end
        end # whether or not there's data
      end # force update
      return @rg
    end

    # Simple text output for recent games
    def recent_games_output( force_update = false )
      recent_games( force_update )
      out = "\nRecent #{@rg.size} games for #{name}:\n"
      @rg.each do |g|
        out << "\t\t#{'%-16.16s' % g[:gametype]} "
        out << "(#{Summoner.convert_riot_time(g[:gamedate]).strftime('%Y %b %e %l:%M%P')})"
        out << "\t#{g[:win] ? 'WIN':'LOSS'}"
        out << "\tas #{'%-12.12s' % g[:champ]}:"
        out << "\t#{g[:kills].to_i}/#{g[:deaths].to_i}/#{g[:assists].to_i}(#{g[:kda] == :perfect ? 'Perfect' : g[:kda]}),\t"
        glen = g[:gamelength].divmod(60)
        out << glen[0].to_s + "m" + glen[1].to_s + "s"
        gpm = g[:gold].to_f / (g[:gamelength] / 60)
        cspm = g[:cs].to_f / (g[:gamelength] / 60)
        out << "\tGold:#{g[:gold]}(#{gpm.round(1)}),\tCS:#{g[:cs]}(#{cspm.round(1)}), "
        out << "Dmg:#{g[:champ_dmg]}\n"
      end
      return out
    end
    
    private

    # load the base summoner data
    #    TODO - handle summoner not found
    #    TODO - handle forbidden/denied response
    def load_summoner( use_remote )
      return unless use_remote
      uri = api_uri( SUMMONER_PATH + @summ_id.to_s )
      r = fetch_response( uri, true )
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

    # calculate kda
    def kda( kills, deaths, assists)
      if deaths.nil? || deaths.zero? # avoid 0div
        kda = :perfect
      else
        kills || kills = 0
        assists || assists = 0
        kda = (kills.to_f + assists) / deaths
        kda.round(2)
      end
    end
  end
end
