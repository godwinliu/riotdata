#  test_champion.rb
#  Copyright (c) 2016 Godwin Liu, All Rights Reserved.

require 'riotdata/champion'
require 'net/http'
require 'minitest/autorun'
require_relative 'riotdata_test_helper'

class TestChampion < Minitest::Test
  include RiotDataTest

  # save some typing
  RC = RiotData::Champion
  
  def test_champion_should_be_singleton_class
    assert_raises( NoMethodError) { c = RC.new }
  end

  def test_should_be_able_to_set_api_key
    key = get_fake_key
    c = RC.instance
    assert set_api_key( c, key )
  end

  def test_should_be_able_to_test_api_keyexist
    c = RC.instance
    refute set_api_key(c, nil), "should delete key"
    refute c.api_key?, "should return false for no key"
    assert set_api_key(c, get_fake_key)
    assert c.api_key?, "should return true for existing key"
  end

  def test_get_champion_list
    c = setup_active_test
    testchamp = 75  # should be Nasus
    testchampname = "Nasus"
    testimagename = "Nasus.png"
    assert cl = c.list, "Should be able to get full champion list"
    assert cl.is_a?(Hash), "should return a Hash of champions, keyed by riot_id"
    assert cl.keys.include?( testchamp ), "the array should include riot_id champion # #{testchamp}"
    assert cl[testchamp].keys.include?( :name ), "the array should include champion's name"
    assert_equal( testchampname, cl[testchamp][:name] )
    assert cl[testchamp].include?( :image ), "the array should include champion's image"
    assert_equal( testimagename, cl[testchamp][:image] )
  end
  
  private
  
  def set_api_key( c, key )
    raise "requires singleton instance" unless c.is_a?(RC)
    c.api_key = key
  end

  def setup_active_test
    c = RC.instance
    c.api_key = get_valid_key
    return c
  end
end
