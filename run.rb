require 'pg'
require 'pry'
require 'eu_central_bank'

require 'json'

require File.expand_path("lib.rb")

load_env()

exchange_rates_file = "exchange_rates.xml"

=begin
1. Save any games not already known.
2. For every game, get the price and whether they are on sale.
3. Update the game with the price and send notification if it turns on sale.
=end
puts DateTime.now.strftime("%d/%m/%Y %H:%M")

puts "Getting latest exchange rates from the ECB..."
eu_bank = EuCentralBank.new
Money.default_bank = eu_bank
eu_bank.save_rates(exchange_rates_file)
eu_bank.update_rates(exchange_rates_file)

puts "Getting games from the Nintendo API..."
games = get_games
puts "Found #{games.length} games."

puts "Saving all new games..."
games.each do |game|
  save_game game
end

game_ids = games.map{|game| game[:nsuid]}.select{|game| game != nil}

puts "Getting all prices for all games..."
prices = get_prices(game_ids).flatten
puts "Found #{prices.length} prices."

puts "Processing prices..."
lowest_prices = get_lowest_prices prices
lowest_prices.each do |price|
  process_price price
end