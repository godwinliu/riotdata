#  test_summoner.rb
#  Copyright (c) 2016 Godwin Liu, All Rights Reserved.

require 'riotdata/summoner'
require 'net/http'
require 'test/unit'

class TestSummoner < Test::Unit::TestCase

  # save some typing
  SC = RiotData::Summoner  # the class being tested

  def setup
    raise "cannot run test without RIOT_KEY set" unless riotkey = ENV['RIOT_KEY']
  end
end

