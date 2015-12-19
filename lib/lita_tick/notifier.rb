module LitaTick
  class Notifier
    attr_reader :handler, :redis, :log

    def initialize(handler, redis, log)
      @handler = handler
      @redis = redis
      @log = log
    end

    def start!(scheduler)
      scheduler.cron '30 17 * * 1-5' do
        remind_users
      end
    end

    def remind!(user, tick_id)
      redis.hset('users', user.id, {
        'tick_id' => tick_id
      }.to_json)
    end

    def forget!(user)
      redis.hdel('users', user.id) > 0
    end

    def users
      redis.hgetall('users').inject({}) do |sum, (user_id, data)|
        sum[user_id] = JSON.parse(data)
        sum
      end
    end

    private

    def remind_users
      users.each do |user_id, data|
        handler.remind_user(user_id, data['tick_id'])
      end
    end
  end
end
