require_relative "base_notifier"
require_relative "error"
module ActiveService
  module CircularDependency
    class RaiseErrorNotifier < BaseNotifier
      def notify!
        raise ActiveService::CircularDependency::Error.new(@message)
      end
    end
  end
end
