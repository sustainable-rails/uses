require_relative "base_notifier"
module Uses
  module CircularDependency
    class LogNotifer < BaseNotifier
      def notify!
        Rails.logger.warn(@message)
      end
    end
  end
end
