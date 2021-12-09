module Uses
  module Initializer
    class BaseInitializer
      def initialize(uses_method_args)
        @proc = self.create_proc(uses_method_args)
      end

      def call
        @proc.()
      end

    private

      def create_proc(uses_method_args)
        raise "subclass must implement"
      end
    end
  end
end
