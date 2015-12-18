require "lita"

Lita.load_locales Dir[File.expand_path(
  File.join("..", "..", "locales", "*.yml"), __FILE__
)]

require 'rufus-scheduler'
require "tick"
require "lita_tick/notifier"
require "lita_tick/user"
require "lita/handlers/tick"

Lita::Handlers::Tick.template_root File.expand_path(
  File.join("..", "..", "templates"),
 __FILE__
)
