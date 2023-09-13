require "spec_helper"
require "aws_lambda_ric/lambda_context"
require "airfoil/middleware/logger_tagging"
require "airfoil/cloudwatch_formatter"
require "active_support/tagged_logging"
require "active_support/logger"

RSpec.describe Airfoil::Middleware::LoggerTagging do
  let(:buf) { StringIO.new }
  let(:logger) do
    l = Logger.new(buf)
    l.formatter = Airfoil::CloudwatchFormatter.new
    ActiveSupport::TaggedLogging.new(l)
  end
  let(:request_id) { SecureRandom.uuid }
  let(:trace_id) { "1-5759e988-bd862e3fe1be46a994272793" }
  let(:request) { {"Lambda-Runtime-Aws-Request-Id" => request_id} }
  let(:context) { LambdaContext.new(request) }

  let(:stack) do
    Middleware::Builder.new do |b|
      b.use described_class, logger
      b.use lambda { |env| logger.info("Foobar") }
    end
  end

  before do
    ENV["_X_AMZN_TRACE_ID"] = trace_id
  end

  it "includes the trace ID in the log event" do
    stack.call(event: "test", context: context)

    expect(buf.string).to match(/\[#{trace_id}\]/)
  end

  it "includes the request ID in the log event" do
    stack.call(event: "test", context: context)

    expect(buf.string).to match(/\[#{request_id}\]/)
  end
end
