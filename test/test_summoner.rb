#  test_summoner.rb
#  Copyright (c) 2016 Godwin Liu, All Rights Reserved.

require 'riotdata/summoner'
require 'net/http'
#require 'test/unit'
require 'minitest/autorun'

class TestSummoner < Minitest::Test

  # expected test version
  TEST_VER = '6.7.1'
  STATIC_SERVER_URL = 'http://ddragon.leagueoflegends.com/cdn'
    
  # save some typing
  SC = RiotData::Summoner  # the class being tested

  def setup
    raise "cannot run test without RIOT_KEY set" unless riotkey = ENV['RIOT_KEY']
    SC.api_key = riotkey
  end

  # class tests
  
  def test_search_for_summoner
    assert s_id = SC.search_name( "superraygun" )
    assert s_id.is_a?( Integer ), "should return the id for an existing summoner"
    assert s = SC.new( s_id )
    assert s.is_a?( SC )
    assert_equal(s_id, s.summ_id)
    assert_equal(s_id, s.riot_id)

    unknown_summ = "asdlkfjawoijalkjerkajskfjalsdkjfalsdjflkaejflkasjelfkjasdkf"
    refute s_id = SC.search_name( unknown_summ )  # assumes unknown_summ is invalid search
  end

  def test_summonerclass_icon_url
    expect = STATIC_SERVER_URL + '/' + TEST_VER + '/img/profileicon/'
    assert_equal(expect, SC.icon_url)
  end
  
  # instance tests
  
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

  def test_return_icon_url
    s = setup_summoner
    assert s.ppic, "icon pic should be available for this summoner"
    expect = STATIC_SERVER_URL + '/' + TEST_VER + '/img/profileicon/' + s.ppic.to_s + ".png"
    assert_equal(expect, s.icon_url)
  end
  
  def test_ranked_champ_stats
    s = setup_summoner
    assert stats = s.ranked_champ_stats, "should return the champ stats"
    assert stats.is_a?( Array )  # it returns an array with one record per champ + a summary
    assert os = s.ranked_champ_stats_output, "should create an output string for the stats"
    assert os.is_a?( String )
  end

  def test_ranked_champ_stats_with_no_data
    skip "TODO - write test for case where summoner has no ranked champ stats"
  end
  
  def test_ranked_champ_stats_forced_update
    skip "TODO - write this test"  # need to be mindful of access limits to server
  end

  def test_recent_games
    s = setup_summoner
    assert rg = s.recent_games, "should return array of recent games"
    assert rg.is_a?( Array )
    assert os = s.recent_games_output, "should create an output string for the recent games"
    assert os.is_a?( String )
  end

  def test_recent_games_with_no_data
    skip "TODO - write test for case where summoner has no recent games"
  end
  
  def test_recent_games_forced_update
    skip "TODO - write test/consider access limits"
  end
  
  private

  def setup_summoner
    assert s = SC.new( 31287954 )  # use GrandFromage
    assert s.riot_id, "summoner request should have worked"
    return s
  end
end

