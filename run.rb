require 'pry'
require 'eu_central_bank'

require 'json'

require File.dirname(__FILE__) + "/lib.rb"

load_env()

exchange_rates_file = File.dirname(__FILE__) + "/exchange_rates.xml"

puts DateTime.now.strftime("%d/%m/%Y %H:%M")

##########################################################

puts "Getting latest exchange rates from the ECB..."
eu_bank = EuCentralBank.new
Money.default_bank = eu_bank
eu_bank.save_rates(exchange_rates_file)
eu_bank.update_rates(exchange_rates_file)

##########################################################

puts "Getting games from the Nintendo API..."
games = get_games
puts "Found #{games.length} games."

##########################################################

puts "Saving all new games..."
games[0..1].each do |game|
  save_game game
end

##########################################################

game_ids = games[0..1].map{|game| game[:nsuid]}.select{|game| game != nil}

puts "Getting all prices for all games..."
prices = get_prices(game_ids).flatten
puts "Found #{prices.length} prices."

##########################################################

puts "Processing prices..."
lowest_prices = get_lowest_prices prices
lowest_prices.each do |price|
  process_price price
end