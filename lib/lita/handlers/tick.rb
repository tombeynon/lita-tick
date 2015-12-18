module Lita
  module Handlers
    class Tick < Handler
      def self.scheduler
        @scheduler ||= Rufus::Scheduler.new
      end

      route(/^tick remind me (.+)/, :add_reminder, command: true, help: {
        "tick remind me EMAIL" => "Remind you at the end of the day if you haven't ticked"
      })

      on :loaded, :start_notifier

      attr_reader :notifier

      def start_notifier(payload)
        notifier.start!(self.class.scheduler)
      end

      def add_reminder(response)
        tick_user = LitaTick::User.find_by_email(response.matches[0][0])
        if tick_user
          notifier.remind!(response.user, tick_user.id)
          response.reply('All set')
        else
          response.reply("I couldn't find that user")
        end
      end

      def remind_user(user_id, tick_id)
        tick_user = LitaTick::User.find(tick_id)
        if tick_user && tick_user.needs_reminding?
          target = Lita::Source.new(user: user_id)
          robot.send_messages(target, 'Don\'t forget to tick!')
        elsif !tick_user
          target = Lita::Source.new(user: user_id)
          robot.send_messages(target, 'Your tick account seems to have been deleted..')
        end
      end

      private

      def notifier
        @notifier ||= LitaTick::Notifier.new(self, redis, log)
      end

      Lita.register_handler(self)
    end
  end
end
