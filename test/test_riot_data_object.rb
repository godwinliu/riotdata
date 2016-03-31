#  test_riot_data_object.rb
#  Copyright (c) 2016 Godwin Liu, All Rights Reserved.
#

require 'riotdata/riot_data_object'
require 'net/http'
require 'test/unit'
require 'json'

class TestRiotDataObject < Test::Unit::TestCase

  def test_should_be_able_to_set_api_key
    key = "12345"
    assert RiotData::RiotDataObject.api_key = key
  end

  def test_should_be_able_to_test_api_keyexist
    refute RiotData::RiotDataObject.api_key = nil, "should delete key"
    refute RiotData::RiotDataObject.api_key?, "should return false for no key"
    assert RiotData::RiotDataObject.api_key = "something"
    assert RiotData::RiotDataObject.api_key?, "should return true for existing key"
  end

  def test_should_raise_exception_if_no_api_key_for_uri
    path = "/somepath"
    refute RiotData::RiotDataObject.api_key = nil
    assert_raises( RuntimeError ) { RiotData::RiotDataObject.api_uri(path) }
  end

  def test_should_form_static_data_api_uri
    key = "123abc"
    path = "/somepath"
    expected = URI("https://na.api.pvp.net/api/lol/static-data/na" << path << "?api_key=" << key)
    assert RiotData::RiotDataObject.api_key = key
    assert_equal( expected, RiotData::RiotDataObject.static_uri( path ) )
  end

  def test_should_form_data_api_uri
    key = "123abc"
    path = "/somepath"
    expected = URI("https://na.api.pvp.net/api/lol/na" << path << "?api_key=" << key)
    assert RiotData::RiotDataObject.api_key = key
    assert_equal( expected, RiotData::RiotDataObject.api_uri( path ) )
  end

  def test_should_raise_exception_for_non_URI_fetch
    key = "123"
    uri = "bibbityboop"
    assert RiotData::RiotDataObject.api_key = key
    assert_raises( RuntimeError) { RiotData::RiotDataObject.fetch_response(uri)}
  end

  def test_should_fetch_forbidden_response_from_riot
    key = "123"
    path = "/v1.4/summoner/by-name/grandfromage"
    assert RiotData::RiotDataObject.api_key = key
    assert uri = RiotData::RiotDataObject.api_uri( path )
    assert res = RiotData::RiotDataObject.fetch_response( uri )
    assert_equal(Net::HTTPForbidden, res.class)
    assert_equal('403', res.code)
  end

  def test_should_fetch_ok_response_from_riot
    key = ENV['RIOT_KEY']
    flunk "Need to set RIOT_KEY env variable (with valid api_key from pvp.net)" unless key
    path = "/v1.4/summoner/by-name/grandfromage"
    assert RiotData::RiotDataObject.api_key = key
    assert uri = RiotData::RiotDataObject.api_uri( path )
    assert res = RiotData::RiotDataObject.fetch_response( uri )
    assert_equal(Net::HTTPOK, res.class)
    assert_equal('200', res.code)
    assert JSON.parse( res.body ).is_a?( Hash ), "successful response should be parsable into a ruby hash"
  end
end
