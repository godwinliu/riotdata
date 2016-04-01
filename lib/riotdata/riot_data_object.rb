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
require 'date'

module RiotData
  REGION = '/na'.freeze
  SERVER_URL = 'https://na.api.pvp.net'.freeze
  API_PATH = '/api/lol'.freeze
  STATIC_DATA_PATH = '/api/lol/static-data'.freeze
  CHAMP_DATA_URL = '/v1.2/champion'.freeze
  
  class RiotDataObject

    # class variables
    @@api_key = nil    # the application will only use a single key, for all data objects
    @@champ_data = nil # cache the static data relating to champions for use by all subclasses
    
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

    def self.champs  # accessor for all static champ data
      @@champ_data || load_champs
    end
      
    def self.static_uri( path, params = {} )
      url = SERVER_URL + STATIC_DATA_PATH + REGION + path
      return form_uri( url, params )
    end

    def self.api_uri( path, params = {} )
      url = SERVER_URL + API_PATH + REGION + path
      return form_uri( url, params )
    end

    def self.fetch_response( uri, log = false )
      unless uri.is_a?( URI::HTTPS ) then raise "bad uri for data request"; end
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      puts "\n\tFetching URI: #{uri.to_s}" if log
      http.get(uri.request_uri)
      # TODO - implement some error handling here
    end

    def self.convert_riot_time( fnum )
      raise "riot time needed as fixnum for conversion" unless fnum.is_a?( Fixnum )
      DateTime.strptime( fnum.to_s[0...-3], '%s')  # riot stores in milliseconds from epoch
      # TODO - there's a time zone bug or something.. we're close but not accurate to hour.
    end
    
    # private class methods:
    
    def self.form_uri( url, params )
      uri = URI( url )
      unless p = merge_keyparam(params) then raise "bad data request param hash, or no api_key"; end
      uri.query = URI.encode_www_form(p)
      return uri
    end

    def self.merge_keyparam( h )
      unless h.is_a?( Hash ) && api_key? then return nil; end
      h.merge( {:api_key => @@api_key} )
    end

    def self.load_champs
      uri = static_uri( CHAMP_DATA_URL )
      res = fetch_response( uri )
      champions = JSON.parse( res.body )
      @@champ_data = Hash.new
      champions['data'].each {|k, v| @@champ_data[v['id']] = v['name'] }
      return @@champ_data
    end

    private_class_method :merge_keyparam, :form_uri, :load_champs
    
  end
end
