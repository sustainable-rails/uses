require "spec_helper"
require "active_service/service"

RSpec.describe ActiveService::Service do
  class SomeService
    attr_reader :initializer_value
    def initialize(initializer_value: :default)
      @initializer_value = initializer_value
    end
  end

  class SomeServiceWithAComplexInitialzer
    attr_reader :initializer_value
    def initialize(initializer_value:)
      @initializer_value = initializer_value
    end
  end

  class ServiceUsingActiveServiceInDefaultWay
    include ActiveService::Service

    uses SomeService
  end
  before do
    ActiveService::Service.initializers do |initializers|
      initializers.clear
    end
    ActiveService::Service.config do |config|
      config.reset!
    end
  end
  describe "::uses" do
    context "default usage" do
      it "creates a private method named based on the class that returns a memoized instance of the given class by calling .new" do
        service = ServiceUsingActiveServiceInDefaultWay.new
        expect(service.methods).not_to include(:some_service)
        expect(service.private_methods).to include(:some_service)

        method = service.method(:some_service)
        expect(method.parameters).to eq([])
        expect(method.owner).to eq(ServiceUsingActiveServiceInDefaultWay)

        some_service_instance = method.call
        some_service_instance_from_repeated_call = method.call

        expect(some_service_instance).to be(some_service_instance_from_repeated_call)
      end
      it "raises an error if the class name cannot be used to derive the method name" do
        expect {
          Class.new do
            include ActiveService::Service

            uses Class.new
          end
        }.to raise_error(/cannot determine a default name/i)
      end
    end
    context "using as: to configure the method name" do
      it "creates a private method named based on `as:` that returns a memoized instance of the given class by calling .new" do
        klass = Class.new do
          include ActiveService::Service

          uses SomeService, as: :the_service
        end
        service = klass.new
        expect(service.methods).not_to include(:the_service)
        expect(service.private_methods).to include(:the_service)

        method = service.method(:the_service)
        expect(method.parameters).to eq([])
        expect(method.owner).to eq(klass)

        some_service_instance = method.call
        some_service_instance_from_repeated_call = method.call

        expect(some_service_instance).to be(some_service_instance_from_repeated_call)
      end
      context "::new accepts arguments, but a no-arg invocation is valid" do
        it "invokes with no-args" do
          service = Class.new do
            include ActiveService::Service
            uses SomeService # see its constructor
          end.new

          confidence_check do
            expect(service.private_methods).to include(:some_service)
          end

          method = service.method(:some_service)

          some_service_instance = method.call
          expect(some_service_instance.initializer_value).to eq(:default)
        end
      end
      context "::new accepts arguments, but some are required" do
        it "raises an error" do
          expect {
            Class.new do
              include ActiveService::Service

              uses SomeServiceWithAComplexInitialzer
            end
          }.to raise_error(/initializer has required arguments/i)
        end
      end
    end
    context "specifying a Proc to initialize:" do
      it "calls that proc to get a new memoized instance" do
        service = Class.new do
          include ActiveService::Service

          uses SomeServiceWithAComplexInitialzer, as: :dep, initialize: ->(*) {
            SomeServiceWithAComplexInitialzer.new(initializer_value: "foobar")
          }
        end.new
        expect(service.send(:dep).initializer_value).to eq("foobar")
      end
    end
    context "specify :config_initializers to initialize:" do
      context "a proc has been placed in the initializers map" do
        it "calls that proc to get a new memoized instance" do

          ActiveService::Service.initializers do |initializers|
            initializers[SomeServiceWithAComplexInitialzer] = ->(*) {
              SomeServiceWithAComplexInitialzer.new(initializer_value: "foobar")
            }
          end

          service = Class.new do
            include ActiveService::Service

            uses SomeServiceWithAComplexInitialzer, as: :dep, initialize: :config_initializers
          end.new

          expect(service.send(:dep).initializer_value).to eq("foobar")
        end
      end
      context "a proc has not been placed in the initializers map" do
        it "raises an error" do
          confidence_check do
            expect(ActiveService::Service.initializers[SomeServiceWithAComplexInitialzer]).to be_nil
          end

          expect {
            Class.new do
              include ActiveService::Service

              uses SomeServiceWithAComplexInitialzer, as: :dep, initialize: :config_initializers
            end
          }.to raise_error(/an initializer for SomeServiceWithAComplexInitialzer has not been defined/i)
        end
      end
    end
    context "specify another symbol to initialize:" do
      it "raises an error with that symbol in it" do
        expect {
          Class.new do
            include ActiveService::Service

            uses SomeServiceWithAComplexInitialzer, as: :dep, initialize: :foobar
          end
        }.to raise_error(/received foobar.*not supported/i)
      end
    end
    context "specify a non-symbol, non-Proc to initialize:" do
      it "raises an error with that class' name in it" do
        expect {
          Class.new do
            include ActiveService::Service

            uses SomeServiceWithAComplexInitialzer, as: :dep, initialize: "blah"
          end
        }.to raise_error(/received a String.*not supported/i)
      end
    end
    context "there are circular dependencies" do
      before do
        allow(Rails.logger).to receive(:debug)
        allow(Rails.logger).to receive(:info)
        allow(Rails.logger).to receive(:warn)
      end
      context "circular dependency warnings are in their default state - :warn" do
        it "works and logs a warning" do
          Class1 = Class.new do
            include ActiveService::Service
          end
          Class2 = Class.new do
            include ActiveService::Service
          end

          Class1.uses Class2
          Class2.uses Class1

          expect(Rails.logger).to have_received(:warn).with(/Class1.*Class2.*have a circular dependency/)
        end
      end
      context "circular dependency warnings are set to :raise_error" do
        it "raises an error" do
          ActiveService::Service.config do |config|
            config.on_circular_dependency = :raise_error
          end
          expect {
            Class3 = Class.new do
              include ActiveService::Service
            end
            Class4 = Class.new do
              include ActiveService::Service
            end

            Class3.uses Class4
            Class4.uses Class3
          }.to raise_error(/Class3.*Class4.*have a circular dependency/)
        end
      end
      context "circular dependency warnings are disabled globally" do
        it "works and logs a debug" do
          ActiveService::Service.config do |config|
            config.on_circular_dependency = :ignore
          end
          Class5 = Class.new do
            include ActiveService::Service
          end
          Class6 = Class.new do
            include ActiveService::Service
          end

          Class5.uses Class6
          Class6.uses Class5

          expect(Rails.logger).to have_received(:debug).with(/Class5.*Class6.*have a circular dependency/)
          expect(Rails.logger).not_to have_received(:warn)
        end
      end
    end
  end
end
