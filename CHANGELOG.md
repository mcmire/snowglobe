# Changelog

## Backward-incompatible changes

* Change `temporary_directory` configuration option to optimize for specifying
  `tmp` inside of an existing project.

## Features

* Support creating Rails 6 applications. Webpacker and Bootsnap are skipped in
  this case.
* Add the ability to create RSpec- and Minitest-centric projects.

## Improvements

* Start testing against Ruby 2.7.
* Stop supporting Rails 4.2.
* Improve CommandRunner to capture stdout and stderr separately.
* Use a cross-platform means of defaulting `temporary_directory`.

## 0.3.0 - 2019-04-21

### Features

* Configure Minitest tests to run in a sorted order.

## 0.2.0 - 2019-04-20

### Features

* Add `run_command` to Snowglobe::RailsApplication.

## 0.1.0 - 2019-03-16

Initial release.
