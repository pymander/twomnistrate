require 'sinatra'
require 'omniauth-twitter'
require_relative 'helpers'

use OmniAuth::Builder do
  provider :twitter, ENV['CONSUMER_KEY'], ENV['CONSUMER_SECRET']
end

enable :sessions

# login w/ twitter
get '/login' do
  # redirect to url generated by omniauth
  redirect to('/auth/twitter')
end

# twitter auth successful
get '/auth/twitter/callback' do
  erb :'401' unless logged_in?
  session[:username] = env['omniauth.auth']['info']['name']
  redirect '/input'
end