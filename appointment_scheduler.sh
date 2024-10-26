#!/bin/bash

PSQL="psql -U <user> -d business -t --no-align -c"

CUSTOMER_NAME=
CUSTOMER_PHONE=
SERVICE_ID_SELECTED=
SERVICE_TIME=
SERVICES=


// FUNCTIONS

function ADD_CUSTOMER () {
  echo -e "\nI don't have a record for that phone number, what's your name?"
  read CUSTOMER_NAME

  if [[ -z $CUSTOMER_NAME ]]
  then
    echo -e "\nThat is not a valid name. Try again.\n"
    ADD_CUSTOMER
  else
    ADD_CUSTOMER_RESULT=$($PSQL "
      INSERT INTO customers (name, phone) 
      VALUES ('$CUSTOMER_NAME', '$CUSTOMER_PHONE')
    ")

    if [[ $ADD_CUSTOMER_RESULT == 'INSERT 0 1' ]]
    then
      READ_TIME
    else
      echo -e "\nWell, fuck. That didn't work...\n"
    fi
  fi
}

function ADD_SERVICE () {
  CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE'")
  SERVICE_ID=$($PSQL "SELECT service_id FROM services WHERE name = '${SERVICES[$SERVICE_ID_SELECTED - 1]}'")

  INSERT_APPOINTMENT_RESULTS=$($PSQL "
    INSERT INTO appointments (customer_id, service_id, time)
    VALUES ('$CUSTOMER_ID', '$SERVICE_ID', '$SERVICE_TIME')
  ")

  if [[ $INSERT_APPOINTMENT_RESULTS != 'INSERT 0 1' ]]
  then
    echo "Fuck, you broke it..."
  else
    echo -e "\nI have put you down for a ${SERVICES[$SERVICE_ID_SELECTED - 1]} at $SERVICE_TIME, $CUSTOMER_NAME."
  fi
}

function ECHO_SERVICES () {
  SERVICES=($($PSQL "SELECT name FROM services"))

  for INDEX in ${!SERVICES[@]}
  do
    local UPDATED_INDEX=$(( INDEX + 1 ))
    local SERVICE="${SERVICES[$INDEX]}"
    echo -e "${UPDATED_INDEX}) ${SERVICE}"
  done

  READ_SERVICES ${#SERVICES[@]}
}

function INIT () {
  echo -e "\n~~~~~ <BUSINESS> ~~~~~\n"
  echo -e "\n Welcome to my <business>, how can I help you?\n"

  ECHO_SERVICES
}

function PHONE_LOOKUP () {
  local EXISTING_PHONE=$($PSQL "SELECT * FROM customers WHERE phone = '$CUSTOMER_PHONE'")
  
  if [[ -z $EXISTING_PHONE ]]
  then
    return 1 # Failure
  else
    return 0 # Success
  fi
}

function READ_SERVICES () {
  # Arguments:
  # $1: length of services

  read SERVICE_ID_SELECTED

  # If greater than services length; if 0; if not a number
  if [[ $SERVICE_ID_SELECTED -gt $1 ]] || [[ $SERVICE_ID_SELECTED == 0 ]] || [[ ! $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]]
  then
    echo -e "\nI could not find that service. What would you like today?\n"
    ECHO_SERVICES
  else
    READ_PHONE_NUMBER
  fi
}

function READ_PHONE_NUMBER () {
  echo -e "\nWhat's your phone number?"
  read CUSTOMER_PHONE

  if [[ -z $CUSTOMER_PHONE ]]
  then
    echo -e "\nI did not find that phone number."
    READ_PHONE_NUMBER
  else
    if ! PHONE_LOOKUP
    then
      ADD_CUSTOMER
    else
      CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone = '$CUSTOMER_PHONE'")
      READ_TIME
    fi
  fi
}

function READ_TIME () {
  echo -e "\nWhat time would you like your ${SERVICES[$SERVICE_ID_SELECTED - 1]}, $CUSTOMER_NAME?"
  read SERVICE_TIME

  if [[ -z $SERVICE_TIME ]]
  then
    echo -e "\nThat is not a valid time. Please enter a time in the format: HH:MM\n"
    READ_TIME
  else
    ADD_SERVICE
  fi
}

INIT
