require_relative "base_notifier"
module ActiveService
  module CircularDependency
    class IgnoreNotifier < BaseNotifier
      def notify!
        Rails.logger.debug(@message)
      end
    end
  end
end
