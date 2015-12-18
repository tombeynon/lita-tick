module Tick
  class User
    extend Client

    def self.all
      get('users.json').map{|u| new(u) }
    end

    attr_reader :id, :first_name, :last_name, :email

    def initialize(params={})
      @id = params['id']
      @first_name = params['first_name']
      @last_name = params['last_name']
      @email = params['email']
    end
  end
end
