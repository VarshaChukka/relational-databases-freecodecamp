#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -q -c"

echo "Enter your username:"
read -r USERNAME

# Escape single quotes in the username for SQL.
USERNAME_ESCAPED=$(printf '%s' "$USERNAME" | sed "s/'/''/g")

# Find the user.
USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME_ESCAPED'")

if [[ -z "$USER_ID" ]]
then
  USER_ID=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME_ESCAPED') RETURNING user_id")
  echo "Welcome, $USERNAME! It looks like this is your first time here."
else
  STATS=$($PSQL "SELECT COUNT(game_id), COALESCE(MIN(number_of_guesses), 0) FROM games WHERE user_id=$USER_ID")
  IFS="|" read -r GAMES_PLAYED BEST_GAME <<< "$STATS"
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))
NUMBER_OF_GUESSES=0

echo "Guess the secret number between 1 and 1000:"
read -r GUESS

while true
do
  if [[ ! "$GUESS" =~ ^[0-9]+$ ]]
  then
    echo "That is not an integer, guess again:"
    read -r GUESS
    continue
  fi

  GUESS_NUM=$((10#$GUESS))
  NUMBER_OF_GUESSES=$((NUMBER_OF_GUESSES + 1))

  if (( GUESS_NUM < SECRET_NUMBER ))
  then
    echo "It's higher than that, guess again:"
  elif (( GUESS_NUM > SECRET_NUMBER ))
  then
    echo "It's lower than that, guess again:"
  else
    break
  fi

  read -r GUESS
done

echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"

# Record the completed game.
$PSQL "INSERT INTO games(user_id, number_of_guesses) VALUES($USER_ID, $NUMBER_OF_GUESSES)" > /dev/null