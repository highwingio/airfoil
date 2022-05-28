# frozen_string_literal: true

require "middleware"

require_relative "airfoil/version"
require_relative "airfoil/middleware/set_request_id"
require_relative "airfoil/middleware/sentry_catcher"
require_relative "airfoil/middleware/sentry_monitoring"
require_relative "airfoil/middleware/function_name"
require_relative "airfoil/middleware/log_event"
require_relative "airfoil/middleware/database"
require_relative "airfoil/logger_patch"
require_relative "airfoil/railtie" if defined?(Rails::Railtie)

module Airfoil
  class << self
    def create_stack
      # ensure that STDOUT streams are synchronous so we don't lose logs
      $stdout.sync = true

      ::Middleware::Builder.new { |b|
        b.use Middleware::SetRequestId
        b.use Middleware::SentryCatcher
        b.use Middleware::SentryMonitoring
        b.use Middleware::LogEvent, Rails.logger
        yield b
      }.inject_logger(Rails.logger)
    end
  end
end
