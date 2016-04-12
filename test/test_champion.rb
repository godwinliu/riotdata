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
    assert set_api_key( key )
  end

  def test_should_be_able_to_test_api_keyexist
    c = RC.instance
    refute set_api_key( nil), "should delete key"
    refute RC.api_key?, "should return false for no key"
    assert set_api_key( get_fake_key)
    assert RC.api_key?, "should return true for existing key"
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

  def test_should_fetch_champion_info
    c = setup_active_test
    testchamp = 75  # should be Nasus
    cl = c.list
    assert cl.keys.include?( testchamp ), "the champ requested (for testing) should be on the full champ list"
    assert cdata = c.fetch( testchamp )
    expected_keys = [ :key, :title, :image, :stats, :spells, :passive ]
    expected_keys.each do |k|
      assert cdata[k], "champ returned should have key: :#{k}"
#      puts "\tKey: #{k}"
#      if k == :spells
#        puts "\t\tSpell keys: #{cdata[k].values.first.keys}"
#      else
#        puts "\t\tValues: #{cdata[k]}"
#      end
    end
    assert_equal( 4, cdata[:spells].size, "there should be 4 spells")
    flunk "TODO - write test"
  end
  
  private
  
  def set_api_key( key )
    RC.api_key = key
  end

  def setup_active_test
    RC.api_key = get_valid_key
    c = RC.instance
    return c
  end
end
