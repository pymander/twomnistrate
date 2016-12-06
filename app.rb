# Sinatra example of OmniAuth Twitter with MongoDB
# Built by Tejas Manohar (https://github.com/tejasmanohar)
# Updated by Erik L. Arneson (https://arnesonium.com/)
# Released under the Apache License 2.0 (apache.org/licenses/LICENSE-2.0.html)
# Open source on GitHub: http://github.com/pymander/twomnistrate

### require gems

# manage your application's gem dependencies with less pain
require 'bundler/setup'

# MongoDB client for ruby
require 'mongo'

# classy web-development dressed in a dsl
require 'sinatra'

# require default group bundler
Bundler.require

# require certain gems only in dev env
configure :development do
  # advanced code reloader for sinatra
  require 'sinatra/reloader'
  # an irb alternative and runtime developer console
  require 'pry'
end


### sinatra settings

configure do
  # set 'sessions' setting true
  enable :sessions
end


### configure api clients

# setup MongoDB client
client = Mongo::Client.new('mongodb://' +  ENV['MONGO_HOST'] + ':27017/' + ENV['MONGO_DB'])
db = client.database

# set users to MongoDB collection
users = db[:users]

# setup omniauth with twitter oauth2 provider
use OmniAuth::Builder do
  provider :twitter, ENV['CONSUMER_KEY'], ENV['CONSUMER_SECRET']
end

### helper methods

helpers do
  # check if user is logged in via session var
  def logged_in?
    session[:authed]
  end
end

### routes

# homepage
get '/' do
  # redirect to list if logged in
  if logged_in?
    redirect '/all'
  else
    erb :home
  end
end

# list all users with their corresponding phrase
get '/all' do
  # enumerates over all users to build array of [username, phrase]'s
  @data = users.find.map {|user| [user['username'], user['phrase']]}
  erb :all
end

# submit new phrase
get '/me' do
  # stop user if they're not logged in
  halt(401,'Not Authorized') unless logged_in?
  # set user's current phrase to instance var so it's available in view
  user = users.find({ username: session[:username] }).first
  if user
    @phrase = user['phrase']
  end
  erb :me
end

# capture user input
post '/me' do
  # Create the document hash that we might need later.
  doc = { 'username' => session[:username],
          'phrase' => params[:phrase] };
  user = users.find({ username: session[:username] }).first

  puts 'Username: ' + session[:username];
  
  # does user exists in collection
  unless user
    # if user inputted text, create user doc in collection
    users.insert_one(doc) # unless params[:phrase].empty?
  else
    if params[:phrase].empty?
      # delete doc from MongoDB
      users.delete_one({username: session[:username]})
    else
      # update phrase for doc in collection
      users.find_one_and_update({ username: session[:username]}, doc)
    end
  end
  # send browser to phrase listings
  redirect '/all'
end

# logout
get '/logout' do
  # change session var to reflect logout
  session[:authed] = nil
  erb :out
end

# login
get '/auth/twitter/callback' do
  # change session var to reflect login
  session[:authed] = true
  session[:username] = request.env['omniauth.auth']['info']['nickname']
  erb :in
end

# login failure
get '/auth/failure' do
  # display full error message
  params[:message]
end
