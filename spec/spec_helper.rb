require "timeout"
require "turbine"
require "pry"

Thread.abort_on_exception = true

Dir["#{__dir__}/support/*.rb"].each do |file|
  require file
end

RSpec.configure do |config|
  config.around(:each) do |example|
    Timeout.timeout(5, TimeoutError, &example)
  end
end
