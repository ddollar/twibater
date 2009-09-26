require 'haml'
require 'sinatra'
require 'twitter'

get '/' do
  haml :index
end

get '/:username' do
  haml :error if params[:username].blank?
  haml :user
end

def find_twibates(entries)
  previous_reply_name = nil

  twibates = entries.inject({}) do |hash, entry|
    if entry.in_reply_to_screen_name == previous_reply_name
      hash[previous_reply_name] ||= 0
      hash[previous_reply_name]  += 1
    end
    previous_reply_name = entry.in_reply_to_screen_name
    hash
  end

  twibates.delete(nil)
  twibates.each do |key, value|
    twibates.delete(key) if value < 2
  end

  twibates
end

def stats(username)
  entries  = twitter.user_timeline(:id => username, :count => 200)
  total    = entries.length
  twibates = find_twibates(entries)
  count    = twibates.values.inject { |s,n| s+n }
  percent  = ((count.to_f / total * 10000).to_i.to_f / 100).to_s + '%'

  { :total => total, :count => count, :percent => percent, :twibates => twibates }
end

def twitter
  @twitter ||= begin
    auth = Twitter::HTTPAuth.new('', '')
    Twitter::Base.new(auth)
  end
end
