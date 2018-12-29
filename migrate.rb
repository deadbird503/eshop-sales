require "sqlite3"

# Remove database and create table again.

begin
  con = SQLite3::Database.new "eshop.db"

  con.execute "DROP TABLE IF EXISTS game_sales"
  #con.execute "CREATE SEQUENCE game_sale_id_seq;"
  con.execute "CREATE TABLE game_sales(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    game_code VARCHAR(20),
    parsed_game_code VARCHAR(20),
    nsuid VARCHAR(20),
    region VARCHAR(20),
    title VARCHAR(75),
    cover_url VARCHAR(200),
    value decimal,
    onsale boolean,
    country VARCHAR(50)
  )"
rescue SQLite3::SQLException => e
  puts e.message
ensure
  con.close if con
end