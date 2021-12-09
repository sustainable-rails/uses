# active\_service - minimally manage your service layer

[![<sustainable-rails>](https://circleci.com/gh/sustainable-rails/active_service.svg?style=shield)](https://app.circleci.com/pipelines/github/sustainable-rails/active_service)

Your *service layer* is comprised of various classes that perform business logic.  They often have dependencies between them and while you can
easily manage that with convention Ruby methods, this gem allows a tiny bit more:

```ruby
class PaymentProcessor
  include ActiveService::Service

  uses Braintree::Gateway # defines braintree_gateway to return an instance

  def collect_payment

    braintree_gateway.sale(...)
  end

end

class PaymentsController
  uses PaymentProcessor # defines payment_processor

  def create
    payment_processor.collect_payment
  end
end
```

## Install

Add to your `Gemfile`

```ruby
gem "active_service"
```

Then, in any service class, controller, mailer, or whatever, include `ActiveService::Service` to access `uses`:

```ruby
class SomeClass
  include ActiveService::Service

  uses SomeDependentClass
end
```

## What Problem Does This Solve?

Assuming you are bought into a service layer for Rails app, it will be comprised of lots of single-purpose classes. These classes are used by your
controllers and other classes that initiate business logic.  These classes will also tend to use each other, especially over time as you discover
what features need to be internally re-used.

Consider a `PaymentsController` that calls into a `PaymentProcessor` to create a charge.  Consider that `PaymentProcessor` uses Braintree's
`Braintree::Gateway` to interact with Braintree.  Conventionally, you may write this:

```ruby
class PaymentsController < ApplicationController

  def create
    # ...
    payment_processor.collect_payment(...)
    # ...
  end

private

  def payment_processor
    @payment_processor ||= PaymentProcessor
  end
end

class PaymentProcessor
  def collect_payment(...)
    braintree_gateway.sale(...)
  end

private

  def braintree_gateway
    @braintree_gateway ||= Braintree::Gateway.new(...)
  end
end
```

Over time, you'll create these private memoized methods frequently.  I find this tedios even for a small sized app.  With active service you can do
this:

```ruby
class PaymentsController < ApplicationController
  include ActiveService::Service

  uses PaymentProcessor

  def create
    # ...
    payment_processor.collect_payment(...)
    # ...
  end
end

class PaymentProcessor
  include ActiveService::Service

  uses Braintree::Gateway

  def collect_payment(...)
    braintree_gateway.sale(...)
  end
end
```

This does a *bit* more than eliminate a few lines of code.  Because this declares dependencies between classes explicitly it affords a few things:

* simplify injecting test doubles
* check for circular dependencies

These are explained below

## Usage

The core of this library is the `uses` macro, which is available when you `include ActiveService::Service`.  I would recommend you do two things to
make this easy:

* Add the `include` call to `ApplicationController`
* Create `app/services/application_service.rb` like so:

  ```ruby
  class ApplicationService
    include ActiveService::Service
  end
  ```

  Then for every class in your service layer, have it inherit from `ApplicationService`.

Now, you can use `uses` pretty  much everywhere you need it.

### `uses` macro

The `uses` macro does two things:

* Creates a private method that returns a memoized instance of the dependent class
* Instantiates that class

You can control both the name of the method and how the class is instantiated if needed, but the default behavior should workk for most cases.

The full signature of `uses` is:

```ruby
uses SomeClass, as: «method name», initialize: «initialization_strategy»
```

By default, the `«method name»` will be the underscorized version of the class, with slashes replaced by underscores, so for example `Braintree::Gateway` becomes `braintree_gateway`.

By default `«initialization_strategy»` is `:new_no_args`, which instructs `uses` to simply call `new` without any args, e.g.
`Braintree::Gateway.new`.

Thus the method that gets defined would look like this:

```ruby
def braintree_gateway
  @braintree_gateway ||= Braintree::Gateway.new
end
private :braintree_gateway
```

#### `as:`

By setting `as:` you can control the name of the private method if you don't like the default.  Generally, you should not do this, but it can be
handy if you are migrating existing code to this gem and don't want to change variable names:

```ruby
uses Braintree::Gateway as: :braintree

# creates this method:
def braintree
  @braintree ||= Braintree::Gateway.new
end
private :braintree
```

`as:` must be a value that can be used as a method in Ruby

#### `initialize:`

Not all objects can be created with `.new`. Here are the possible values for `initialize:`

* `:new_no_args` - This is the default and creates an instance by calling `new` without any args. This should be how most of the classes you create are ininitailized.
* `:config_initializers` - This says that an instance has been pre-configured by a file in `config/initializers`.  Specifically, it assumes code
like this has been executed before this class has been loaded:

  ```ruby
  # config/initializers/braintree.rb
  ActiveService::Service.initializers do |initializers|
    initializers[Braintree::Gateway] = ->(*) {
      Braintree::Gateway.new(
        :environment => :sandbox,
        :merchant_id => "your_merchant_id",
        :public_key  => "your_public_key",
        :private_key => "your_private_key",
      )
    }
  end
  ```

  `initializers` is a hash that has the class as a key and a `Proc` as the value. That `Proc` will be used each time the class must be
  instantiated.  This is the second preferred method for creating instances since it is desirable to have a single location for how an instance is
  created if it must be created in a complex way.

  Note that it doesn't have to be in a file in `config/initializers`, but since `uses` will execute when a class containing it is loaded, 
  `config/initializers` is the best place to put code like this.
* A `Proc` - If you set `initialize:` to a `Proc`, that `Proc` will be called to get the instance of the object.  This is useful if the way in which the object is created differs based on what class is including it. This should be used rarely

### Circular Dependencies

Because the proliferation of `uses` creates a structured representation of your service layer's dependencies, active service can check for circular
dependencies.  The reason this is important is that your code's behavior can become confusing if a dependency depends on another class that depends
on it.

By default, if a circular dependency is detected, active service will emit a warning.  You can change this behavior by setting a config value,
which you can do by creating `config/initializers/active_sevice.rb`:

```ruby
# config/initializers/active_sevice.rb
ActiveService.config do |config|
  config.on_circular_dependency = # one of :warn, :ignore, or :raise_error
end
```

Valid values are:

* `:warn` - this is the default and will emit a warning if a circular dependency is found.
* `:ignore` - this will log a warning a debug level, effectively squelching the message. Don't use this unless you are migrating a service layer that has a lot of circular dependencies.
* `:raise_error` - this will raise an `ActiveService::CircularDependency::Error` when it encounters a circular dependency.

### Testing Support

Because we have a structured representation of dependencies, we can provide some support for mocking dependent objects.  By default, no mocking is
done. The methods `inject_double` and `inject_rspec_double` are available to make mocking easier.

First, you'll need to `require` them as they are not available by default.

```ruby
# e.g. in test_helper or spec_helper
require "active_service/inject_double"
```

You'll then want to include `ActiveService::InjectDouble` wherever you need it. I would recommend doing this in your base test or RSpec
configuration, for example:

```ruby
# spec/spec_helper.rb
require "active_service/inject_double"

RSpec.configure do |config|
  config.include ActiveService::InjectDouble

  # ... remainder of your configuration
end
```

In an RSpec test, you might create a mock of `Braintree::Gateway` like so:

```ruby
RSpec.describe PaymentProcessor do
  subject(:payment_processor) { described_class.new }

  let(:braintree_gateway) { instance_double(Braintree::Gateway) }
  let(:transaction) { double }

  before do
    allow(braintree_gateway).to receive(:sale)
  end

  describe "#collect_payment" do
    it "calls braintree" do
      payment_processor.collect_payment

      expect(braintree_gateway).to have_received(:sale)
    end
  end
end
```

You can save some lines by doing this:

```ruby
RSpec.describe PaymentProcessor do
  subject(:payment_processor) { described_class.new }

  let(:braintree_gateway) { inject_rspec_double(payment_processor, Braintree::Gateway) }

  before do
    allow(braintree_gateway).to receive(:sale)
  end

  describe "#collect_payment" do
    it "calls braintree" do

      payment_processor.collect_payment

      expect(braintree_gateway).to have_received(:sale)
    end
  end
end
```

In addition to saving a few lines of code, this will also raise an error if your class does not depend on the class passed to
`inject_rspec_double`, which can be handy for refactoring and managing your codebase.

If you aren't using RSpec, you can use `inject_double` like so:

```ruby
inject_double(payment_processor, braintree_gateway: however_you_create_a_double(Braintree::Gateway))
```
