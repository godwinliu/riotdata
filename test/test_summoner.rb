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
    SC.api_key = riotkey
  end

  def test_init_summoner
    assert s = SC.new( 123, false )   # try it without loading anything
    assert s.is_a?( SC )
    assert_equal( 123, s.summ_id)
    refute s.riot_id, "no summoner object should be created, if remote loading is turned off"

    assert s2 = SC.new  # now try to load the default
    assert s2.summ_id
    assert s2.riot_id   # the riot data should load also
    assert s2.name
    assert s2.ppic
    assert s2.level
    assert s2.revdate
  end
end

