require 'net/http'
require "tick/client"
require "tick/user"
require "tick/entry"

module Tick
  class << self
    attr_accessor :subscription_id, :api_token, :api_contact
    
    def api_url
      "https://www.tickspot.com/#{subscription_id}/api/v2/"
    end
  end
end
