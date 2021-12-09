require "active_support/concern"
require "active_support/core_ext/string/inflections"

require_relative "config"
require_relative "method_name"
require_relative "initializer"
require_relative "uses_method_args"
require_relative "circular_dependency/analyzer"

module Uses
  # Provides a very basic mechanism for dependency management between classes in your service
  # layer.  This is done via the method `uses`.
  #
  # The simplest use of this module is to create a base class for all classes in your service layer:
  #
  #     # app/services/application_service.rb
  #     class ApplicationService
  #       include Uses::Method
  #     end
  #
  # Then, all services inherit from this and have access to the uses method.
  #
  # Note that any class or method without RubyDoc should be treated as private/internal, and you
  # should not depend on.
  module Method

    extend ActiveSupport::Concern

    class_methods do
      # Declare that the class including the Uses::Method module depends on another
      # class.  This will create an instance method on this class that returns a memoized
      # instance of the class passed in (klass).
      #
      # klass:: the class of what is dependend-upon.
      # as:: if given, overrides the default naming for the instance method.
      #      By default (when as: is omitted or set to nil), the name will
      #      be `klass.underscore.gsub(/\//,"_")` (see Uses::MethodName),
      #      so for a class named SomeClass, it would be `some_class`, however for
      #      a class named SomeNamespace::SomeClass, it would be `some_namespace_some_class`.
      #      If you set a value for `as:` that value would be used instead of this auto-generated value.
      # initialize: Controls how the instance is initialized:
      #             :new_no_args:: create the instance with `.new` an no args. This is the default, since
      #                            most service-layer classes should not need initializer arguments.
      #             :config_initializers:: Indicates that an intiailzation proc has been previously
      #                                    configured and should be used.  See ::initializers above.
      #             a Proc:: The `Proc` is called to return the new instance.  Generally you would
      #                      only use this if your class required special initialization but is only
      #                      used in *this* class.  Keep in mind that this couples the service with
      #                      how to iniltialize its dependent, which is not often a good thing.  But
      #                      sometimes you have to.
      def uses(klass, as: nil, initialize: :new_no_args)
        uses_method_args = Uses::UsesMethodArgs.new(
          klass_being_used: klass,
          klass_with_uses: self,
          method_name_override: as,
          initializer_strategy: initialize,
          uses_config: Uses.config
        )

        name                         = Uses::MethodName.new(uses_method_args)
        circular_dependency_analyzer = Uses::CircularDependency::Analyzer.new(uses_method_args)
        initializer                  = Uses::Initializer.from_args(uses_method_args)

        circular_dependency_analyzer.analyze!

        if circular_dependency_analyzer.circular_dependency?
          circular_dependency_analyzer.notify!
        end

        self.__uses_dependent_classes[klass] = name

        define_method name.to_s do
          self.__uses_dependent_instances[name.to_s] ||= initializer.()
        end
        private name.to_s
      end

      def __uses_dependent_classes
        @__uses_dependent_classes ||= {}
      end
    end

    def __uses_dependent_instances
      @__uses_dependent_instances ||= {}
    end
  end
end
