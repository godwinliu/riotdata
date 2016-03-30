#!/usr/bin/env ruby

require 'net/http'
require 'json'

riotkey = 'fbd73303-e9cf-478d-bbb9-a77bf03bc905'

riot_status_server = 'status.leagueoflegends.com'
status_url = '/shards/na'

riotserver = 'na.api.pvp.net'
api_url = '/api/lol/na'
static_url = '/api/lol/static-data/na'

summoner_url = '/v1.4/summoner/by-name/'
summoner_stats_url = '/v1.3/stats/by-summoner/'
matchlist_url = '/v2.2/matchlist/by-summoner/'
champ_url = '/v1.2/champion'
item_url = '/v1.2/item'
game_url = '/v1.3/game/by-summoner/'

summoner = 'grandfromage'
summoner_id = '31287954'  # <= GrandFromage

url = 'https://' + riotserver + api_url
static_url = 'https://' + riotserver + static_url
# url << summoner_url << summoner
# url << matchlist_url << summoner_id
# url << summoner_stats_url << summoner_id << '/ranked'
# url << static_champ_url << '/101'
# url = static_url << champ_url << '/75'
# url = 'http://' + riot_status_server + status_url
# url = static_url << item_url
url << game_url << summoner_id << '/recent'

url << '?api_key=' + riotkey
url << '&champData=all'

params = { :api_key => riotkey }
params[:champData] = 'all'

puts "\nFetching.. '#{url}'\n"

uri = URI(url)
uri.query = URI.encode_www_form(params)

puts "\nURI: #{uri.inspect}\n"

http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true

res = http.get(uri.request_uri)

#Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
#  request = Net::HTTP::Get.new uri
#
#  response = http.request request
#end

# puts "Response: #{res.inspect}\n\n"
# puts "Response body: #{res.body.inspect}\n\n"

jsonobj = JSON.parse(res.body)

# puts "JSON obj: #{jsonobj.inspect}\n\n"
# puts "JSON obj keys: #{jsonobj.keys}\n\n"

 jsonobj.each do |k, v|
   puts "Keys: #{k.inspect}\n"
   puts "Values: #{v.inspect}\n" unless k=="games"

   # list the champions (static-data)
   # if k == 'data'
   #   puts "(total = #{v.size}): \n"
   #   v.each { |c, x| puts "\t" + x['name']  + " - " + x['title'] }
   #   puts "\n"
   # end

   # champion spells
   # if k == "spells"
   #   puts "(spells = #{v.size}): keys: #{v[0].keys}\n"
   #   v.each { |s| puts "\t" + s['name'] + ' - ' + s['tooltip'] }
   #   puts "\n"
   # end

   # (recent) games
   if k == "games"
     puts "(games = #{v.size}):  keys: #{v[0].keys}\n"
   end
 end

