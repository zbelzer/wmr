require 'sinatra/base'
require 'yajl/json_gem'
require 'redis'
require 'erb'

module WMR
  class Server < Sinatra::Base
    dir = File.dirname(File.expand_path(__FILE__))
    set :views,  "#{dir}/server/views"
    set :public, "#{dir}/server/public"
    set :static, true

    get '/' do
      erb :index
    end

    get '/data' do
      content_type :json
      redis = Redis.new
      data = redis.sort("temp")
      "[" + data.join(',') + "]"
    end
  end
end
