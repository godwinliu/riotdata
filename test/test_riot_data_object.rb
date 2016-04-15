#  test_riot_data_object.rb
#  Copyright (c) 2016 Godwin Liu, All Rights Reserved.
#

require 'riotdata/riot_data_object'
require 'net/http'
#require 'test/unit'
require 'minitest/autorun'
require 'json'
require_relative 'riotdata_test_helper'

class TestRiotDataObject < Minitest::Test
  include RiotDataTest
  
  # save some typing
  RDO = RiotData::RiotDataObject
  
  def setup
  end
  
  def test_should_be_able_to_set_api_key
    key = get_fake_key
    assert set_api_key(key)
  end

  def test_should_be_able_to_test_api_keyexist
    refute set_api_key(nil), "should delete key"
    refute RiotData::RiotDataObject.api_key?, "should return false for no key"
    assert set_api_key(get_fake_key)
    assert RiotData::RiotDataObject.api_key?, "should return true for existing key"
  end

  def test_should_cache_version
    assert set_api_key(get_valid_key)
    assert v1 = RiotData::RiotDataObject.current_version, "should return the current version of the game"
    assert_equal( TESTED_VER, v1 )
  end
  
  def test_should_cache_champion_static_data
    assert set_api_key(get_valid_key)
    assert set1 = RiotData::RiotDataObject.champs
    assert set2 = RiotData::RiotDataObject.champs # this is a duplicate assertion, to see if it triggers another fetch request to the server - log should show only one.
    assert_equal(set1, set2)
    # puts set1.inspect
  end

  def test_should_cache_champion_icon_url
    assert set_api_key(get_valid_key)
    champ_id = 96 # Kog'Maw
    assert i_url = RiotData::RiotDataObject.champ_image_icon_url( champ_id )
    expected = "http://ddragon.leagueoflegends.com/cdn/" + TESTED_VER + "/img/champion/KogMaw.png"
    assert_equal( expected, i_url )
  end

  def test_should_get_champ_passive_icon_url
    assert set_api_key(get_valid_key)
    img_name = "testimage.png"
    assert i_url = RDO.champ_passive_icon_url( img_name )
    expected = "http://ddragon.leagueoflegends.com/cdn/" + TESTED_VER + "/img/passive/" + img_name
  end

  def test_should_get_champ_ability_icon_url
    assert set_api_key(get_valid_key)
    img_name = "testimage.png"
    assert i_url = RDO.champ_ability_icon_url( img_name )
    expected = "http://ddragon.leagueoflegends.com/cdn/" + TESTED_VER + "/img/spell/" + img_name
  end
  
  def test_should_raise_exception_if_no_api_key_for_uri
    path = get_fake_path
    refute set_api_key(nil)
    assert_raises( RuntimeError ) { RiotData::RiotDataObject.api_uri(path) }
  end

  def test_should_form_static_data_api_uri
    key = get_fake_key
    path = get_fake_path
    expected = URI("https://na.api.pvp.net/api/lol/static-data/na" << path << "?api_key=" << key)
    assert set_api_key(key)
    assert_equal( expected, RDO.static_uri( path ) )
  end

  def test_instances_should_be_able_to_form_static_uri
    key = get_fake_key
    path = get_fake_path
    expected = URI("https://na.api.pvp.net/api/lol/static-data/na" << path << "?api_key=" << key)
    o = RDO.new
    assert set_api_key(key)
    assert_equal( expected, o.static_uri(path) )
  end

  def test_should_form_data_api_uri
    key = get_fake_key
    path = get_fake_path
    expected = URI("https://na.api.pvp.net/api/lol/na" << path << "?api_key=" << key)
    assert set_api_key(key)
    assert_equal( expected, RDO.api_uri( path ) )
  end

  def test_instances_should_be_able_to_form_api_uri
    key = get_fake_key
    path = get_fake_path
    expected = URI("https://na.api.pvp.net/api/lol/na" << path << "?api_key=" << key)
    o = RDO.new
    assert set_api_key(key)
    assert_equal( expected, o.api_uri( path ) )
  end

  def test_should_raise_exception_for_non_URI_fetch
    uri = get_fake_path
    assert set_api_key(get_fake_key)
    assert_raises( RuntimeError) { RiotData::RiotDataObject.fetch_response(uri)}
  end

  def test_should_fetch_forbidden_response_from_riot
    path = get_valid_path
    assert set_api_key(get_fake_key)
    assert uri = RiotData::RiotDataObject.api_uri( path )
    assert res = RiotData::RiotDataObject.fetch_response( uri )
    assert_equal(Net::HTTPForbidden, res.class)
    assert_equal('403', res.code)
  end

  def test_should_fetch_ok_response_from_riot
    key = get_valid_key
    path = get_valid_path
    assert set_api_key(key)
    assert uri = RiotData::RiotDataObject.api_uri( path )
    assert res = RiotData::RiotDataObject.fetch_response( uri )
    assert_equal(Net::HTTPOK, res.class)
    assert_equal('200', res.code)
    assert JSON.parse( res.body ).is_a?( Hash ), "successful response should be parsable into a ruby hash"
  end

  def test_instances_should_be_able_to_fetch_api_responses
    o = setup_valid_instance
    path = get_valid_path
    assert uri = o.api_uri( path )
    assert res = o.fetch_response( uri )
    assert_equal(Net::HTTPOK, res.class)
    assert_equal('200', res.code)
    assert JSON.parse( res.body ).is_a?( Hash ), "successful response should be parsable into a ruby hash"
  end

  def test_should_convert_riot_time
    rtime = 1459520093000
    assert d = RDO.convert_riot_time( rtime )
    assert d.is_a?( DateTime )
    assert_equal( "2016-Apr-01 10:14am", d.strftime('%Y-%b-%d %l:%M%P') )
  end

  def test_should_return_timezone
    assert tz = RDO.time_zone, "should return the default time zone"
    expect_default = 'America - Toronto'
    assert_equal( expect_default, tz.to_s )
  end

  def test_instance_should_have_word_wrap
    o = setup_valid_instance
    assert_equal( 1, get_lorem_ipsum.split("\n").size, "lorem ipsum in one line" )
    assert out = o.word_wrap( get_lorem_ipsum )
    assert_equal( 6, out.split("\n").size, "line width 80 should produce 6 lines" )
  end

  def test_instance_should_have_gamelength_out
    o = setup_valid_instance
    gl = 2293  # seconds
    expect = "38m 13s"
    assert_equal( expect, o.gamelength(gl), "should translate a game time into XXm YYs text")
  end
  
  private

  def get_valid_path
    path = "/v1.4/summoner/by-name/grandfromage"
  end
  
  def get_fake_path
    "/somepath"
  end

  def set_api_key( key )
    RiotData::RiotDataObject.api_key = key
  end

  def setup_valid_instance
    key = get_valid_key
    assert set_api_key(key)
    RDO.new
  end
end
