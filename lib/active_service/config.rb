require "active_support/core_ext/object/inclusion"
module ActiveService
  class Config
    # Configure what should happen when a circular dependency is detected.
    #
    # :warn:: Emit a warning, but allow it (default)
    # :raise_error:: Raise an exception, effectively making your app unusable until
    #                you resolve the circular dependencies
    # :ignore:: Emit a warning at DEBUG level, effectively allowing you to ignore these issues.
    attr_reader :on_circular_dependency

    # The array of custom initializers.  Generally you should use
    # `ActiveService.initializers do |initializers|` to manipulate this
    attr_reader :initializers

    def initialize
      reset!
    end

    def reset!
      self.on_circular_dependency = :warn
      @initializers = {}
    end

    ON_CIRCULAR_DEPENDENCY_VALUES = [
      :ignore,
      :raise_error,
      :warn,
    ]
    def on_circular_dependency=(new_value)
      if !new_value.in?(ON_CIRCULAR_DEPENDENCY_VALUES)
        raise ArgumentError, "#{new_value} is not a valid value for on_circular_dependency. Use one of #{ON_CIRCULAR_DEPENDENCY_VALUES}"
      end
      @on_circular_dependency = new_value
    end

  end
end
