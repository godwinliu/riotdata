#  test_riot_data_object.rb
#  Copyright (c) 2016 Godwin Liu, All Rights Reserved.
#

require 'riotdata/riot_data_object'
require 'net/http'
require 'test/unit'
require 'json'

class TestRiotDataObject < Test::Unit::TestCase

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

  def test_should_cache_champion_static_data
    assert set_api_key(get_valid_key)
    assert set1 = RiotData::RiotDataObject.champs
    assert set2 = RiotData::RiotDataObject.champs # this is a duplicate assertion, to see if it triggers another fetch request to the server - log should show only one.
    assert_equal(set1, set2)
    # puts set1.inspect
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
    assert_equal( expected, RiotData::RiotDataObject.static_uri( path ) )
  end

  def test_should_form_data_api_uri
    key = get_fake_key
    path = get_fake_path
    expected = URI("https://na.api.pvp.net/api/lol/na" << path << "?api_key=" << key)
    assert set_api_key(key)
    assert_equal( expected, RiotData::RiotDataObject.api_uri( path ) )
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

  private

  def get_valid_key
    key = ENV['RIOT_KEY']
    flunk "Need to set RIOT_KEY env variable (with valid api_key from pvp.net)" unless key
    return key
  end

  def get_valid_path
    path = "/v1.4/summoner/by-name/grandfromage"
  end
  
  def get_fake_key
    "123"
  end

  def get_fake_path
    "/somepath"
  end

  def set_api_key( key )
    RiotData::RiotDataObject.api_key = key
  end
  
end
