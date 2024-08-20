# frozen_string_literal: true

require_relative "lib/airfoil/version"

Gem::Specification.new do |spec|
  spec.name = "airfoil"
  spec.version = Airfoil::VERSION
  spec.authors = ["Highwing Engineering"]
  spec.email = ["engineering@highwing.io"]

  spec.summary = "Enough structure to get our Lambda handlers in the air"
  # spec.homepage = "TODO: Put your gem's website or public repo URL here."
  spec.required_ruby_version = ">= 3.2"

  #   spec.metadata["homepage_uri"] = spec.homepage
  # spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.glob("{lib}/**/*.*") + %w[README.md]
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "dry-monads"
  spec.add_dependency "ibsciss-middleware", "~> 0.4.3"
  spec.add_dependency "railties"

  spec.add_development_dependency "aws_lambda_ric"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rubocop"
end
