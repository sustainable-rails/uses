require_relative "base_initializer"

class Uses::Initializer::NewNoArgs < Uses::Initializer::BaseInitializer
  def create_proc(uses_method_args)
    initialize_method = uses_method_args.klass_being_used.instance_method(:initialize)
    if !initialize_method.arity.in?([0,-1])
      raise "#{uses_method_args.klass_being_used}'s initializer has required arguments, but has been used in #{uses_method_args.klass_with_uses.class} to initializer with no arguments passed to ::new. Please use initialize: with a Proc or :config_initializers to control how the instance is created"
    end
    ->() { uses_method_args.klass_being_used.new }
  end
end
