require_relative "base_initializer"

class Uses::Initializer::FromInitializers < Uses::Initializer::BaseInitializer
  def create_proc(uses_method_args)
    uses_method_args.uses_config.initializers.fetch(uses_method_args.klass_being_used)
  rescue KeyError
    raise "An initializer for #{uses_method_args.klass_being_used.name} has not been defined. #{uses_method_args.klass_with_uses.name} has set initialize: to :config_initializers, which means it's assuming some other file (e.g. in config/initializers) has called Uses.initializers to set up the initialization"
  end
end
