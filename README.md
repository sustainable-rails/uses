# uses - declare dependencies between classes

[![<sustainable-rails>](https://circleci.com/gh/sustainable-rails/uses.svg?style=shield)](https://app.circleci.com/pipelines/github/sustainable-rails/uses)

Your *service layer* is a web of classes that depend on each other to get the job done. While you can manage that directly with code and test them
directly using mocks or integration tests, declaring dependencies directly can reduce errors, increase consistency, and make your code a bit
simpler.

## Install

Add to your `Gemfile`

```ruby
gem "uses"
```

## Usage

Suppose you have a `PaymentsController` that uses a class called `PaymentProcessor`. Suppose that `PaymentProcessor` uses `Braintree::Gateway`
under the covers:

```
+--------------------+
|                    |
| PaymentsController |
|                    |
+---+----------------+
    |
    |           +------------------+
    \-«uses»--->|                  |
                | PaymentProcessor |
                |                  |
                +------------------+
                    |
                    |           +--------------------+
                    \-«uses»--->|                    |
                                | Braintree::Gateway |
                                |                    |
                                +--------------------+
```

You might implement this like so:

```ruby
class PaymentsController < ApplicationController
  def create
    payment_processor.collect_payment(...)
  end
  
private

  def payment_processor
    @payment_processor ||= PaymentProcessor.new
  end
end

class PaymentProcessor
  def collect_payment
    braintree_gateway.sale(...)
  end

private

  def braintree_gateway
    @braintree_gateway ||= Braintree::Gateway.new
  end
end
```

This is fine, but with Uses you can declare these dependencies explicitly:

```ruby
class PaymentsController < ApplicationController
  uses PaymentProcessor # <--------

  def create
    payment_processor.collect_payment(...)
    #  ^
    #  |
    #  |
    # Method dynamically defined when `uses` is called

  end
end

class PaymentProcessor
  uses Braintree::Gateway # <--------

  def collect_payment
    braintree_gateway.sale(...)
    #  ^
    #  |
    #  |
    # Method dynamically defined when `uses` is called
  end
end
```

## Why Would You Want This?

By declaring dependencies like this, you:

* save some code, which adds up as your application grows.
* can detect circular dependencies, which is often a sign of trouble or confusion.
* can ensure that if you mock a dependency, you class really does depend on it.
* make dependants clear at the top of the class, but without adopting a complicated dependency-injection pattern.

## Set Up

Strictly speaking, to access `uses`, you should include `Uses::Method` into any class that needs it. Practically, this is what you should
do:

* Add it to `ApplicationController`:

  ```ruby
  class ApplicationController < ActionController::Base
    include Uses::Method

    # whatever else is in your ApplicationController
  end
  ```
* Create `app/sevices/application_service.rb` like so:

  ```ruby
  class ApplicationService
    include Uses::Method
  end
  ```

  and have your service layer classes inherit from this
* Add `Uses::Method` to any other base class where your service layer logic is initiated.

## Testing Support

You might test `PaymentProcessor` by mocking `Braintree::Gateway`, like so:

```ruby
RSpec.describe PaymentProcessor do
  subject(:payment_processor) { described_class.new }

  let(:braintree_gateway) { instance_double(Braintree::Gateway) }

  before do
    allow(Braintree::Gateway).to receive(:new).and_return(braintree_gateway)
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

When building out your service layer, having to repeatedly mock the call to `new` can be tedious.  If your class changes to need the class you are
mocking, you don't have a good way to know that.  Instead, `inject_rspec_double` can solve both issues:

```ruby
RSpec.describe PaymentProcessor do
  subject(:payment_processor) { described_class.new }

  # vvvvvv
  let(:braintree_gateway) { inject_rspec_double(payment_processor,Braintree::Gateway) }
  # ^^^^^^

  before do
    # No need to mock :new
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

This saves a few lines of code (which, again, will add up over time), but will also fail is `PaymentProcessor` does not depend on
`Braintree::Gateway` via `uses`.

If you aren't using RSpec or want to control how the mock gets created, you can also use `inject_double`:

```ruby
RSpec.describe PaymentProcessor do
  subject(:payment_processor) { described_class.new }

  # vvvvvv
  let(:braintree_gateway) { inject_double(payment_processor,Braintree::Gateway: double("BT Gateway")) }
  # ^^^^^^

  before do
    # No need to mock :new
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

## Set Up for Testing

You need to `require("uses/inject_double")` and then `include Uses::InjectDouble` to make `inject_rspec_double` and
`inject_double` available. Practically speaking, you should do this in your base test case or RSpec configuration:

```ruby
# spec/spec_helper.rb
require "uses/inject_double"

RSpec.configure do |config|
  config.include Uses::InjectDouble

  # ... remainder of your configuration
end
```


## Reference

### `uses` macro

The `uses` macro does two things:

* Creates a private method that returns a memoized instance of the dependent class
* Instantiates that class

You can control both the name of the method and how the class is instantiated if needed, but the default behavior should work for most cases.

The full signature of `uses` is:

```ruby
uses SomeClass, as: «method name», 
                initialize: «initialization_strategy»
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

#### `as:` option

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

#### `initialize:` option

Not all objects can be created with `.new`. Here are the possible values for `initialize:`

* `:new_no_args` - This is the default and creates an instance by calling `new` without any args. This should be how most of the classes you create are initialized.
* `:config_initializers` - This says that an instance has been pre-configured by a file in `config/initializers` that calls into Uses' configuration API like so:

  ```ruby
  # config/initializers/braintree.rb
  Uses.initializers do |initializers|
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

  Note that it doesn't have to be in a file in `config/initializers`, it just has to be loaded before any class that uses `uses` is loaded.
* A `Proc` - If you set `initialize:` to a `Proc`, that `Proc` will be called to get the instance of the object.  This is useful if the way in which the object is created differs based on what class is including it. This should be used rarely.  Example:

  ```ruby
  class PaymentProcessor
    uses Braintree::Gateway, initialize: ->(*) {
      Braintree::Gateway.new(
        :environment => :sandbox,
        :merchant_id => "your_merchant_id",
        :public_key  => "your_public_key",
        :private_key => "your_private_key",
      )
    }
  end
  ```

### `inject_rspec_double`

The signature of this method is:

```ruby
inject_rspec_double(«object_with_dependency»,
                    «class that it depends on»)
```

`inject_rspec_double` returns an instance created via RSpec's `instance_double` method.  It will raise an exception if `«object_with_dependency»`'s
class does use call `uses «class that it depends on»`.  This way, if you refactor your class to no longer need this dependency, your test will
fail.

### `inject_double`

The signature of this method is:

```ruby
inject_double(«object_with_dependency»,
              «class that it depends on» => «mocked instance»)
```

This is useful if you need to control how the mocked instance is created or if you are not using RSpec.

### `Uses.config`

There is currently one configuration option.

#### `:on_circular_dependency` option

Because the proliferation of `uses` creates a structured representation of your service layer's dependencies, Uses can check for circular
dependencies.  The reason this is important is that your code's behavior can become confusing if a dependency depends on another class that depends
on it.

By default, if a circular dependency is detected, Uses will emit a warning.  You can change this behavior by setting a config value,
which you can do by creating `config/initializers/uses.rb`:

```ruby
# config/initializers/uses.rb
Uses.config do |config|
  config.on_circular_dependency = # one of :warn, :ignore, or :raise_error
end
```

Valid values are:

* `:warn` - this is the default and will emit a warning if a circular dependency is found.
* `:ignore` - this will log a warning a debug level, effectively squelching the message. Don't use this unless you are migrating a service layer that has a lot of circular dependencies.
* `:raise_error` - this will raise an `Uses::CircularDependency::Error` when it encounters a circular dependency.

