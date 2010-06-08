require 'rubygems'
require 'rake'
 
begin
  require 'jeweler'
	Jeweler::Tasks.new do |gemspec|
		gemspec.name = "azurterm"
		gemspec.summary = "aozora bunko cui viewer"
		gemspec.email = "celluloid.key@gmail.com"
		gemspec.homepage = "http://github.com/hibariya/azurterm"
		gemspec.description = "aozora bunko cui viewer"
    gemspec.executables = ["azurterm"]
		gemspec.authors = %w(hibariya)
		gemspec.has_rdoc = true
		gemspec.rdoc_options = ["--main", "README.rdoc", "--exclude", "spec"]
	  gemspec.files = FileList['lib/**/*.rb', 'VERSION', 'Rakefile']
	end
rescue LoadError
	puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
	spec.libs << 'lib' << 'spec'
	spec.spec_files = FileList['spec/**/*_spec.rb']
end
task :default => :spec

