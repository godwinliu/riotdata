#  match.rb
#  Copyright (c) 2016 Godwin Liu, All Rights Reserved.

require_relative 'riot_data_object'
require 'json'
require 'yaml'  # for debugging

module RiotData

  MATCH_PATH = '/v2.2/match/'.freeze
  TEST_MATCH = 2157410441   # a test match where

  
  class Match < RiotDataObject
    attr_reader :match_id, :raw, :match_type, :match_date, :match_length,
                :participants, :teams

    MATCH_MAPS = { 11 => "Summoner's Rift" }
    DELTA_STATS = {
      cpmd: 'creepsPerMinDeltas',
      xppmd: 'xpPerMinDeltas',
      gpmd: 'goldPerMinDeltas',
      tpmd: 'damageTakenPerMinDeltas'
    }
    TIME_BINS = {
      'zeroToTen' => :t0to10,
      'tenToTwenty' => :t10to20,
      'twentyToThirty' => :t20to30,
      'thirtyToEnd' => :t30toEnd
    }
    TEAM_DECODE = {
      100 => 'Blue Team',
      200 => 'Red Team'
    }
    
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

      out << team_out( team1 )
      out << "\n\n#{"\t"*5}Versus\n"
      out << team_out( team2 )

      # performance
      out << "\n\n\tPerformance: (Gamelength: #{gamelength(match_length)} )\n"
      TIME_BINS.each do |tk, tv|
        case tv
        when :t0to10
          out << "\n\t0 to 10min:"
        when :t10to20
          out << "\n\t10 to 20min:"
        when :t20to30
          out << "\n\t20 to 30min:"
        when :t30toEnd
          out << "\n\t30 to end:"
        else
          out << "\n\tunknown time block:"
        end
        participants.each do |pk, pv|
          #out << "#{pk} - #{pv[:performance].to_yaml}"
          if outval = pv[:performance][:cpmd][tv]  # ensure these keys exist
            if pv[:summoner]
              out << "\n\t\t#{'%2.2s' % pk}: #{'%-20.20s' % pv[:summoner]} (/min deltas) -"
            else
              out << "\n\t\t#{'%2.2s' % pk}: #{'%-20.20s' % pv[:champ]} (/min deltas) -"
            end
            out << "\tcs: #{outval.round(1)}"
            field = participants.map {|k, v| v[:performance][:cpmd][tv]}
            out << ((field.inject(true) {|greatest, e| greatest && e <= outval}) ? "(*)" : "\t")
          end
          if outval = pv[:performance][:gpmd][tv]
            out << "\tgold: #{outval.round(1)}"
            field = participants.map {|k, v| v[:performance][:gpmd][tv]}
            out << ((field.inject(true) {|greatest, e| greatest && e <= outval}) ? "(*)" : "")
          end
          if outval = pv[:performance][:xppmd][tv]
            out << "\txp: #{outval.round(1)}"
            field = participants.map {|k, v| v[:performance][:xppmd][tv]}
            out << ((field.inject(true) {|greatest, e| greatest && e <= outval}) ? "(*)" : "")
          end
          if outval = pv[:performance][:tpmd][tv]
            out << "\ttank: #{outval.round(1)}"
            field = participants.map {|k, v| v[:performance][:tpmd][tv]}
            out << ((field.inject(true) {|greatest, e| greatest && e <= outval}) ? "(*)" : "")
          end
        end # participants
        out << "\n"
      end # timeblock
      return out
    end

#    def self.load_match( m_id)
#      uri = api_uri( MATCH_PATH + m_id.to_s )
#      r = fetch_response(uri, true )
#      JSON.parse( r.body )
#    end

    def self.load_detail( m_id )
      uri = api_uri(MATCH_PATH + m_id.to_s, {includeTimeline: true} )
      r = fetch_response(uri, true )
      JSON.parse(r.body)
    end
    
    private

    def load_match
      uri = api_uri( MATCH_PATH + @match_id.to_s )
      r = fetch_response(uri, true )
      JSON.parse( r.body )
    end

    def team_out( team )
      raise "invalid argument - should be a team (participant) hash" unless team.is_a?(Hash)
      out = String.new
      team_id = team.first[1][:team]
      out << "\n\t\tTeam: #{TEAM_DECODE[team_id]} #{'(** WIN **)' if teams[team_id][:winner]}"
      team.each do |k, v|
        out << "\n\t\t#{'%2.2s' % k}: #{'%6.6s' % v[:lane]} - #{'%-12.12s' % v[:role]}: "
        out << "#{'%13.13s' % v[:champ]}"
        out << "  #{self.kda_out(v[:stats]['kills'].to_i, v[:stats]['deaths'].to_i, v[:stats]['assists'].to_i)}"
        out << "\t(#{v[:summoner]})" if v[:summoner]
      end
      return out
    end

    def parse_match
      @match_type = {
        season: @raw['season'],
        version: @raw['matchVersion'],
        type: @raw['queueType'],
        map: MATCH_MAPS.fetch( @raw['mapId'], "unknown" )
      }
      @match_date = @raw['matchCreation']
      @match_length = @raw['matchDuration']
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
          performance: parse_performance(p['timeline']),
          stats: p['stats']
        }
      end  # participant processing

      @raw['participantIdentities'].each do |p|
        pid = p['participantId']
        ps[pid][:summ_id] = p['player'] ? p['player']['summonerId'] : nil
        ps[pid][:summoner] = p['player'] ? p['player']['summonerName'] : nil
      end # identity processing
      
      return ps
    end

    def parse_performance( t_hash )
      raise "bad timeline hash for participant" unless t_hash.is_a?( Hash )
      p = Hash.new
      DELTA_STATS.each do |dk, dkraw|
        p[dk] = Hash.new
        t_hash[dkraw].each do |k, v|
          p[dk][TIME_BINS[k]] = v
        end
      end
      return p
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
