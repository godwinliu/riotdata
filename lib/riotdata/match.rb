#  match.rb
#  Copyright (c) 2016 Godwin Liu, All Rights Reserved.

require_relative 'riot_data_object'
require 'json'
require 'yaml'  # for debugging

module RiotData

  MATCH_PATH = '/v2.2/match/'.freeze
  TEST_MATCH = 2157410441   # a test match where

  
  class Match < RiotDataObject
    attr_reader :match_id, :raw, :match_type, :match_date, :participants,
                :teams

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
      out << " v" + match_type[:version]
      out << "\t(#{Match.convert_riot_time(match_date).strftime('%Y-%b-%e %l:%M%P')})\n"

      # participants
      out << "\n\tParticipants:\n"
      team1 = participants.select {|k, v| v[:team] == 100}
      team2 = participants.select {|k, v| v[:team] == 200}

      team1id = team1.first[1][:team]
      out << "\n\t\tTeam: #{team1id} #{'(** WIN **)' if teams[team1id][:winner]}"
      team1.each do |k, v|
        out << "\n\t\t#{k}: #{'%6.6s' % v[:lane]} - #{'%-12.12s' % v[:role]}: "
        out << "#{v[:champ]} (#{v[:summoner]})"
      end

      out << "\n\n#{"\t"*5}Versus\n"

      team2id = team2.first[1][:team]
      out << "\n\t\tTeam: #{team2id} #{'(** WIN **)' if teams[team2id][:winner]}"
      team2.each do |k, v|
        out << "\n\t\t#{k}: #{'%6.6s' % v[:lane]} - #{'%-12.12s' % v[:role]}: "
        out << "#{v[:champ]} (#{v[:summoner]})"
      end
      return out
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
      @participants = parse_participants
      @teams = parse_teams
      return
    end

    def parse_participants
      ps = Hash.new
      @raw['participants'].each do |p|
        ps[p['participantId']] = {
          # raw: p,
          team: p['teamId'],
          champ_id: p['championId'],
          champ: Match.champs[p['championId']][:name],
          role: p['timeline']['role'],
          lane: p['timeline']['lane'],
          performance: p['timeline'],
          stats: p['stats']
        }
      end  # participant processing
      
      @raw['participantIdentities'].each do |p|
        pid = p['participantId']
        ps[pid][:summ_id] = p['player']['summonerId']
        ps[pid][:summoner] = p['player']['summonerName']
      end # identity processing
      
      return ps
    end

    def parse_teams
      ts = Hash.new
      @raw['teams'].each do |t|
        ts[t['teamId']] = {
          raw: t,
          winner: t['winner']
        }
      end
      return ts
    end
    
  end  # class
end
