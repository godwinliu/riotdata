#!/usr/bin/env ruby

require 'net/http'
require 'json'

riotkey = 'fbd73303-e9cf-478d-bbb9-a77bf03bc905'

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
# url = static_url << champ_url << '/75'
# url = 'http://' + riot_status_server + status_url
# url = static_url << item_url
# url << game_url << summoner_id << '/recent'

# url << '?api_key=' + riotkey
# url << '&champData=all'

# --------- Get Champion Data ------------
url = static_url << champ_url
params = { :api_key => riotkey }
# params[:champData] = 'all'
# params[:champData] = 'info'

uri = URI(url)
uri.query = URI.encode_www_form(params)

puts "\nFetching URI: #{uri.to_s}\n"

http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true

res = http.get(uri.request_uri)
champions = JSON.parse(res.body)

# puts "\n Keys: #{champions.keys}\n\n"

puts "\n Champions (version #{champions['version']}, #{champions['data'].count} Total)\n"
achamps = Hash.new
champions['data'].each { |k, v| achamps[v['id']] = v['name'] }
# puts "\t #{achamps.inspect}\n\n"

# --------- Now Get Recent Match Data ------------
url = 'https://' + riotserver + api_url
url << game_url << summoner_id << '/recent'
params = {:api_key => riotkey}

uri = URI(url)
uri.query = URI.encode_www_form(params)

puts "\nFetching URI: #{uri.to_s}\n"

http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true

res = http.get(uri.request_uri)
jsonobj = JSON.parse(res.body)

jsonobj.each do |k, v|
  puts "Keys: #{k.inspect}\n"
  puts "Values: #{v.inspect}\n" unless k == 'games'

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
    # puts "(games = #{v.size}):  keys: #{v[0].keys}\n"
    puts "\t\t#{v.size} Games:\n"
    v.each do |g|
      # puts g.inspect + "\n"
      gs = g['stats']
      cs = gs['minionsKilled'].to_i + gs['neutralMinionsKilled'].to_i
      cspm = cs.to_f / (gs['timePlayed'] / 60)
      glen = gs['timePlayed'].divmod(60)
      glen_str = glen[0].to_s + "m" + glen[1].to_s + "s"
      gpm = gs['goldEarned'].to_f / (gs['timePlayed'] / 60)
      print "\t\t #{'%-16.16s' % g['subType']}\t#{gs['win'] ? 'WIN':'LOSS'}"
      print "\tas #{'%-12.12s' % achamps[g['championId']]}:"
      print "\t#{gs['championsKilled'].to_i}/#{gs['numDeaths'].to_i}/#{gs['assists'].to_i},\t"
      print glen_str
      print "\tGold:#{gs['goldEarned']}(#{gpm.round(1)}),\tCS:#{cs}(#{cspm.round(1)}), Dmg:#{gs['totalDamageDealtToChampions']}\n"
    end
  end
end

