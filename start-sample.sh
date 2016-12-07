#!/bin/bash

CONSUMER_KEY="twitter consumer key"
CONSUMER_SECRET="twitter secret key"
MONGO_HOST="mongodb IP address"
MONGO_DB="mongo DB name"

export CONSUMER_KEY CONSUMER_SECRET MONGO_HOST MONGO_DB

ruby ./app.rb
