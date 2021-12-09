require "spec_helper"
require "active_service/service"
require "active_service/inject_double"

RSpec.describe ActiveService::InjectDouble do
  include ActiveService::InjectDouble
  describe "#inject_double" do
    context "class depends on the double's class" do
      context "using default naming" do
        it "injects the given instance" do
          InjectDoubleClass1 = Class.new do
            include ActiveService::Service
          end
          InjectDoubleClass2 = Class.new

          InjectDoubleClass1.uses InjectDoubleClass2

          instance_under_test = InjectDoubleClass1.new

          mocked_instance = Object.new

          injected_double = inject_double(instance_under_test, InjectDoubleClass2 => mocked_instance)

          expect(injected_double).to be(mocked_instance)
          expect(instance_under_test.send(:inject_double_class2)).to eq(mocked_instance)
        end
      end
      context "using overridden name via as:" do
        it "injects the given instance" do
          InjectDoubleClass3 = Class.new do
            include ActiveService::Service
          end
          InjectDoubleClass4 = Class.new

          InjectDoubleClass3.uses InjectDoubleClass4, as: "some_object"

          instance_under_test = InjectDoubleClass3.new

          mocked_instance = Object.new

          injected_double = inject_double(instance_under_test, InjectDoubleClass4 => mocked_instance)

          expect(injected_double).to be(mocked_instance)
          expect(instance_under_test.send(:some_object)).to eq(mocked_instance)
        end
      end
      context "using hash syntax accidentally" do
        it "raises an error" do
          InjectDoubleClass7 = Class.new do
            include ActiveService::Service
          end
          InjectDoubleClass8 = Class.new

          instance_under_test = InjectDoubleClass7.new

          mocked_instance = Object.new

          expect {
            inject_double(instance_under_test, InjectDoubleClass8: mocked_instance)
          }.to raise_error(/class.*not a symbol/i)
        end
      end
    end
    context "class does not depend on the double's class" do
      it "raises an error" do
        InjectDoubleClass5 = Class.new do
          include ActiveService::Service
        end
        InjectDoubleClass6 = Class.new

        instance_under_test = InjectDoubleClass5.new

        mocked_instance = Object.new

        expect {
          inject_double(instance_under_test, InjectDoubleClass6 => mocked_instance)
        }.to raise_error(/does not.*InjectDoubleClass6/i)
      end
    end
    context "class is not an active service" do
      it "raises an error" do
        expect {
          inject_double("foo", Object => "blah")
        }.to raise_error(/String.*not an ActiveService::Service/i)
      end
    end
  end
  describe "#inject_rspec_double" do
    it "injects an instance_double" do
      InjectRSpecDoubleClass1 = Class.new do
        include ActiveService::Service
      end
      InjectRSpecDoubleClass2 = Class.new

      InjectRSpecDoubleClass1.uses InjectRSpecDoubleClass2

      instance_under_test = InjectRSpecDoubleClass1.new

      injected_double = inject_rspec_double(instance_under_test, InjectRSpecDoubleClass2)
      expect(instance_under_test.send(:inject_r_spec_double_class2)).to be(injected_double)
      expect(injected_double.class).to eq(RSpec::Mocks::InstanceVerifyingDouble)
    end
  end
end
