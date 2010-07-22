# encoding: utf-8
require 'rake'
require 'rake/rdoctask'

$: << File.expand_path('../lib', __FILE__)
require 'webrick/httpreverseproxyserver/version'

desc 'Generate documentation for the webrick_httpreverseproxyserver gem.'
Rake::RDocTask.new(:doc) do |doc|
  doc.rdoc_dir = 'doc'
  doc.title = 'WEBRick::HTTPReverseProxyServer'
  doc.options << '--line-numbers' << '--inline-source'
  doc.rdoc_files.include('README.rdoc')
  doc.rdoc_files.include('lib/**/*.rb')
end

desc 'Build gem'
task :build do
  sh 'gem build webrick_httpreverseproxyserver.gemspec'
end

desc "Install gem locally"
task :install => :build do
  sh "gem install webrick_httpreverseproxyserver-#{WEBrick::HTTPReverseProxyServer::VERSION}.gem"
end

desc 'Release gem'
task :release => :build do
  sh "gem push webrick_httpreverseproxyserver-#{WEBrick::HTTPReverseProxyServer::VERSION}.gem"
end
