require "spec_helper"
require "active_service/config"

RSpec.describe ActiveService::Config do
  describe "#on_circular_dependency" do

    subject(:config) { ActiveService::Config.new }

    it "allows :raise_error" do
      expect {
        config.on_circular_dependency = :raise_error
      }.not_to raise_error
    end
    it "allows :warn" do
      expect {
        config.on_circular_dependency = :warn
      }.not_to raise_error
    end
    it "allows :ignore" do
      expect {
        config.on_circular_dependency = :ignore
      }.not_to raise_error
    end
    it "raises on any other value" do
      expect {
        config.on_circular_dependency = :foobar
      }.to raise_error(ArgumentError,/foobar/)
    end
  end
end
