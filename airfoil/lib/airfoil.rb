# frozen_string_literal: true

require "middleware"

require_relative "airfoil/version"
require_relative "airfoil/middleware/database"
require_relative "airfoil/middleware/function_name"
require_relative "airfoil/middleware/log_event"
require_relative "airfoil/middleware/logger_tagging"
require_relative "airfoil/middleware/set_request_id"
require_relative "airfoil/logger_patch"
require_relative "airfoil/railtie" if defined?(Rails::Railtie)

module Airfoil
  class << self
    def create_stack
      # ensure that STDOUT streams are synchronous so we don't lose logs
      $stdout.sync = true

      Signal.trap("TERM") do
        # We can't use the Rails logger here as the logger is not available in the trap context
        puts "Received SIGTERM, shutting down gracefully..." # rubocop:disable Rails/Output
      end

      ::Middleware::Builder.new { |b|
        b.use Middleware::LoggerTagging, Rails.logger
        b.use Middleware::SetRequestId
        b.use Middleware::Datadog
        b.use Middleware::SentryCatcher, Rails.logger
        b.use Middleware::SentryMonitoring
        b.use Middleware::LogEvent, Rails.logger
        yield b
      }.inject_logger(Rails.logger)
    end
  end
end
