# eshop-sales
Telegram bot that sends a message every time a Switch game goes on sale in the Nintendo Eshop.

Every time run.rb is ran, it does this:
- Pull all games(only from Europe) from the Nintendo API.
- Get all prices, for all countries and for all games from the Nintendo API.
- Save the lowest price for each game.
- If a game is on sale and is the lowest price, send a telegram message.

## This project is badly coded hacky copy-pasted spaghetti code.
I didn't really care about code style or DRY when coding this because I just wanted to complete it as fast as possible. As such, this is not an example of my coding skills :P

## Dependencies
Uses plain ruby without rails. Uses postgresql to save game data. A cronjob is supplied to fire the script every hour. The other gems are for http requests and currency conversion.
