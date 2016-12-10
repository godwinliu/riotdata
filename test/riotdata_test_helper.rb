#  test_helper.rb
#  Copyright (c) 2016 Godwin Liu, All Rights Reserved.
#
#  (mixin) module for RiotData tests - common functionality

module RiotDataTest
  TESTED_VER = '6.24.1'

  def get_valid_key
    key = ENV['RIOT_KEY']
    flunk "Need to set RIOT_KEY env variable (with valid api_key from pvp.net)" unless key
    return key
  end
  
  def get_fake_key
    "123abc"
  end

  def get_lorem_ipsum
    "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
  end
end
