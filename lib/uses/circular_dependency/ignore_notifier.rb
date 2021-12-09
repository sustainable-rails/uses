require_relative "base_notifier"
module Uses
  module CircularDependency
    class IgnoreNotifier < BaseNotifier
      def notify!
        Rails.logger.debug(@message)
      end
    end
  end
end
