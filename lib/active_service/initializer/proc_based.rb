require_relative "base_initializer"

class ActiveService::Initializer::ProcBased < ActiveService::Initializer::BaseInitializer
  def create_proc(uses_method_args)
    uses_method_args.initializer_strategy
  end
end
