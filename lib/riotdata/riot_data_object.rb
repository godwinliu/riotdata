#  riot_data_object.rb
#  Copyright (c) 2016 Godwin Liu, All Rights Reserved.
#
#  base class for riot data api back-ended objects.
#    this can be subclassed for each of the different
#    kinds of data objects so that they can be abstracted
#    in ruby.
#
#  this class also takes care of handshaking and uri/url
#    requests to the riot api servers, and, in general,
#    returns ruby objects after they have been parsed by
#    json..
#

require 'net/http'

module RiotData
  REGION = '/na'.freeze
  SERVER_URL = 'https://na.api.pvp.net'.freeze
  API_PATH = '/api/lol'.freeze
  STATIC_DATA_PATH = '/api/lol/static-data'.freeze

  class RiotDataObject

    # class variables
    @@api_key = nil   # => the application will only use a single key, for all data objects
    
    # class methods
    def self.api_key=( key )
      @@api_key = key
    end

    def self.api_key?
      @@api_key ? true : false
    end

    # for debugging:
    # def self.api_key
    #  @@api_key
    # end
    
    def self.static_uri( path, params = {} )
      url = SERVER_URL + STATIC_DATA_PATH + REGION + path
      return form_uri( url, params )
    end

    def self.api_uri( path, params = {} )
      url = SERVER_URL + API_PATH + REGION + path
      return form_uri( url, params )
    end

    def self.get_json( uri )
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      puts "\tFetching URI: #{uri.to_s}"
      http.get(uri.request_uri)
    end

    private

    def self.merge_keyparam( h )
      unless h.is_a?( Hash ) && api_key? then return nil; end
      h.merge( {:api_key => @@api_key} )
    end

    def self.form_uri( url, params )
      uri = URI( url )
      unless p = merge_keyparam(params) then raise "bad data request param hash, or no api_key"; end
      uri.query = URI.encode_www_form(p)
      return uri
    end
  end
end
