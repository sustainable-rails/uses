require "active_support/concern"
require "active_support/core_ext/string/inflections"

require_relative "config"
require_relative "method_name"
require_relative "initializer"
require_relative "uses_method_args"
require_relative "circular_dependency/analyzer"

module ActiveService
  # Provides a very basic mechanism for dependency management between classes in your service
  # layer.  This is done via the method `uses`.
  #
  # The simplest use of this module is to create a base class for all classes in your service layer:
  #
  #     # app/services/application_service.rb
  #     class ApplicationService
  #       include ActiveService::Service
  #     end
  #
  # Then, all services inherit from this and have access to the uses method.
  #
  # Note that any class or method without RubyDoc should be treated as private/internal, and you
  # should not depend on.
  module Service

    # Yields a hash of initializer, with the intention that you insert
    # the initializer for your service into this hash. The key should be the class name
    # that would be given to a `uses` invocation, and the value should be a proc
    # that returns an instance of that class.
    #
    # The reason you would do this is if your service requires special setup beyond calling
    # new without arguments.  For example:
    #
    #
    #    require "active_service"
    #    ActiveService::Service.initializers do |initializers|
    #      initializers[Aws::S3::Client] = ->(*) {
    #        Aws::S3::Client.new(
    #          access_key_id: ENV["AWS_ACCESS_KEY_ID"],
    #          secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"],
    #          region: ENV["AWS_REGION"],
    #       )
    #      }
    #    end
    #
    #    # Then, in a service that uses this:
    #
    #    class MyService
    #      include ActiveService::Service
    #
    #      uses Aws::S3::Client, as: :s3, initialize: :config_initializers
    #
    #      def some_method
    #        s3.whatever # s3 has been initialized using the Proc above
    #      end
    #    end
    def self.initializers
      yield(config.initializers) if block_given?
      config.initializers
    end

    # Yields the ActiveService::Config instance governing this
    # gem's behavior.  You should call this in an intializer.
    # See ActiveService::Config for what options exist
    def self.config
      @@config ||= ActiveService::Config.new
      yield(@@config) if block_given?
      @@config
    end

    extend ActiveSupport::Concern

    class_methods do
      # Declare that the class including the ActiveService::Service module depends on another
      # class.  This will create an instance method on this class that returns a memoized
      # instance of the class passed in (klass).
      #
      # klass:: the class of what is dependend-upon.
      # as:: if given, overrides the default naming for the instance method.
      #      By default (when as: is omitted or set to nil), the name will
      #      be `klass.underscore.gsub(/\//,"_")` (see ActiveService::MethodName),
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
        uses_method_args = ActiveService::UsesMethodArgs.new(
          klass_being_used: klass,
          klass_with_uses: self,
          method_name_override: as,
          initializer_strategy: initialize,
          active_service_config: ActiveService::Service.config
        )

        name                         = ActiveService::MethodName.new(uses_method_args)
        circular_dependency_analyzer = ActiveService::CircularDependency::Analyzer.new(uses_method_args)
        initializer                  = ActiveService::Initializer.from_args(uses_method_args)

        circular_dependency_analyzer.analyze!

        if circular_dependency_analyzer.circular_dependency?
          circular_dependency_analyzer.notify!
        end

        self.__active_service_dependent_classes[klass] = name

        define_method name.to_s do
          self.__active_service_dependent_instances[name.to_s] ||= initializer.()
        end
        private name.to_s
      end

      def __active_service_dependent_classes
        @__active_service_dependent_classes ||= {}
      end
    end

    def __active_service_dependent_instances
      @__active_service_dependent_instances ||= {}
    end
  end
end
