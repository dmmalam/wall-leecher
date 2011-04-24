# -*- encoding: utf-8 -*-

path = File.expand_path(File.join(File.dirname(__FILE__), 'lib'))
$LOAD_PATH.unshift path unless $LOAD_PATH.include? path
require 'options'

Gem::Specification.new do |s|
  s.name        = "wall-leecher"
  s.version     = WallLeecher::Options.version.join('.')
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Dharmesh Malam"]
  s.email       = ["dmmalam@gmail.com"]
  s.license     = 'ISC'
  s.homepage    = "http://github.com/dmmalam/wall-leecher"
  s.summary     = "A Ruby Event Machine driven command line wallpaper downloader that can search from a variety of sites."
  s.description = <<-EOF
  Wall-Leech is a script to crawl a website and download interesting items (ie wallpaper images), but this can be anything.
  It's written in Event Machine to provide high performance non blocking IO, and new sites can be easily added
  EOF
  s.required_ruby_version     = ">= 1.9.2"
  s.required_rubygems_version = ">= 1.5.0"

  s.add_dependency "eventmachine", "~> 1.0.0.beta.3"
  s.add_dependency "em-http-request", "~> 1.0.0.beta.3"
  s.add_dependency "em-files", "~> 0.2.2"
  s.add_dependency "nokogiri", "~> 1.4.4"

  s.add_development_dependency "bundler", ">= 1.0.0"
  s.add_development_dependency "rspec", ">= 2.5.0"


  s.files        = `git ls-files`.split("\n")
  s.executables  = `git ls-files bin`.split("\n").map{|f| f[/^bin\/(.*)/,1 ]}
  s.require_path = 'lib'
end