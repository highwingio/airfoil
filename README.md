# Airfoil

_Enough structure to get our Lambda handlers in the air._

Airfoil is curated middleware stack that abstracts away common infrastructure
needed for Lambda handler functions.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'airfoil'
```

And then execute:

    bundle install

Or install it yourself as:

    gem install airfoil

## Usage

You can instantiate a new handler with an Airfoil stack like so:

```ruby
require_relative "config/environment"

STACK = Airfoil.create_stack do |b|
  # Custom middleware and handlers go here
  b.use Airfoil::Middleware::FunctionName, DbReset, "db-reset"
  b.use Airfoil::Middleware::FunctionName, UpdateUpcomingRenewals, "update-upcoming-renewals"
end

def handler(event:, context:)
  STACK.call({event: event, context: context})
end
```

Airfoil also includes a stack of middleware that you can add to or customize to
suit your specific needs. Your own middleware can inherit from the base class and
implement their own behavior like so:

```ruby
class MyResolverMiddleware < Airfoil::Middleware::Base
  def call(env)
    ApplicationResolver.handle(env[:event], env[:context])
  end
end
```

Existing middleware include:

- `FunctionName` - dispatch any calls made to a specific Lambda function (by name) to a specified handler class
- `LogEvent` - log AWS events in a pretty format
- `SetRequestId` - set the `AWS_REQUEST_ID` environment variable for your function code

## Additional Middleware

There are additional middleware available as separate gems that provide specific functionality. They must be explicitly added to your middleware stack in `create_stack`.

### Sentry

Add the `airfoil-sentry` gem to your Gemfile.This provides three middlewares:

- `SentryCatcher` - catch exceptions and report them to Sentry, including context:

```ruby
b.use Airfoil::Middleware::SentryCatcher
```

- `SentryMonitoring` - instrument your function code for Sentry's performance monitoring

```ruby
b.use Airfoil::Middleware::SentryMonitoring
```

### ActiveRecord

Add the `airfoil-activerecord` gem to your Gemfile. This provides a single middleware:

- `DatabaseConnection` - Check a connection in/out and enable the query cache per handler

```ruby
b.use Airfoil::Middleware::DatabaseConnection
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).
