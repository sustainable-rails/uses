module ActiveService
  module CircularDependency
    class BaseNotifier
      def initialize(uses_method_args)
        @message =  "#{uses_method_args.klass_being_used} and #{uses_method_args.klass_with_uses} have a circular dependency. This may cause unforseen issues, or just be generally confusing"
      end

      def notify!
        raise "subclass must implement"
      end
    end
  end
end
