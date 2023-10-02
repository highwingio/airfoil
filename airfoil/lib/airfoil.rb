# frozen_string_literal: true

require "middleware"

require_relative "airfoil/version"
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

      logger = defined?(::Rails) ? Rails.logger : Logger.new($stdout, level: (ENV["LOG_LEVEL"] || :info).to_sym)

      ::Middleware::Builder.new { |b|
        if defined?(::Rails)
          b.use Middleware::LoggerTagging, logger
        end
        b.use Middleware::SetRequestId
        # This is causing infinite recursion for some reason
        # b.use Middleware::LogEvent, logger
        yield b
      }.inject_logger(logger)
    end
  end
end
