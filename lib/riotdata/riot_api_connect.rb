# riot_api_connect.rb
#
#  mixin module - for connecting to riot servers
#
#  Copyright (c) 2016 Godwin Liu, All Rights Reserved.

require 'net/http'

module RiotAPIConnect
  REGION = 'na'.freeze
  SERVER = 'na.api.pvp.net'.freeze
  API_URL = '/api/lol'.freeze
  STATIC_URL = '/api/lol/static-data'.freeze

  def static_uri( path, params )
    url = 'https://' + SERVER + STATIC_URL + '/' + REGION + path
    uri = URI( url )
    uri.query = URI.encode_www_form(params)
    return uri
  end

  def api_uri( path, params )
    url = 'https://' + SERVER + API_URL + '/' + REGION + path
    uri = URI( url )
    uri.query = URI.encode_www_form(params)
    return uri
  end

  def get_json( uri )
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    puts "\tFetching URI: #{uri.to_s}"
    http.get(uri.request_uri)
  end
end
