require "bundler/gem_tasks"
begin
  require "rspec/core/rake_task"

  desc "Run all specs in spec directory"
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.pattern = "spec/**/*_spec.rb"
  end

rescue LoadError
  STDERR.puts "\n*** RSpec not available. (sudo) gem install rspec to run unit tests. ***\n\n"
end

begin
  require "chefstyle"
  require "rubocop/rake_task"
  RuboCop::RakeTask.new(:style) do |task|
    task.options << "--display-cop-names"
  end
rescue LoadError
  STDERR.puts "\n*** chefstyle not available. (sudo) gem install chefstyle to run unit tests. ***\n\n"
end

task default: [:spec, :style]
