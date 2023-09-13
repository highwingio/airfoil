# frozen_string_literal: true

require "spec_helper"
require "aws_lambda_ric/lambda_context"
require "airfoil/middleware/step_function"
require "airfoil/middleware/sentry_catcher"

RSpec.describe Airfoil::Middleware::StepFunction do
  let(:request_id) { SecureRandom.uuid }
  let(:trace_id) { "1-5759e988-bd862e3fe1be46a994272793" }
  let(:request) { {"Lambda-Runtime-Aws-Request-Id" => request_id} }
  let(:context) { LambdaContext.new(request) }
  let(:sentry) { Sentry.get_current_hub }

  before :all do
    @stack = Middleware::Builder.new do |b|
      b.use Airfoil::Middleware::SentryCatcher, Logger.new(nil)
      b.use described_class, FakeHandler, "other-func"
      b.use described_class, FakeHandler, "function-name", "other-func",
        retried_exceptions: [FakeHandler::MyException]
      b.use described_class, FakeHandler, "divider",
        retried_exceptions: [ZeroDivisionError]
    end
  end

  # rubocop:disable Lint/ConstantDefinitionInBlock
  # rubocop:disable RSpec/LeakyConstantDeclaration
  class FakeHandler
    MyException = Class.new(StandardError)

    def self.handle(event, context)
      case event
      in type: "divide"
        1 / 0
      in type: "cool"
        "Trueness"
      else
        raise MyException, "OOPS!"
      end
    end
  end

  # rubocop:enable Lint/ConstantDefinitionInBlock
  # rubocop:enable RSpec/LeakyConstantDeclaration

  before do
    Sentry.init do |config|
      config.dsn = "https://test@sentry.example.com/1"
      config.environment = "test"
      config.background_worker_threads = 0
      config.traces_sample_rate = 1.0
    end

    allow(sentry).to receive(:capture_event)
  end

  context "when function name matches" do
    before do
      ENV["AWS_LAMBDA_FUNCTION_NAME"] = "function-name"
    end

    it "excludes sentry handling of errors but continues to raise error" do
      expect { @stack.call(event: {}, context: context) }.to raise_exception(FakeHandler::MyException)
      expect(sentry).not_to have_received(:capture_event)
    end

    it "reports errors that are not excluded" do
      expect { @stack.call(event: {type: "divide"}, context: context) }.to raise_exception(ZeroDivisionError)
      expect(sentry).to have_received(:capture_event)
    end

    it "returns the result of the call" do
      result = nil

      expect { result = @stack.call(event: {type: "cool"}, context: context) }.not_to raise_exception
      expect(sentry).not_to have_received(:capture_event)
      expect(result).to eq("Trueness")
    end

    context "when the call is handled twice" do
      before do
        ENV["AWS_LAMBDA_FUNCTION_NAME"] = "other-func"
      end

      it "the error is still permitted by a function not excluding sentry reporting" do
        expect { @stack.call(event: {}, context: context) }.to raise_exception(FakeHandler::MyException)
        expect(sentry).to have_received(:capture_event).once
      end
    end
  end

  context "when function name does not match" do
    before do
      ENV["AWS_LAMBDA_FUNCTION_NAME"] = "divider"
    end

    it "excludes error for the named function" do
      expect { @stack.call(event: {type: "divide"}, context: context) }.to raise_exception(ZeroDivisionError)
      expect(sentry).not_to have_received(:capture_event)
    end
  end
end
