module Lita
  module Handlers
    class Tick < Handler
      def self.scheduler
        @scheduler ||= Rufus::Scheduler.new
      end

      route(/^tick remind (\d+)/, :add_reminder, command: true, help: {
        "tick remind me USER_ID" => "Remind you at 5pm to tick for USER_ID"
      })

      on :loaded, :start_notifier

      attr_reader :notifier

      def start_notifier
        @notifier ||= Notifier.new(robot, redis, self.class.scheduler)
        notifier.start
      end

      def add_reminder(response)
        if reminder = notifier.remind(response.user, response.matches[0])
          response.reply('Sure.')
        else
          response.reply("Ah, that didn't work. #{reminder}")
        end
      end

      Lita.register_handler(self)
    end
  end
end
