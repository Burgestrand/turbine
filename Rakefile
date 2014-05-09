desc "Start a pry console with the gem loaded"
task :console do
  exec "pry", "-Ilib", "-rturbine"
end

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new

task default: :spec
