require "turbine"
require "pry"

Thread.abort_on_exception = true

Dir["#{__dir__}/support/*.rb"].each do |file|
  require file
end
