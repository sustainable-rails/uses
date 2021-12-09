module ActiveService
  module CircularDependency
    class BaseNotifier
      def initialize(uses_method_args, path_to_dependency)
        path = if path_to_dependency.empty?
                 nil
               else
                 " via #{path_to_dependency.map(&:to_s).join(',')}"
               end
        @message =  "#{uses_method_args.klass_being_used} and #{uses_method_args.klass_with_uses} have a circular dependency#{path}. This may cause unforseen issues, or just be generally confusing"
      end

      def notify!
        raise "subclass must implement"
      end
    end
  end
end
