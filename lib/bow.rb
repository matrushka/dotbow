require 'singleton'
require 'rubydns'
require 'rubydns/handler'

class Bow
  include Singleton
  attr_accessor :path, :home, :vhosts, :templates, :user, :detectors, :logger

  def initialize
    @path = File.expand_path(File.dirname(__FILE__)+"/..")

    @vhosts = File.expand_path(@path+"/vhosts")
    @templates = File.expand_path(@path+"/templates")

    @user = ENV['SUDO_USER']
    @home = `sudo -u #{@user} echo ~`.chomp
    @detectors = []

    @logger = Logger.new("#{@path}/log/bowd.log")
    @logger.formatter = proc { |severity, datetime, progname, msg|
      "[#{severity}] #{datetime}: #{msg}\n"
    }

    # check for vhosts directory
    unless File.directory? @vhosts
      FileUtils.mkdir_p @vhosts
      FileUtils.chown_R @user, nil, @vhosts
    end
  end

  def match_template path
    @detectors.each do |detector|
      if detector.detect path
        return detector.to_s.match(/(.+)Detector/i)[1].downcase
      end
    end
    return nil
  end

  def create_logger
    logger = Logger.new("#{@path}/log/bowd.log")
    logger.formatter = proc { |severity, datetime, progname, msg|
      "[#{severity}] #{datetime}: #{msg}\n"
    }
    return logger
  end

  def render template, bindings
    erb = Erubis::Eruby.new(File.read("#{@templates}/#{template}.erb"))
    erb.method(:result).call bindings
  end

  def dns_server_start port, &block
    # Init server
    server = RubyDNS::Server.new(&block)
    # Init server logger
    server.logger = Bow.instance.create_logger
    server.logger.info "Starting DNS server..."
    # Run server
		EventMachine.run do
			server.fire(:setup)
			server.logger.info "DNS Server listening on port #{port}"
      EventMachine.open_datagram_socket('127.0.0.1', port, RubyDNS::UDPHandler, server)
      EventMachine.start_server('127.0.0.1', port, RubyDNS::TCPHandler, server)
			server.fire(:start)
		end

		server.fire(:stop)
  end
end