module LitaTick
  class Notifier
    attr_reader :handler, :redis, :log

    def initialize(handler, redis, log)
      @handler = handler
      @redis = redis
      @log = log
    end

    def start!(scheduler, reminder_time='17:20', reminder_days='1-5')
      time_parts = reminder_time.split(':')
      scheduler.cron "#{time_parts[1]} #{time_parts[0]} * * #{reminder_days}" do
        send
      end
    end

    def remind!(user, tick_id)
      redis.hset('users', user.id, {
        'tick_id' => tick_id
      }.to_json)
    end

    def send
      return if stopped?
      send!
    end

    def send!
      send_reminders
    end

    def stop_until!(date)
      redis.set('stop_until', date)
    end

    def resume!
      redis.del('stop_until')
    end

    def forget!(user)
      redis.hdel('users', user.id) > 0
    end

    def stopped?
      date = redis.get('stop_until')
      if date && Date.parse(date) > Date.today
        return true
      else
        return false
      end
    end

    private

    def send_reminders
      users.each do |user_id, data|
        handler.remind_user(user_id, data['tick_id'])
      end
    end

    def users
      redis.hgetall('users').inject({}) do |sum, (user_id, data)|
        sum[user_id] = JSON.parse(data)
        sum
      end
    end
  end
end
