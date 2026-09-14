require "simplecov"
SimpleCov.start "rails" do
  enable_coverage :branch
  skip %r{^/test/}
  skip %r{^/config/}
  skip %r{^/db/}
  skip "app/channels/application_cable/connection.rb"
  group "Services", "app/services"
  group "Jobs", "app/jobs"
  minimum_coverage 90
end
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
Dir[Rails.root.join("test/support/**/*.rb")].each { |file| require file }
module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)
    parallelize_setup do |worker|
      SimpleCov.command_name "#{SimpleCov.command_name}-#{worker}"
    end
    parallelize_teardown do |_worker|
      SimpleCov.result
    end
    fixtures :all
    include ActiveJob::TestHelper
    include SessionTestHelper
    include ImportTestHelper
  end
end
