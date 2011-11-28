require 'rubygems'

require 'rake'
require 'jeweler'

Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "handlebar"
  gem.homepage = "http://github.com/twg/handlebar"
  gem.license = "MIT"
  gem.summary = %Q{Simple text tempating system}
  gem.description = %Q{A simple text templating system}
  gem.email = "github@tadman.ca"
  gem.authors = [ "Scott Tadman" ]
end

Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

task :default => :test
