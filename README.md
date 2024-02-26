# Snowglobe [![Gem Version][version-badge]][rubygems] [![Build Status][travis-badge]][travis] ![Downloads][downloads-badge]

[version-badge]: https://img.shields.io/gem/v/snowglobe.svg
[rubygems]: https://rubygems.org/gems/shoulda-matchers
[travis-badge]: https://img.shields.io/travis/mcmire/snowglobe/master.svg
[travis]: https://travis-ci.org/mcmire/snowglobe
[downloads-badge]: https://img.shields.io/gem/dtv/snowglobe.svg

Snowglobe is a gem
that helps erect and destroy Rails applications for use in tests.

## Installation

Add this line to your project's Gemfile:

``` ruby
gem 'snowglobe'
```

And then execute:

``` bash
bundle
```

Alternatively, install it directly using:

``` bash
gem install snowglobe
```

## Usage

Snowglobe was developed for gems
which provide some kind of integration with application frameworks (like Rails)
or test frameworks (like RSpec and Minitest)
and thus require complete tests to ensure that said integration works as intended.
Ideally,
to simulate a real-world environment,
such tests would generate some kind of project which has been preconfigured to load the working version of the gem
and then execute some bit of code within that project
in a completely separate Ruby process than the one that is running the tests.

That's exactly what Snowglobe lets you do.
Snowglobe provides three classes for use in your test setup
which create different kinds of projects:

* `Snowglobe::RailsApplication` creates a minimal Rails application
* `Snowglobe::RspecProject` creates a project that is preconfigured with RSpec
* `Snowglobe::MinitestProject` creates a project that is preconfigured with Minitest

You will want to start by telling Snowglobe the name of your project.
You can do that by adding the following to your test setup:

``` ruby
Snowglobe.configure do |config|
  config.project_name = "my_project_name_goes_here"
end
```

By default, Snowglobe places generated projects in a global temporary directory,
but it's customary for Rails applications to have a `tmp` directory,
so you can configure Snowglobe to use that instead:

``` ruby
Snowglobe.configure do |config|
  config.project_name = "my_project_name_goes_here"
  # This assumes you've placed this configuration block in test/test_helper.rb
  # or spec/spec_helper.rb; update to match
  config.temporary_directory = Pathname.new("../tmp").expand_path(__dir__)
end
```

Next, you will want to define a file in your test setup
that inherits from one of the classes listed above.
For instance:

``` ruby
class AppThatLoadsMyGem < Snowglobe::RailsApplication
end
```

Snowglobe's project classes have a `create` method
which you will need to override in order to customize the project.
These classes also have convenience methods for allowing you to interact with the generated project,
such as updating the Gemfile, adding new files, or running commands within the project.
For instance, if you want to load your gem in the project,
you would define `create` like so:

``` ruby
def create
  super
  add_gem 'my_gem', path: File.expand_path('../path/to/my/gem', __FILE__)
end
```

Once you've defined your project class,
you can make use of it in your tests
to generate an instance of the project
and run a command inside of it.
For instance,
your test might look like:

``` ruby
it 'does something useful' do
  app = AppThatLoadsMyGem.new

  app.write_file('test/example_test.rb', <<~FILE)
    require 'test_helper'

    class MyTest < Minitest::Test
      def some_test
        assert true
      end
    end
  FILE

  app.create

  command = app.run_n_unit_tests('test/example_test.rb')

  expect(command).to be_success
end
```

That was admittedly a very brief primer,
but it should be enough to get you started.
For more:

* Read through the source code for [RailsApplication],
  [RspecProject],
  and [MinitestProject]
  to get an idea of the differences between these strategies.
* Review the [delegators in Project]
  (which is the superclass of all strategies)
  to learn what kinds of methods you can call on a Project.
* Take a look at the [tests for WarningsLogger] for an example.

[RailsApplication]: https://github.com/mcmire/snowglobe/blob/update-readme/lib/snowglobe/rails_application.rb
[RspecProject]: https://github.com/mcmire/snowglobe/blob/update-readme/lib/snowglobe/rspec_project.rb
[MinitestProject]: https://github.com/mcmire/snowglobe/blob/update-readme/lib/snowglobe/minitest_project.rb
[delegators in project]: https://github.com/mcmire/snowglobe/blob/update-readme/lib/snowglobe/project.rb#L16
[tests for WarningsLogger]: https://github.com/mcmire/warnings_logger/blob/master/spec/unit/warnings_logger_spec.rb

## Developing

* `bin/setup` to get started
* `bundle exec rake release` to release a new version

## Compatibility

Snowglobe is [tested][travis] and supported against Ruby 2.6+ and Rails 5.0+.

## Author/License

Snowglobe is copyring © Elliot Winkler (<elliot.winkler@gmail.com>)
and is released under the [MIT license](LICENSE).
