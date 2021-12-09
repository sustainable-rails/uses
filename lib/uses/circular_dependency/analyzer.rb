require_relative "log_notifier"
require_relative "ignore_notifier"
require_relative "raise_error_notifier"

module Uses
  module CircularDependency
    class Analyzer
      def initialize(uses_method_args)
        @uses_method_args = uses_method_args
      end

      def analyze!
        @dependency, @path_to_dependency = transitive_dependency?(@uses_method_args.klass_with_uses,@uses_method_args.klass_being_used)
      end

      def circular_dependency?
        !!@dependency
      end

      def notify!
        raise "You have not called analyze!" if @dependency.nil?
        notifier = case @uses_method_args.uses_config.on_circular_dependency
                   when :warn        then Uses::CircularDependency::LogNotifer.new(@uses_method_args, @path_to_dependency)
                   when :ignore      then Uses::CircularDependency::IgnoreNotifier.new(@uses_method_args, @path_to_dependency)
                   when :raise_error then Uses::CircularDependency::RaiseErrorNotifier.new(@uses_method_args, @path_to_dependency)
                   end
        notifier.notify!
      end

    private

      def transitive_dependency?(klass_with_uses,klass_being_analyzed, path=[])
        other_class_has_uses = klass_being_analyzed.respond_to?(:__uses_dependent_classes)

        if other_class_has_uses
          if klass_with_uses == klass_being_analyzed
            [ true, path ]
          else
            # Want to stop searching as soon as we find something
            procs_to_check_for_transitive_dependencies = klass_being_analyzed.__uses_dependent_classes.keys.map { |klass|
              ->() { transitive_dependency?(klass_with_uses,klass, path + [ klass_being_analyzed ]) }
            }
            first_proc_to_find_a_dependency = procs_to_check_for_transitive_dependencies.detect { |p|
              transitive_dependency, _ = p.()
              transitive_dependency
            }
            if first_proc_to_find_a_dependency
              _, path_to_dependency = first_proc_to_find_a_dependency.()
              [ true, path_to_dependency ]
            else
              false
            end
          end
        else
          false
        end
      end
    end
  end
end
