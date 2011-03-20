require 'rubygems'
require 'rake'

desc 'Builds the gem'
task :build do
  system "gem build wmr.gemspec"
end

desc 'Builds and installs the gem'
task :install => :build do
  system "gem install wmr-#{File.read('VERSION')}"
end
