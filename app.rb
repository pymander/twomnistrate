# Sinatra example of OmniAuth Twitter with Orchestrate
# Built by Tejas Manohar
# Released under the Apache License 2.0 (apache.org/licenses/LICENSE-2.0.html)
# Open source on GitHub: http://github.com/tejasmanohar/omnistrate

### require gems

# manage your application's gem dependencies with less pain
require 'bundler/setup'

# orchestrate client for ruby
require 'orchestrate'

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

# setup orchestrate application
app = Orchestrate::Application.new(ENV['API_KEY'])

# set users to orchestrate collection
users = app[:users]

# create orchestrate method client
client = Orchestrate::Client.new(ENV['API_KEY'])

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
  @data = users.map {|user| [user.key, user.value['phrase']]}
  erb :all
end

# submit new phrase
get '/me' do
  # stop user if they're not logged in
  halt(401,'Not Authorized') unless logged_in?
  # set user's current phrase to instance var so it's available in view
  @phrase = users[session[:username]][:phrase] unless users[session[:username]].nil?
  erb :me
end

# capture user input
post '/me' do
  # does user exists in collection
  if users[session[:username]].nil?
    # if user inputted text, create user doc in collection
    users.create(session[:username], { 'phrase' => params[:phrase] }) unless params[:phrase].empty?
  else
    if params[:phrase].empty?
      # save selected doc in users
      doc = client.get(:users, session[:username])
      # delete doc based on its ref in collection
      client.delete(:users, session[:username], doc.ref)
    else
      # update phrase for doc in collection
      users.set(session[:username], { 'phrase' => params[:phrase] })
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
