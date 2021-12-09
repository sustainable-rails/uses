require_relative "log_notifier"
require_relative "ignore_notifier"
require_relative "raise_error_notifier"

module ActiveService
  module CircularDependency
    class Analyzer
      def initialize(uses_method_args)
        @uses_method_args = uses_method_args
      end

      def circular_dependency?
        other_class_is_active_service = @uses_method_args.klass_being_used.respond_to?(:__active_service_dependent_classes)
        if other_class_is_active_service
          @uses_method_args.klass_being_used.__active_service_dependent_classes.include?(@uses_method_args.klass_with_uses)
        else
          false
        end
      end

      def notify!
        notifier = case @uses_method_args.active_service_config.on_circular_dependency
                   when :warn        then ActiveService::CircularDependency::LogNotifer.new(@uses_method_args)
                   when :ignore      then ActiveService::CircularDependency::IgnoreNotifier.new(@uses_method_args)
                   when :raise_error then ActiveService::CircularDependency::RaiseErrorNotifier.new(@uses_method_args)
                   end
        notifier.notify!
      end
    end
  end
end
