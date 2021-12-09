require_relative "base_notifier"
require_relative "error"
module Uses
  module CircularDependency
    class RaiseErrorNotifier < BaseNotifier
      def notify!
        raise Uses::CircularDependency::Error.new(@message)
      end
    end
  end
end
