#!/usr/bin/ruby

$:.unshift(File.join(File.expand_path(File.dirname(__FILE__)), '.'))

$root_dir = File.expand_path('..', __FILE__)

require 'rubygems'
require 'lib/web/depcheck'

depchecker = Burpdot::Depcheck.new
depchecker.checkdeps

require 'webrick'
require 'optparse'
require 'parseconfig'

require 'lib/configuration'
require 'lib/web'
require 'lib/import'
require 'lib/output'

Socket.do_not_reverse_lookup = true

#Version and licensing gumpft
verstring = "Version 0.5.2 - 20th of August, 2011 - Created by Christian \"xntrik\" Frichot.\n\n"
verstring += "Copyright 2011 Christian Frichot\n\n"
verstring += "Licensed under the Apache License, Version 2.0 (the \"License\");\n"
verstring += "you may not use this file except in compliance with the License.\n"
verstring += "You may obtain a copy of the License at\n\n"
verstring += "\thttp://www.apache.org/licenses/LICENSE-2.0\n\n"
verstring += "Unless required by applicable law or agreed to in writing, software\n"
verstring += "distributed under the License is distributed on an \"AS IS\" BASIS,\n"
verstring += "WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.\n"
verstring += "See the License for the specific language governing permissions and\n"
verstring += "limitations under the License.\n"

class OptsConsole
  def self.parse(args)
    options = {}
    
    opts = OptionParser.new do |opts|
      opts.banner = "Usage: ./burpweb.rb [options]"
      
      opts.separator ""
      opts.separator "Specific Options:"
      
      opts.on("-h", "--help", "Show help") do |v|
        puts opts
        puts
        exit
      end

      opts.on("-c", "-c <burpweb config file>", "Config: The burpdot web config file. Defaults to 'burpweb.cfg'") do |c|
        options['cfg'] = c
      end

      opts.on("-v", "--version", "Show version") do |v|
        options['version'] = true
      end
      
    end
      
    begin
      opts.parse!(args)

      options['cfg'] = "burpweb.cfg" if options['cfg'].nil? #Default is to burpweb.cfg

    rescue OptionParser::InvalidOption
      puts "Invalid option, try -h for usage"
      exit
    end
      
    options
  end
end

options = OptsConsole.parse(ARGV)

if options['version']
  print verstring
  exit
end

#Load the configuration file
$config = Burpdot::Configuration.new(options['cfg'])

if options['version']
  print verstring
  exit
end

#Starting up the web interface
httpconfig = {}
httpconfig[:BindAddress] = $config.get_value("burpip")
httpconfig[:Port] = $config.get_value("burpport")
httpconfig[:Logger] = WEBrick::Log.new($stdout, WEBrick::Log::DEBUG)
httpconfig[:ServerName] = "BurpDot"
httpconfig[:ServerSoftware] = "BurpDot"

http_server = WEBrick::HTTPServer.new(httpconfig)

#Mount public content
http_server.mount("/",WEBrick::HTTPServlet::FileHandler,"lib/web/static")

#Mount the "burp log" file upload handler
http_server.mount("/logfile",Burpdot::WebBurpFileUpload)

#Mount the "status checker"
http_server.mount("/status",Burpdot::StatusChecker)

#Mount the "db"
http_server.mount("/db",Burpdot::Db)

#Mount the "cruncher"
http_server.mount("/crunch", Burpdot::Crunch)

trap("INT") {
  puts "Quitting..."
  http_server.stop
}

#Kick off the web server NOW! boom!
http_server.start
