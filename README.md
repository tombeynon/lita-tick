# lita-tick

[![Build Status](https://travis-ci.org/tombeynon/lita-tick.png?branch=master)](https://travis-ci.org/tombeynon/lita-tick)
[![Coverage Status](https://coveralls.io/repos/tombeynon/lita-tick/badge.svg?branch=master&service=github)](https://coveralls.io/github/tombeynon/lita-tick?branch=master)

A Lita handler to remind you fill in your [Tick](http://www.tickspot.com).

## Installation

Add lita-tick to your Lita instance's Gemfile:

``` ruby
gem "lita-tick", github: 'tombeynon/lita-tick'
```

## Configuration

``` ruby
Lita.configure do |config|
  config.handlers.tick.api_token = 'ADMIN API TOKEN'
  config.handlers.tick.subscription_id = 'SUBSCRIPTION ID'
  config.handlers.tick.api_contact = 'API CONTACT EMAIL'
  config.handlers.tick.reminder_time = '17:20'
  config.handlers.tick.reminder_days = '1-5'
end
```

## Usage

```
lita remind me to tick mytickemail@company.com
#=> All set

# Monday-Friday at 17:20 
#=> Don't forget to tick! You've entered 2.0 hours today 

lita stop reminding me to tick
#=> All done. I was only trying to help

```

### Admin functions available to tick_admins 

```
lita stop tick reminders until 1/1/2016
#=> Tick reminders stopped until 2016-01-01

lita resume tick reminders
#=> Tick reminders resumed
```

## License

[MIT](http://opensource.org/licenses/MIT)
