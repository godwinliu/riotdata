#  riot_data_connector.rb
#  Copyright (c) 2016 Godwin Liu, All Rights Reserved.
#
#  mixin module for defining paths to riot server url's and paths

require 'net/http'

module RiotDataConnector
  SERVER_URL = 'https://na.api.pvp.net'.freeze
  STATIC_SERVER_URL = 'http://ddragon.leagueoflegends.com/cdn'.freeze
  
  REGION = '/na'.freeze
  API_PATH = '/api/lol'.freeze
  STATIC_DATA_PATH = '/api/lol/static-data'.freeze
  CHAMP_DATA_PATH = '/v1.2/champion'.freeze
  VERSION_PATH = '/v1.2/versions'.freeze

  CHAMP_IMAGE_PATH = '/img/champion'.freeze

  $api_key = nil
  
  def api_key=( key )
    $api_key = key
  end

  def api_key?
    $api_key ? true : false
  end

  def static_uri( path, params = {} )
    url = SERVER_URL + STATIC_DATA_PATH + REGION + path
    return form_uri( url, params )
  end

  def form_uri( url, params )
    uri = URI( url )
    unless p = merge_keyparam(params) then raise "bad data request param hash, or no api_key"; end
    uri.query = URI.encode_www_form(p)
    return uri
  end

  def merge_keyparam( h )
    unless h.is_a?( Hash ) && api_key? then return nil; end
    h.merge( {:api_key => $api_key} )
  end

  def fetch_response( uri, log = false )
    unless uri.is_a?( URI::HTTPS ) then raise "bad uri for data request"; end
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      puts "\n\tFetching URI: #{uri.to_s}" if log
      http.get(uri.request_uri)
      # TODO - implement some error handling here
  end

end
