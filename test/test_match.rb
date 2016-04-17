#  test_match.rb
#  Copyright (c) 2016 Godwin Liu, All Rights Reserved.

require 'riotdata/match'
require 'net/http'
require 'minitest/autorun'

require_relative 'riotdata_test_helper'

class TestMatch < Minitest::Test
  include RiotDataTest

  RM = RiotData::Match
  TEST_MATCH = 2157410441

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

  def test_should_raise_if_match_not_found
    should_not_find = "1234567891234"   # there shouldn't be any matches in the trillion range yet
    assert_raises( RuntimeError) { setup_active_test( should_not_find ) }
  end
  
  def test_should_raise_unless_match_id_is_integer
    should_not_allow = "abc-match"   # match_id's are supposed to be integers...
    assert_raises( RuntimeError) { setup_active_test( should_not_allow ) }
  end
  
  private

  def setup_active_test( match_id = TEST_MATCH )
    RM.api_key = get_valid_key
    return RM.new( match_id )
  end
   
  
end
