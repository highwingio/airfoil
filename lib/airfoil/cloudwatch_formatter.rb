require "logger"

module Airfoil
  class CloudwatchFormatter < Logger::Formatter
    def call(severity, datetime, progname, msg)
      "#{severity} RequestId: #{ENV["AWS_REQUEST_ID"]} #{msg}\n"
    end
  end
end
