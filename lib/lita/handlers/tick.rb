module Lita
  module Handlers
    class Tick < Handler
      def self.scheduler
        @scheduler ||= Rufus::Scheduler.new
      end

      route(/^remind me to tick (\S+@\S+\.\S+)/, :add_reminder, command: true, help: {
        "remind me to tick EMAIL" => "Remind you at the end of the day if you haven't ticked"
      })

      route(/^stop reminding me to tick/, :remove_reminder, command: true, help: {
        "stop reminding me to tick" => "Stop reminding you about tick"
      })

      route(/^stop tick reminders until (\d{1,2})\/(\d{1,2})\/(\d{4})/, :stop_reminders, command: true, restrict_to: :tick_admins, help: {
        "stop tick reminders until DATE" => "Stop all reminders until DATE"
      })

      route(/^resume tick reminders/, :resume_reminders, command: true, restrict_to: :tick_admins, help: {
        "resume tick reminders" => "Resume all tick reminders"
      })

      on :loaded, :start_notifier

      config :api_token, type: String, required: true
      config :api_contact, type: String, required: true
      config :subscription_id, type: String, required: true
      config :reminder_time, type: String, default: '17:20'
      config :reminder_days, type: String, default: '1-5'

      attr_reader :notifier

      def start_notifier(payload)
        ::Tick.api_token = config.api_token
        ::Tick.subscription_id = config.subscription_id
        ::Tick.api_contact = config.api_contact

        notifier.start!(self.class.scheduler, config.reminder_time, config.reminder_days)
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

      def remove_reminder(response)
        if notifier.forget!(response.user)
          response.reply("All done. I was only trying to help")
        else
          response.reply("Chill, you didn't ask me to remind you")
        end
      end

      def stop_reminders(response)
        until_date = Date.new(*response.matches[0].reverse.map(&:to_i))
        notifier.stop_until!(until_date)
        response.reply("Tick reminders stopped until #{until_date}")
      end

      def resume_reminders(response)
        notifier.resume!
        response.reply("Tick reminders resumed")
      end

      def remind_user(user_id, tick_id)
        tick_user = LitaTick::User.find(tick_id)
        if tick_user && tick_user.needs_reminding?
          target = Lita::Source.new(user: user_id)
          robot.send_messages(target, "Don't forget to tick! You've entered #{tick_user.hours_posted_today} hours for today")
        elsif !tick_user
          target = Lita::Source.new(user: user_id)
          robot.send_messages(target, 'I couldn\'t access your tick account..')
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
