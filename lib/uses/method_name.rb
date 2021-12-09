require_relative "invalid_method_name"
module Uses
  class MethodName

    def self.derive_method_name(klass)
      klass.name.to_s.underscore.gsub(/\//,"_")
    end

    def initialize(uses_method_args)
      @name = if uses_method_args.method_name_override.nil?
                self.class.derive_method_name(uses_method_args.klass_being_used)
              else
                uses_method_args.method_name_override.to_s
              end
        if @name !~ /^[a-z0-9_]+$/
          raise Uses::InvalidMethodName.new("Cannot determine a default name for #{uses_method_args.klass_being_used} used by #{uses_method_args.klass_with_uses}. Use as: to specify the name")
        end
    end
    def to_s
      @name
    end
  end
end
