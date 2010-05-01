# -*- encoding: utf-8 -*-
require 'bundler'

Gem::Specification.new do |s|
  s.name = %q{wrapt}
  s.version = "0.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Daniel Neighman"]
  s.date = %q{2010-04-30}
  s.description = %q{Layouts in rack}
  s.summary = %q{Layouts in rack}
  s.homepage = %q{http://github.com/hassox/wrapt}
  s.email = %q{has.sox@gmail.com}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.6}

  s.files = Dir[File.join(Dir.pwd, "**/*")]

  s.add_bundler_dependencies
end

