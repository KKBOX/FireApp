#\ -p 4000

require 'rubygems'
require 'bundler'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'serve'
require 'serve/rack'
require "rack/coffee"


# The project root directory
root = ::File.dirname(__FILE__)

# Compile Sass on the fly with the Sass plugin. Some production environments
# don't allow you to write to the file system on the fly (like Heroku).
# Remove this conditional if you want to compile Sass in production.
require 'sass'
require 'sass/plugin/rack'
require 'compass'

Compass.add_project_configuration( Compass.detect_configuration_file(root) )
Compass.configure_sass_plugin!

use Sass::Plugin::Rack  # Sass Middleware


# Other Rack Middleware
use Rack::ShowStatus      # Nice looking 404s and other messages
use Rack::ShowExceptions  # Nice looking errors

use Rack::Coffee, { 
  :root => File.join(root, 'coffeescripts'), 
  :urls => Compass.configuration.http_javascripts_path,
  :cache_compile => true
}

# Rack Application
if ENV['SERVER_SOFTWARE'] =~ /passenger/i
  # Passenger only needs the adapter
  run Serve::RackAdapter.new( root )
else
  # Use Rack::Cascade and Rack::Directory on other platforms for static assets
  run Rack::Cascade.new([
    Serve::RackAdapter.new( root ),
    Rack::Directory.new( root )
  ])
end
