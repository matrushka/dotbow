require 'singleton'
require 'logger'
class Bow
  attr_reader :path, :home, :vhosts, :templates, :user, :detectors, :logger, :domain, :port
  @@instance = nil

  def initialize domain, port
    @path = File.expand_path(File.dirname(__FILE__)+"/..")

    @vhosts = File.expand_path(@path+"/vhosts")
    @templates = File.expand_path(@path+"/templates")

    @user = ENV['SUDO_USER']
    @user ||= ENV['USER']

    @home = `sudo -u #{@user} echo $HOME`.chomp
    @detectors = []

    # Create logger with 10MB of shift size
    @logger = Logger.new("#{@path}/log/bow.log", 0, (10 * 1024 * 1024))
    @logger.formatter = proc { |severity, datetime, progname, msg|
      "[#{severity}] #{datetime}: #{msg}\n"
    }

    @domain = domain
    @port = port

    # check for vhosts directory
    unless File.directory? @vhosts
      FileUtils.mkdir_p @vhosts
      FileUtils.chown_R @user, nil, @vhosts
    end
    @@instance = self
  end

  def self.instance
    if @@instance.nil?
      raise "Bow has not been initialized"
    end
    @@instance
  end

  def match_template path
    if @detectors.empty?
      # Load detectors
      Dir["#{@path}/detectors/*.rb"].each {|file| require file }
    end
    @detectors.each do |detector|
      if detector.detect path
        return detector.to_s.match(/(.+)Detector/i)[1].downcase
      end
    end
    return nil
  end

  def create_logger
    logger = Logger.new("#{@path}/log/bow.log", 0, (10 * 1024 * 1024))
    logger.formatter = proc { |severity, datetime, progname, msg|
      "[#{severity}] #{datetime}: #{msg}\n"
    }
    return logger
  end

  def render template, bindings
    erb = Erubis::Eruby.new(File.read("#{@templates}/#{template}.erb"))
    erb.method(:result).call bindings
  end


  def prepare_resolver
    # check "/etc/resolver/#{domain}"
    unless File.exists? "/etc/resolver/#{@domain}"
      FileUtils.mkdir_p "/etc/resolver"
      File.open("/etc/resolver/#{@domain}", 'w+') do |f|
        f.puts Bow.instance.render('resolver', {:port => @port })
      end
      return true
    end
    return false
  end

  def daemon_path
    "/Library/LaunchDaemons/com.bow.refresh.plist"
  end

  def prepare_daemon
    # check "/Library/LaunchDaemons/com.bow.server.plist"
    unless File.exists? daemon_path
      # write plist file
      File.open(daemon_path, 'w+') do |f|
        f.puts Bow.instance.render("com.bow.refresh", {:username => Bow.instance.user ,:apachectl_path => "#{Apache.instance.path}/apachectl", :vhosts_dir => Bow.instance.vhosts})
      end
      # chmod gotta be 644
      File.chmod(0644, daemon_path)
      # chown to root:wheel
      FileUtils.chown('root', 'wheel', daemon_path)
      # load plist
      `sudo launchctl load #{daemon_path}`
      return true
    end
    return false
  end

  def agent_path
    "#{Bow.instance.home}/Library/LaunchAgents/com.bow.server.plist"
  end

  def prepare_agent
    # check "/Library/LaunchDaemons/com.bow.server.plist"
    unless File.exists? agent_path
      # write plist file
      File.open(agent_path, 'w+') do |f|
        f.puts Bow.instance.render("com.bow.server", {:bow_path => "#{Bow.instance.path}/run-server.sh"})
      end
      # chmod gotta be 644
      File.chmod(0644, agent_path)
      # chown to root:wheel
      FileUtils.chown(Bow.instance.user, 'staff', agent_path)
      # load plist
      `launchctl load #{agent_path}`
      return true
    end
    return false
  end

  def prepare_apache
    # apache config injection
    apache_config_injection = "
    # Bow Apache Injection
    NameVirtualHost *:80
    Include #{@path}/vhosts/*.conf
    "

    # check apache configuration for injection
    if Apache.instance.check_config apache_config_injection
      # inject apache configuration
      Apache.instance.inject_config apache_config_injection
      return true
    end
    return false
  end

  def dns_server_start
    Bow.instance.logger.info "Bow server warming up..."
    DNSServer.start({
      :port => @port,
      :host => "127.0.0.1",
      :logger => Bow.instance.logger,
      :resolver => proc do |name, type|
        # Seek host in available hosts
        site_name = name.match("(www\.)?(.+)\.#{Bow.instance.domain}").to_a.last
        # Init handler logger
        logger = Bow.instance.logger
        # Handle request
        directory = "#{Bow.instance.home}/Sites/#{site_name}"
        if File.directory? directory
          logger.info "#{directory} found for #{site_name}.#{Bow.instance.domain}"
          vhosts_file = "#{Bow.instance.path}/vhosts/#{site_name}.conf"
          unless File.exists? vhosts_file
            logger.info "Virtual host file not found."
            open(vhosts_file, 'w') do |f|
              template = Bow.instance.match_template directory
              template_variables = {:document_root => "#{directory}", :domain_name => "#{site_name}.#{Bow.instance.domain}"}
              if !template.nil? && File.exists?("#{Bow.instance.path}/templates/vhost.#{template}.erb");
                logger.info "\"#{template}\" detected. Writing virtual host file."
                f.puts Bow.instance.render("vhost.#{template}", template_variables)
              else
                logger.info "No framework detected. Writing virtual host file."
                f.puts Bow.instance.render("vhost", template_variables)
              end
            end
            FileUtils.chown Bow.instance.user, nil, vhosts_file
            # plist watcher restarts apache after modification (this is why i have to touch it first)
            # WatchPaths in launchd does not detect file changes it'll only detect new and deleted files (also touches on that directory)
            # system "touch #{Bow.instance.vhosts}" # Unnecessary since new file is caught by WatchPaths
            logger.info "Waiting for Apache Refresher."
            sleep 3
            # May be we can loop for 10 seconds while checking apache status?
            logger.info "Response sent."
          end
          { :ttl => 16000, :ip => "127.0.0.1" }
        else
          logger.info "#{directory} not found for #{site_name}.#{Bow.instance.domain}"
          nil
        end
      end
    })
  end
end