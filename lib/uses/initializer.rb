require_relative "error"
require_relative "initializer/new_no_args"
require_relative "initializer/from_initializers"
require_relative "initializer/proc_based"

module Uses
  module Initializer
    def self.from_args(uses_method_args)
      strategy_klass(uses_method_args).new(uses_method_args)
    end

  private

    def self.strategy_klass(uses_method_args)
      case uses_method_args.initializer_strategy
      when :new_no_args         then NewNoArgs
      when :config_initializers then FromInitializers
      when Proc                 then ProcBased
      else
        raise UnknownInitializerStrategy.new(uses_method_args.initializer_strategy)
      end
    end


    class UnknownInitializerStrategy < Uses::Error
      def initialize(strategy)
        if strategy.kind_of?(Symbol)
          super("initialize: received #{strategy}, which is not supported. Should be either the symbol :config_initializers, a Proc, or simply omitted")
        else
          super("initialize: received a #{strategy.class}, which is not supported. Should be either the symbol :config_initializers, a Proc, or simply omitted")
        end
      end
    end
  end
end
