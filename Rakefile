require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "itunes-connect"
    gem.summary = %Q{Get your iTunes Connect Reports}
    gem.description = %Q{Programmatic and command-line access to iTunes Connect Reports}
    gem.email = "alex.vollmer@gmail.com"
    gem.homepage = "http://github.com/alexvollmer/itunes-connect"
    gem.authors = ["Alex Vollmer"]
    gem.files = FileList["lib/**/*.rb", "bin/*", "spec/**/*"]

    gem.add_dependency "httpclient", "~>2.1"
    gem.add_dependency "nokogiri", "~>1.3"
    gem.add_dependency "clip", ">=1.0.1"
    gem.add_dependency "sqlite3-ruby", "~>1.2"

    gem.add_development_dependency "rspec"
    gem.add_development_dependency "fakeweb"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec => :check_dependencies

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  if File.exist?('VERSION')
    version = File.read('VERSION')
  else
    version = ""
  end

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "itunes-connect #{version}"
  rdoc.main = 'README.rdoc'
  rdoc.rdoc_files.include('lib/*.rb')
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/itunes_connect/*.rb')
end
