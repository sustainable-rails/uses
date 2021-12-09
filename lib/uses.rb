module Uses
  # Yields a hash of initializer, with the intention that you insert
  # the initializer for your service into this hash. The key should be the class name
  # that would be given to a `uses` invocation, and the value should be a proc
  # that returns an instance of that class.
  #
  # The reason you would do this is if your service requires special setup beyond calling
  # new without arguments.  For example:
  #
  #
  #    require "uses"
  #    Uses.initializers do |initializers|
  #      initializers[Aws::S3::Client] = ->(*) {
  #        Aws::S3::Client.new(
  #          access_key_id: ENV["AWS_ACCESS_KEY_ID"],
  #          secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"],
  #          region: ENV["AWS_REGION"],
  #       )
  #      }
  #    end
  #
  #    # Then, in a service that uses this:
  #
  #    class MyService
  #      include Uses::Method
  #
  #      uses Aws::S3::Client, as: :s3, initialize: :config_initializers
  #
  #      def some_method
  #        s3.whatever # s3 has been initialized using the Proc above
  #      end
  #    end
  def self.initializers
    yield(config.initializers) if block_given?
    config.initializers
  end

  # Yields the Uses::Config instance governing this
  # gem's behavior.  You should call this in an intializer.
  # See Uses::Config for what options exist
  def self.config
    @@config ||= Uses::Config.new
    yield(@@config) if block_given?
    @@config
  end

end
require_relative "uses/version"
require_relative "uses/method"
