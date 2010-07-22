# encoding: utf-8

$: << File.expand_path('../lib', __FILE__)
require 'webrick/httpreverseproxyserver/version'

Gem::Specification.new do |s|
  s.name = "webrick_httpreverseproxyserver"
  s.version = WEBrick::HTTPReverseProxyServer::VERSION
  s.authors = ["Richard Kernahan", "Gregor Schmidt"]
  s.email = "g.schmidt@finn.de"
  s.homepage = "http://github.com/finnlabs/webrick_httpreverseproxyserver"
  s.summary = "Implements a simple reverse HTTP proxy server"
  s.description = "Implements a simple reverse HTTP proxy - useful for advanced configuration or inspection of reverse proxies in development."

  s.files = Dir['{lib/**/*,[A-Z]*}']
  s.platform = Gem::Platform::RUBY
  s.require_path = 'lib'
  s.rubyforge_project = '[none]'
end
