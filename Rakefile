require "rspec/core/rake_task"
require "bundler/gem_tasks"

require_relative "support/current_bundle"

RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = "--color --format progress --backtrace"
end

task :default do
  if Snowglobe::CurrentBundle.instance.appraisal_in_use?
    sh "rake spec"
  elsif ENV["CI"]
    exec "appraisal install && appraisal rake --trace"
  else
    appraisal = Snowglobe::CurrentBundle.instance.latest_appraisal
    exec "appraisal install && appraisal #{appraisal.name} rake --trace"
  end
end
