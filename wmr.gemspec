# encoding: UTF-8
#
Gem::Specification.new do |s|
  s.name               = 'wmr'
  s.homepage           = 'http://github.com/zbelzer/wmr'
  s.summary            = 'An interface to WMR100/200'
  s.require_paths      = ['lib']
  s.executables        = ['wmr']
  s.authors            = ['Zachary Belzer', 'Michael Marion', 'Jason Norris']
  s.email              = ['zbelzer@gmail.com']
  s.version            = File.read('VERSION')
  s.platform           = Gem::Platform::RUBY
  s.files              = Dir["**/*"]

  s.add_dependency 'libhid-ruby', '>= 0.0.1'
  s.add_dependency 'trollop', '>= 1.16.2'
end
