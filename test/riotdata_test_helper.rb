#  test_helper.rb
#  Copyright (c) 2016 Godwin Liu, All Rights Reserved.
#
#  (mixin) module for RiotData tests - common functionality

module RiotDataTest
  TESTED_VER = '6.7.1'

  def get_valid_key
    key = ENV['RIOT_KEY']
    flunk "Need to set RIOT_KEY env variable (with valid api_key from pvp.net)" unless key
    return key
  end
  
  def get_fake_key
    "123abc"
  end
end
