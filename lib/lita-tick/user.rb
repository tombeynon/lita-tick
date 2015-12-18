module LitaTick
  class User < SimpleDelegator
    def needs_reminding?
      true
    end

    def self.find(id)
      users = Tick::User.all
      user = users.find{ |u| u.id == id }
      return new(user) if user
    end

    def self.find_by_email(email)
      users = Tick::User.all
      user = users.find{ |u| u.email == email }
      return new(user) if user
    end
  end
end
