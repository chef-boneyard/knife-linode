require 'bundler'
Bundler::GemHelper.install_tasks
require 'rake/rdoctask'

begin
  require 'sdoc'

  Rake::RDocTask.new do |rdoc|
    rdoc.title = 'Chef Ruby API Documentation'
    rdoc.main = 'README.rdoc'
    rdoc.options << '--fmt' << 'shtml' # explictly set shtml generator
    rdoc.template = 'direct' # lighter template
    rdoc.rdoc_files.include(
      'README.rdoc',
      'LICENSE',
      'spec/tiny_server.rb',
      'lib/**/*.rb'
    )
    rdoc.rdoc_dir = 'rdoc'
  end
rescue LoadError
  puts 'sdoc is not available. (sudo) gem install sdoc to generate rdoc ' + \
       'documentation.'
end

begin
  require 'rspec/core/rake_task'

  task default: :spec

  desc 'Run all specs in spec directory'
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.pattern = 'spec/unit/**/*_spec.rb'
  end
rescue LoadError
  STDERR.puts '\n*** RSpec not available. (sudo) gem install rspec to run ' + \
              'unit tests. ***\n\n'
end
