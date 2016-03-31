# runner.rb
#
#  runs the riotdata ruby application
#
#  Copyright (c) 2016 Godwin Liu, All Rights Reserved.

require_relative 'summoner'
require_relative 'champion_data'

module RiotData
  class Runner
    def initialize( api_key )
      @api_key = api_key
      puts "\n\tRiot Data Initializing... using api_key: #{@api_key}\n"
      # TODO - put options parser here
    end

    def run
      s = Summoner.new @api_key
      puts "\tSummonerID: #{s.summ_id}"
      cd = ChampionData.new @api_key
      # puts "\t Champs init: #{cd.champs}\n"

      rcr = s.ranked_champs
      summ = rcr.select {|i| i['id'] == 0}
      puts "\nRanked results with #{rcr.size-1} champions, #{winloss(summ[0]['stats'])} )\n"

      rcr.sort! {|a, b| b['stats']['totalSessionsWon'] <=> a['stats']['totalSessionsWon'] }
      rcr.each do |ch|
        next if ch['id'] == 0
        chs = ch['stats']
        print "\t\t #{'%-12.12s' % cd.champs[ch['id']]}:\t#{winloss(chs)})"
        print "\n"
      end

      rcs = s.ranked_champ_stats
      puts rcs
    end

    private

    # return a win/loss string from a summoner stat hash
    def winloss( s )
      # puts s.inspect
      return nil if !s.is_a?( Hash )
      win = s.fetch('totalSessionsWon', 0)
      loss = s.fetch('totalSessionsLost', 0)
      n = s.fetch('totalSessionsPlayed')
      return "#{win}/#{loss}\t(n=#{n},\t#{(win.to_f*100/n).round(1)}%)"
    end
    
  end
end
