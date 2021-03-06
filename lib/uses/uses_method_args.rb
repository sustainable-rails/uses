module Uses
  class UsesMethodArgs

    attr_reader :klass_being_used,
                :klass_with_uses,
                :method_name_override,
                :initializer_strategy,
                :uses_config

    def initialize(klass_being_used:,
                   klass_with_uses:,
                   method_name_override:,
                   initializer_strategy:,
                   uses_config:)

      @klass_being_used     = klass_being_used
      @klass_with_uses      = klass_with_uses
      @method_name_override = method_name_override
      @initializer_strategy = initializer_strategy
      @uses_config          = uses_config

    end
  end
end
