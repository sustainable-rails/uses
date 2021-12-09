require "logger"
require "confidence_check/for_rspec"

if !defined?(Rails)
  module Rails
  end
end

if !Rails.respond_to?(:logger)
  module Rails
    def self.logger
      @logger ||= Logger.new(STDERR)
    end
  end
end

RSpec.configure do |config|
  config.include ConfidenceCheck::ForRSpec
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.disable_monkey_patching!

  config.warnings = true

  if config.files_to_run.one?
    config.default_formatter = "doc"
  end

  config.order = :random

  Kernel.srand config.seed
end
