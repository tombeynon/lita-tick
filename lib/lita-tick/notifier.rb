module LitaTick
  class Notifier
    attr_reader :robot, :redis, :scheduler

    def initialize(robot, redis, scheduler)
      @robot = robot
      @scheduler = scheduler
    end

    def start
      # scheduler.cron '0 5 * * 1-5' do
      scheduler.cron '*/1 * * * *' do
        remind_users
      end
    end

    def remind_users
      users.each do |tick_id, user|
        target = Source.new(user: user['u_id'])
        robot.send_messages(target, tick_id)
        log.info "SENDING: #{tick_id} -> #{target}"
      end
    end

    def remind(user, tick_id)
      redis.hset('users', tick_id, {
        user_id: user.id
      })
    end

    private

    def users
      @users ||= redis.hget('users')
    end
  end
end
