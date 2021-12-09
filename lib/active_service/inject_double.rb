module ActiveService
  # Convienience methods for test to inject mocks/doubles into a class under test.
  #
  # An advantage of "injecting" dependencies is that you can provide alternate implementations 
  # for testing that simplify your tests.  While Ruby doesn't strictly require that you make
  # dependencies injectible, it is nice to have a bit of help in doing to so for a test.
  #
  # If using RSpec, use `inject_rspec_double`.
  module InjectDouble
    # Inject an instantiated double into subject, returing the double.
    #
    # subject:: the instance of the class under test where you want a double injected
    # injectsion:: a hash of size 1 where the key is the class given to `uses` and
    #              the value is the doubled object
    def inject_double(subject, injections)
      if injections.size != 1
        raise "expected a single key/value to inject_double, but got #{injections.size}"
      end

      klass    = injections.first[0]
      instance = injections.first[1]

      subject_must_be_active_sevice!(subject)
      injected_class_must_be_class!(klass)

      name = dependency_method_name!(subject, klass)

      subject.__active_service_dependent_instances[name] = instance

      instance
    end

    #
    # For Rspec users, you might do:
    #
    #     dependent_service = instance_doule(DependentService)
    #     allow(DependentService).to receive(:new).and_return(dependent_service)
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
    def inject_rspec_double(subject, klass)
      self.inject_double(subject, klass => instance_double(klass))
    end

  private

    def subject_must_be_active_sevice!(subject)
      if !subject.class.respond_to?(:__active_service_dependent_classes)
        raise ActiveService::Error, "#{subject.class} is not an ActiveService::Service, so you cannot inject a double into it"
      end
    end

    def injected_class_must_be_class!(klass)
      if !klass.kind_of?(Class)
        raise ActiveService::Error, "Pass the actual class, not a #{klass.class}."
      end
    end

    def dependency_method_name!(subject, klass)
      name = subject.class.__active_service_dependent_classes[klass].to_s

      if name.blank?
        raise ActiveService::Error, "#{subject.class} does not depend on a #{klass}, so there is no reason to inject a mock"
      end
      name
    end

  end
end
