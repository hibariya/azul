# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{azurterm}
  s.version = "0.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["hibariya"]
  s.date = %q{2010-06-08}
  s.default_executable = %q{azurterm}
  s.description = %q{aozora bunko cui viewer}
  s.email = %q{celluloid.key@gmail.com}
  s.executables = ["azurterm"]
  s.extra_rdoc_files = [
    "README"
  ]
  s.files = [
    "Rakefile",
     "VERSION",
     "lib/azurterm.rb",
     "lib/azurterm/config.rb",
     "lib/azurterm/shelf.rb",
     "lib/azurterm/shelf/person.rb",
     "lib/azurterm/shelf/raw_work.rb",
     "lib/azurterm/shelf/work.rb",
     "lib/azurterm/terminal.rb"
  ]
  s.homepage = %q{http://github.com/hibariya/azurterm}
  s.rdoc_options = ["--main", "README.rdoc", "--exclude", "spec"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.6}
  s.summary = %q{aozora bunko cui viewer}
  s.test_files = [
    "spec/azurterm_spec.rb",
     "spec/spec_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end

