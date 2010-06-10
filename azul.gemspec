# Generated by jeweler
# DO NOT EDIT THIS FILE
# Instead, edit Jeweler::Tasks in Rakefile, and run `rake gemspec`
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{azul}
  s.version = "0.2.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["hibariya"]
  s.date = %q{2010-06-10}
  s.default_executable = %q{azul}
  s.description = %q{aozora bunko cui viewer}
  s.email = %q{celluloid.key@gmail.com}
  s.executables = ["azul"]
  s.extra_rdoc_files = [
    "README"
  ]
  s.files = [
    "Rakefile",
     "VERSION",
     "lib/azul.rb",
     "lib/azul/config.rb",
     "lib/azul/shelf.rb",
     "lib/azul/shelf/person.rb",
     "lib/azul/shelf/raw_work.rb",
     "lib/azul/shelf/work.rb",
     "lib/azul/terminal.rb"
  ]
  s.homepage = %q{http://github.com/hibariya/azul}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.6}
  s.summary = %q{aozora bunko cui viewer}
  s.test_files = [
    "spec/spec_helper.rb",
     "spec/azul_spec.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<zipruby>, [">= 0"])
    else
      s.add_dependency(%q<zipruby>, [">= 0"])
    end
  else
    s.add_dependency(%q<zipruby>, [">= 0"])
  end
end
