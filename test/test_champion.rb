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
    flunk
  end

  def test_should_be_able_to_set_api_key
    key = get_fake_key
    assert set_api_key( key )
  end

  def test_should_be_able_to_test_api_keyexist
    refute set_api_key(nil), "should delete key"
    refute RC.api_key?, "should return false for no key"
    assert set_api_key(get_fake_key)
    assert RC.api_key?, "should return true for existing key"
  end

  def set_api_key( key )
    RiotData::Champion.api_key = key
  end
end
