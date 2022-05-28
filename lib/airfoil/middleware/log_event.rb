require "dry-monads"
require "active_support"
require "active_support/core_ext/hash/except"
require "airfoil/middleware/base"

module Airfoil
  module Middleware
    class LogEvent < Middleware::Base
      include Dry::Monads[:maybe]

      def initialize(app, logger)
        super(app)
        @logger = logger
      end

      def call(env)
        event = env[:event]

        logged_data = {
          "identity" => log_identity(event),
          "event" => log_event(event)
        }.to_json

        @logger.info(logged_data)
        result = @app.call(env)
        # Log the full result instead of the truncated version the middleware outputs
        @logger.info({result: result}.to_json)
        result
      end

      private

      # Clear unwanted properties from our log output
      def clean_event(event)
        unwanted_fields = %w[identity]
        event.except(*unwanted_fields)
      end

      def log_event(event)
        return event if event.is_a?(String)

        # Remove the full identity from our event output
        if event.is_a?(Array)
          event.map { |e| clean_event(e) }
        else
          clean_event(event)
        end
      end

      def log_identity(event)
        identity = case event
        in [e, *rest]
          e.dig("identity")
        in Hash
          event.dig("identity")
        else
          nil
        end

        Maybe(identity).bind { |i|
          Some({
            groups: i.dig("groups"),
            source_ip: i.dig("sourceIp"),
            sub: i.dig("sub"),
            auth_time: i.dig("claims", "auth_time")
          })
        }.value_or(nil)
      end
    end
  end
end
