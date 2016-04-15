#  test_match.rb
#  Copyright (c) 2016 Godwin Liu, All Rights Reserved.

require 'riotdata/match'
require 'net/http'
require 'minitest/autorun'

require_relative 'riotdata_test_helper'

class TestMatch < Minitest::Test
  include RiotDataTest

  RM = RiotData::Match
  TEST_MATCH = 2157410441   # a test match where

  def test_should_get_match
    assert (m = setup_active_test), "should be able to get the test match"
    assert m.is_a?( RM )
    assert m.match_id, "should return the match_id"
    assert_equal( TEST_MATCH, m.match_id )
    assert m.raw, "should return the raw parsed hash"

    # and create readable attribs - these are not broken out, to minimize fetches
    attribs = {
      :raw => Hash,
      :match_id => Integer,
      :match_type => Hash,
      :match_date => Integer,
      :participants => Hash,
      :teams => Hash
    }

    attribs.each do |k, v|
      assert (res = m.send(k)), "match should respond to :#{k}"
      assert res.is_a?( v ), "response to :#{k} should be of class '#{v}'"
    end
  end

  private

  def setup_active_test( match_id = TEST_MATCH )
    RM.api_key = get_valid_key
    return RM.new( match_id )
  end
   
  
end
