require 'pg'
require 'httparty'
require 'money'
require 'eu_central_bank'

require 'yaml'
require 'enumerator'

GAMES_URL = 'http://search.nintendo-europe.com/en/select'.freeze
DEFAULT_GAMES_PARAMS = {
  fl: 'product_code_txt,title,date_from,nsuid_txt,image_url_sq_s',
  fq: [
    'type:GAME',
    'system_type:nintendoswitch*',
    'product_code_txt:*',
  ].join(' AND '),
  q: '*',
  rows: 9999,
  sort: 'sorting_title asc',
  start: 0,
  wt: 'json',
}.freeze

COUNTRIES = %w[
  AT AU BE BG CA CH CY CZ DE DK EE ES FI FR GB GR HR HU IE IT JP LT LU LV MT MX NL NO NZ PL PT RO
  RU SE SI SK US ZA
].freeze

PRICES_URL = 'https://api.ec.nintendo.com/v1/price'.freeze
DEFAULT_PRICES_PARAMS = {
  lang: 'en',
}.freeze

def load_env
  env_file = File.expand_path("local_env.yml")
  YAML.load(File.open(env_file)).each do |key, value|
    ENV[key.to_s] = value
  end if File.exists?(env_file)
end

def get_games
  response = HTTParty.get(GAMES_URL, query: DEFAULT_GAMES_PARAMS)
  games = JSON.parse(response.body, symbolize_names: true)[:response][:docs]
  games.map do |game|
    {
      region: 'europe',
      game_code: game.dig(:product_code_txt, 0).strip.match(/\AHAC\w?(\w{4})\w\Z/)[1],
      raw_game_code: game.dig(:product_code_txt, 0),
      title: game[:title],
      release_date: Date.parse(game[:date_from]),
      nsuid: game.dig(:nsuid_txt, 0),
      cover_url: game[:image_url_sq_s],
    }
  end
end

def save_game game
  begin
    con = PG.connect dbname: 'eshop', user: ENV.fetch("DB_USERNAME"), password: ENV.fetch("DB_PASSWORD")

    result = con.exec "SELECT * FROM game_sales WHERE nsuid = '#{game[:nsuid]}'"
    if result.ntuples == 0
      # New game
      con.exec "INSERT INTO game_sales(id, region, game_code, parsed_game_code, title, nsuid, cover_url, onsale) VALUES (DEFAULT, '#{game[:region]}', '#{game[:raw_game_code]}', '#{game[:game_code]}', '#{game[:title].gsub("'", "")}', '#{game[:nsuid]}', '#{game[:cover_url]}', false)"
    else
      # Update game
      # For now, not needed.
    end
  rescue PG::Error => e
    puts e.message
    abort
  ensure
    con.close if con
  end
end

def get_prices(ids)
  COUNTRIES.map do |country|
    prices = get_prices_aux(country: country, ids: ids)
  end
end

def get_prices_aux(country: 'US', ids: [], limit: 50)
  prices = ids.enum_for(:each_slice, limit).flat_map do |ids_to_fetch|
    query = DEFAULT_PRICES_PARAMS.merge(country: country, ids: ids_to_fetch.join(','))
    response = HTTParty.get(PRICES_URL, query: query)
    JSON.parse(response.body, symbolize_names: true)[:prices]
  end
  prices.select! { |p| p && p.include?(:regular_price) }
  prices.map do |price|
    value = price.dig(:regular_price, :raw_value).to_f
    currency = price.dig(:regular_price, :currency)
    {
      nsuid: price[:title_id],
      country: country,
      status: price[:sales_status],
      currency: price.dig(:regular_price, :currency),
      value_in_cents: Money.from_amount(value, currency).cents,
    }
  end
end

def get_lowest_prices prices
  lowest_prices = {}

  prices.each do |price|
    begin
      exchanged_value = Money.new(price[:value_in_cents], price[:currency]).exchange_to("EUR")
    rescue Money::Currency::UnknownCurrency => e
      puts "Cannot exchange currency #{price[:currency]} to EUR! Skipping this price..."
      next
    end

    if lowest_prices[price[:nsuid]].nil? || exchanged_value < Money.new(lowest_prices[price[:nsuid]][:value], "EUR")
      # For this nsuid, we have found a price that is lower. Update it in the hash.
      lowest_prices[price[:nsuid]] = {
        value: exchanged_value.to_f,
        country: price[:country],
        onsale: (price[:status] == "onsale")
      }
    end
  end

  return lowest_prices
end

def process_price price
  begin
    con = PG.connect dbname: 'eshop', user: ENV.fetch("DB_USERNAME"), password: ENV.fetch("DB_PASSWORD")

    result = con.exec "SELECT * FROM game_sales WHERE nsuid = '#{price[0]}'"

    if result.ntuples == 0
      puts "The game with nsuid #{price[0]} was not found in the database!"
      return
    else
      result = result[0]

      if price[1][:onsale] && !result["value"].nil? && price[1][:value] < result["value"].to_f
        # We have found a sale price that is lower than the normal price!
        # Send a notification about this!
        send_notification ({
          value: price[1][:value],
          title: result["title"],
          cover_url: result["cover_url"],
          country: price[1][:country]
        })
      end

      # Always update the database with the latest lowest price.
      con.exec "UPDATE game_sales SET country = '#{price[1][:country]}', onsale = #{price[1][:onsale].to_s}, value = #{price[1][:value]} WHERE nsuid = '#{price[0]}'"
    end
  rescue PG::Error => e
    puts e.message
    abort
  ensure
    con.close if con
  end
end

def send_notification game
  result = HTTParty.post("https://api.telegram.org/bot#{ENV.fetch("TELEGRAM_BOT_TOKEN")}/sendMessage",
    body: {
      chat_id: "@eshopsales",
      text: "#{game[:title]} is now on sale for €#{game[:value]}!"
    }
  )

  if !result["ok"]
    puts "Something went wrong while sending the Telegram message!"
    puts result.inspect
  end
end