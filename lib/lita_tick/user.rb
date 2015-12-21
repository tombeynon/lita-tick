module LitaTick
  class User < SimpleDelegator
    def hours_posted_today
      entries_for_today.reduce(0){|sum, e| sum + e.hours }
    end

    def entries_for_today
      @entries_for_today ||= find_entries_for_today
    end

    def self.find(id)
      users = Tick::User.all
      user = users.find{ |u| u.id.to_s == id.to_s }
      return new(user) if user
    end

    def self.find_by_email(email)
      users = Tick::User.all
      user = users.find{ |u| u.email == email }
      return new(user) if user
    end

    private

    def find_entries_for_today
      params = {
        user_id: id,
        start_date: Date.today,
        end_date: Date.today
      }
      Tick::Entry.where(params)
    end
  end
end
