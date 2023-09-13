require "spec_helper"
require "aws_lambda_ric/lambda_context"
require "airfoil/middleware/log_event"
require "airfoil/cloudwatch_formatter"
require "active_support/tagged_logging"
require "active_support/logger"

RSpec.describe Airfoil::Middleware::LogEvent do
  let(:logger) do
    ActiveSupport::TaggedLogging.new(
      Logger.new($stdout)
    ).tap do |l|
      l.formatter = Airfoil::CloudwatchFormatter.new
    end
  end
  let(:request_id) { SecureRandom.uuid }
  let(:identity) {
    {
      "claims" => {
        "auth_time" => 1639513547,
        "secrets" => "top-secret"
      },
      "groups" => ["test"],
      "sourceIp" => ["0.0.0.0"],
      "sub" => "test-id",
      "otherStuff" => "junk"
    }
  }
  let(:request) {
    {
      "Lambda-Runtime-Deadline-Ms" => 300,
      "Lambda-Runtime-Aws-Request-Id" => request_id,
      "Lambda-Runtime-Invoked-Function-Arn" => "some::arn"
    }
  }
  let(:context) {
    LambdaContext.new(request)
  }
  let(:logged_identity) {
    {
      groups: ["test"],
      source_ip: ["0.0.0.0"],
      sub: "test-id",
      auth_time: 1639513547
    }
  }
  let(:stack) {
    Middleware::Builder.new { |b|
      b.use Airfoil::Middleware::SetRequestId
      b.use described_class, logger
    }
  }

  before do
    ENV["AWS_LAMBDA_LOG_GROUP_NAME"] = "ruby/ses-lambda"
    ENV["AWS_LAMBDA_LOG_STREAM_NAME"] = "log-stream"
    ENV["AWS_LAMBDA_FUNCTION_NAME"] = "ses-lambda"
    ENV["AWS_LAMBDA_FUNCTION_MEMORY_SIZE"] = "16"
    ENV["AWS_LAMBDA_FUNCTION_VERSION"] = "1"
    allow(logger).to receive(:info)
  end

  it "sets AWS request id to an env var" do
    allow(logger).to receive(:info).and_return("INFO RequestId: #{request_id} {\"identity\":null,\"event\":{}}")
    expect {
      stack.call(event: {}, context: context)
    }.to change { ENV["AWS_REQUEST_ID"] }.from(nil).to(request_id)
  end

  it "reports the event as a string" do
    allow(logger).to receive(:info).and_call_original
    stack.call(event: "test", context: context)

    expect(logger).to have_received(:info).with({
      identity: nil,
      event: "test"
    }.to_json)
  end

  it "reports the event as a Hash object" do
    allow(logger).to receive(:info).and_call_original
    event = {"a" => "a", "identity" => identity}

    stack.call(event: event, context: context)

    expect(logger).to have_received(:info).with({
      identity: logged_identity,
      event: {a: "a"}
    }.to_json)
  end

  it "reports the event as an Array" do
    allow(logger).to receive(:info).and_call_original

    event = [
      {"a" => "a", "identity" => identity},
      {"b" => "b", "identity" => identity}
    ]
    stack.call(event: event, context: context)

    expect(logger).to have_received(:info).with({
      identity: logged_identity,
      event: [{a: "a"}, {b: "b"}]
    }.to_json)
  end
end
