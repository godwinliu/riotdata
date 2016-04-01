#  test_summoner.rb
#  Copyright (c) 2016 Godwin Liu, All Rights Reserved.

require 'riotdata/summoner'
require 'net/http'
#require 'test/unit'
require 'minitest/autorun'

class TestSummoner < Minitest::Test

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

  def test_ranked_champ_stats
    s = setup_summoner
    assert stats = s.ranked_champ_stats, "should return the hash of champ stats"
    assert stats.is_a?( Array )  # it returns an array with one record per champ + a summary
    assert os = s.ranked_champ_stats_output, "should create an output string for the stats"
    assert os.is_a?( String )
  end

  def test_ranked_champ_stats_forced_update
    skip "TODO - write this test"  # need to be mindful of access limits to server
  end

  private

  def setup_summoner
    assert s = SC.new( 31287954 )  # use GrandFromage
    assert s.riot_id, "summoner request should have worked"
    return s
  end
end

