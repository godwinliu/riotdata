#  riot_data_connector.rb
#  Copyright (c) 2016 Godwin Liu, All Rights Reserved.
#
#  mixin module for defining paths to riot server url's and paths
#
#  [2016-Apr-08 GYL] Note - in development - this repeats a lot of
#  code from RiotDataObject.  Those functions should eventually be
#  replaced by the ones here, in order to keep the library "DRY", if
#  the singleton code is better... but that's not really clear at the
#  moment..  it seems that inheriting a base object also has its
#  advantages...

require 'net/http'
require 'tzinfo'

module RiotDataConnector
  SERVER_URL = 'https://na.api.pvp.net'.freeze
  STATIC_SERVER_URL = 'http://ddragon.leagueoflegends.com/cdn'.freeze
  
  REGION = '/na'.freeze
  API_PATH = '/api/lol'.freeze
  STATIC_DATA_PATH = '/api/lol/static-data'.freeze
  CHAMP_DATA_PATH = '/v1.2/champion'.freeze
  VERSION_PATH = '/v1.2/versions'.freeze

  CHAMP_IMAGE_PATH = '/img/champion'.freeze
  DEFAULT_TZ = 'America/Toronto'

  $api_key = nil
  $timezone = TZInfo::Timezone.get( DEFAULT_TZ )
  $current_riot_version = nil
  
  def self.api_key=( key )
    $api_key = key
  end

  def api_key=( key )
    $api_key = key
  end

  def self.api_key?
    $api_key ? true : false
  end

  def api_key?
    $api_key ? true : false
  end

  def self.current_version
    $current_riot_version ||= load_versions
  end

  def self.load_versions
    # TODO - need to write such that this doesn't access an instance method
    uri = static_uri( VERSION_PATH )
    res = fetch_response(uri)
    $versions = JSON.parse(res.body)
    return $versions.first
  end
    
  def self.static_uri( path, params = {} )
    url = SERVER_URL + STATIC_DATA_PATH + REGION + path
    return form_uri( url, params )
  end

  def static_uri( path, params = {} )
    url = SERVER_URL + STATIC_DATA_PATH + REGION + path
    return form_uri( url, params )
  end

  def api_uri( path, params = {} )
    url = SERVER_URL + API_PATH + REGION + path
    return form_uri( url, params )
  end
  
  def self.form_uri( url, params )
    uri = URI( url )
    unless p = merge_keyparam(params) then raise "bad data request param hash, or no api_key"; end
    uri.query = URI.encode_www_form(p)
    return uri
  end

  def form_uri( url, params )
    uri = URI( url )
    unless p = merge_keyparam(params) then raise "bad data request param hash, or no api_key"; end
    uri.query = URI.encode_www_form(p)
    return uri
  end

  def self.merge_keyparam( h )
    unless h.is_a?( Hash ) && api_key? then return nil; end
    h.merge( {:api_key => $api_key} )
  end

  def merge_keyparam( h )
    unless h.is_a?( Hash ) && api_key? then return nil; end
    h.merge( {:api_key => $api_key} )
  end

  def self.fetch_response( uri, log = false )
    unless uri.is_a?( URI::HTTPS ) then raise "bad uri for data request"; end
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      puts "\n\tFetching URI: #{uri.to_s}" if log
      http.get(uri.request_uri)
      # TODO - implement some error handling here
  end

  def fetch_response( uri, log = false )
    unless uri.is_a?( URI::HTTPS ) then raise "bad uri for data request"; end
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      puts "\n\tFetching URI: #{uri.to_s}" if log
      http.get(uri.request_uri)
  end

end
