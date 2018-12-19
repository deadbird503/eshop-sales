require 'pg'
require File.expand_path("lib.rb")

load_env()

begin
  con = PG.connect dbname: 'eshop', user: ENV.fetch("DB_USERNAME"), password: ENV.fetch("DB_PASSWORD")

  con.exec "DROP TABLE IF EXISTS game_sales"
  con.exec "CREATE SEQUENCE game_sale_id_seq;"
  con.exec "CREATE TABLE game_sales(id smallint NOT NULL DEFAULT nextval('game_sale_id_seq') PRIMARY KEY,
    game_code VARCHAR(20), parsed_game_code VARCHAR(20), nsuid VARCHAR(20),
    region VARCHAR(20), title VARCHAR(75),
    cover_url VARCHAR(200), on_sale INTEGER)"
  con.exec "ALTER SEQUENCE game_sale_id_seq OWNED BY game_sales.id;"
rescue PG::Error => e
  puts e.message
ensure
  con.close if con
end