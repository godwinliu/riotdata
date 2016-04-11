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
require 'tzinfo'
require 'json'

module RiotData
  SERVER_URL = 'https://na.api.pvp.net'.freeze
  STATIC_SERVER_URL = 'http://ddragon.leagueoflegends.com/cdn'.freeze
  
  REGION = '/na'.freeze
  API_PATH = '/api/lol'.freeze
  STATIC_DATA_PATH = '/api/lol/static-data'.freeze
  CHAMP_DATA_PATH = '/v1.2/champion'.freeze
  VERSION_PATH = '/v1.2/versions'.freeze

  CHAMP_IMAGE_PATH = '/img/champion'.freeze
  DEFAULT_TZ = 'America/Toronto'
  
  class RiotDataObject

    # class variables
    @@api_key = nil    # the application will only use a single key, for all data objects
    @@champ_data = nil # cache the static data relating to champions for use by all subclasses
    @@current_version = nil
    @@versions = nil
    @@timezone = TZInfo::Timezone.get( DEFAULT_TZ )
    
    # class methods
    def self.api_key=( key )
      @@api_key = key
      $api_key = key   # this to enable RiotDataConnector
    end

    def self.api_key?
      @@api_key && $api_key ? true : false
    end

    def self.current_version # accessor for current version data
      @@current_version ||= load_versions 
    end
    
    def self.champs  # accessor for champ names
      @@champ_data || load_champs
    end
      
    def self.champ_image_icon_url( champ_id )
      raise "invalid champ_id" unless self.champs.include?( champ_id )
      return STATIC_SERVER_URL + '/' + self.current_version + CHAMP_IMAGE_PATH + '/' + self.champs[champ_id][:image]
    end
    
    def self.static_uri( path, params = {} )
      url = SERVER_URL + STATIC_DATA_PATH + REGION + path
      return form_uri( url, params )
    end

    def static_uri( path, params = {} )
      RiotDataObject.static_uri( path, params )
    end
    
    def self.api_uri( path, params = {} )
      url = SERVER_URL + API_PATH + REGION + path
      return form_uri( url, params )
    end

    def api_uri( path, params = {} )
      RiotDataObject.api_uri( path, params )
    end
    
    def self.fetch_response( uri, log = false )
      unless uri.is_a?( URI::HTTPS ) then raise "bad uri for data request"; end
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      puts "\n\tFetching URI: #{uri.to_s}" if log
      http.get(uri.request_uri)
      # TODO - implement some error handling here
    end

    def fetch_response( uri, log = false)
      RiotDataObject.fetch_response( uri, log )
    end
    
    def self.time_zone
      @@timezone
    end
    
    def self.convert_riot_time( fnum )
      raise "riot time needed as fixnum for conversion" unless fnum.is_a?( Fixnum )
      riottime = DateTime.strptime( fnum.to_s[0...-3], '%s')  # riot stores in milliseconds from epoch
      localtime = @@timezone.utc_to_local(riottime)
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
      uri = static_uri( CHAMP_DATA_PATH, { champData: 'image'} )
      res = fetch_response( uri )
      champions = JSON.parse( res.body )
      @@champ_data = Hash.new
      champions['data'].each do |k, v|
        @@champ_data[v['id']] = {name: v['name'], image: v['image']['full']}
      end
      return @@champ_data
    end

    def self.load_versions
      uri = static_uri( VERSION_PATH )
      res = fetch_response(uri)
      @@versions = JSON.parse(res.body)
      return @@versions.first
    end
    
    private_class_method :merge_keyparam, :form_uri, :load_champs, :load_versions
    
  end
end
