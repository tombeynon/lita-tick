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
      redis.hset('users', tick_id, {
        'user_id' => user.id
      })
    end

    def users
      redis.hgetall('users')
    end

    private

    def remind_users
      users.each do |tick_id, data|
        handler.remind_user(data['user_id'], tick_id)
      end
    end
  end
end
