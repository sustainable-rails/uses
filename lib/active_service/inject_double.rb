module ActiveService
  # Convienience methods for test to inject mocks/doubles into a class under test.
  #
  # An advantage of "injecting" dependencies is that you can provide alternate implementations 
  # for testing that simplify your tests.  While Ruby doesn't strictly require that you make
  # dependencies injectible, it is nice to have a bit of help in doing to so for a test.
  #
  # If using RSpec, use `inject_rspec_double`.
  module InjectDouble
    def inject_double(subject, injections)
      if injections.size != 1
        raise "expected a single key/value to inject_double, but got #{injections.size}"
      end

      name     = injections.first[0].to_s
      instance = injections.first[1]

      subject.__active_service_dependent_instances[name] = instance

      instance
    end

    #
    # For Rspec users, you might do:
    #
    #     dependent_service = instance_doule(DependentService)
    #     allow(DependentService).to receive(:new).and_return(dependent_service)
    #
    # (Yes, you can do `allow_any_instance_of(DependentService).to receive(:some_method)`, but
    # this is incredibly inconvienient for verifying if you need to)
    #
    # The problem is that it would be nice to know if your class under test actually uses the 
    # dependent service, plus it's annoying to have to write two lines of code.
    #
    # Instead:
    #
    #     dependent_service = instance_double(object_under_test, DependentService)
    #
    # If you depend in DependentService, this will replace the real instance with yours.  If you do not
    # it will raise an error.
    #
    # *Limitation* - does not work if using `as:`.
    def inject_rspec_double(subject, klass)
      if subject.class.__active_service_dependent_classes.include?(klass)
        self.inject_double(subject, ActiveService::MethodName.derive_method_name(klass) => instance_double(klass))
      else
        raise "#{subject.class} does not depend on a #{klass}"
      end
    end
  end
end
