require 'pg'
require File.expand_path("lib.rb")

load_env()

begin
  con = PG.connect dbname: 'eshop', user: ENV.fetch("DB_USERNAME"), password: ENV.fetch("DB_PASSWORD")

  con.exec "DROP TABLE IF EXISTS game_sales"
  con.exec "CREATE TABLE game_sales(id INTEGER PRIMARY KEY,
    game_code VARCHAR(20), parsed_game_code VARCHAR(20), nsuid VARCHAR(20),
    region VARCHAR(20), title VARCHAR(75), release_date date, cover_url VARCHAR(75))"
rescue PG::Error => e
  puts e.message
ensure
  con.close if con
end