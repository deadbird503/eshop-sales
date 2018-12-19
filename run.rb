require 'pg'
require 'pry'

require 'json'

require File.expand_path("lib.rb")

load_env()

GAME_LIMIT = 200

=begin
1. Get all games and their ids.
2. Get all prices for the games.
3. If they are on sale, save them.
=end

games = get_games
games.each do |game|
  save_game game
end
game_ids = games.map{|game| game[:nsuid]}.select{|game| game != nil}

get_prices game_ids

binding.pry

1==1
