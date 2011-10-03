$0 = 'bowd'

require "rubygems"
require "bundler/setup"

require 'erubis'
require 'rubydns'
require 'daemons'

require "#{File.dirname(__FILE__)}/lib/apache"
require "#{File.dirname(__FILE__)}/lib/bow"

if ENV['USER'] != 'root' || ENV['SUDO_USER'] == 'root'
  puts "Bow must be run as root through sudo from your own user"
  exit
end

Bow.instance.logger.info "Bow warming up..."

Apache.instance.path = "/Applications/MAMP/bin/apache2/bin"

domain = 'dev'
port = 5300

# Load detectors
Dir["#{Bow.instance.path}/detectors/*.rb"].each {|file| require file }

# y Bow.instance.detectors

# check "/etc/resolver/#{domain}"
unless File.exists? "/etc/resolver/#{domain}"
  open("/etc/resolver/#{domain}", 'w') do |f|
    f.puts Bow.instance.render('resolver', {:port => port })
  end
end

# apache config injection
apache_config_injection = "
# Bow Apache Injection
Include #{Bow.instance.path}/vhosts/*.conf
"

# check apache configuration for injection
unless Apache.instance.check_config apache_config_injection
  # inject apache configuration
  p "Injecting apache configuration"
  Apache.instance.inject_config apache_config_injection
end

# Start DNS Server
Bow.instance.dns_server_start(5300) do
  match(Regexp.new("(www\.)?(.+)\.#{domain}"),:A) do |match,transaction|
    # Init handler logger
    logger = Bow.instance.create_logger
    # Handle request
    directory_name = match.to_a.last
    p directory_name
    directory = "#{Bow.instance.home}/Sites/#{directory_name}"
    if File.directory? directory
      logger.info "#{directory} found for #{directory_name}.#{domain}"
      vhosts_file = "#{Bow.instance.path}/vhosts/#{directory_name}.conf"
      unless File.exists? vhosts_file
        logger.info "Virtual host file not found."
        open(vhosts_file, 'w') do |f|
          template = Bow.instance.match_template directory
          template_variables = {:document_root => "#{directory}", :domain_name => "#{directory_name}.#{domain}"}
          if !template.nil? && File.exists?("#{Bow.instance.path}/templates/vhost.#{template}.erb");
            logger.info "\"#{template}\" detected. Writing virtual host file."
            f.puts Bow.instance.render("vhost.#{template}", template_variables)
          else
            logger.info "No framework detected. Writing virtual host file."
            f.puts Bow.instance.render("vhost", template_variables)
          end
        end
        FileUtils.chown Bow.instance.user, nil, vhosts_file
        logger.info "Restarting Apache."
        Apache.instance.restart
      end
      transaction.respond!("127.0.0.1")
    else
      transaction.passthrough!(Resolv::DNS.new)
    end
  end

  # Default DNS handler
  otherwise do |transaction|
      transaction.passthrough!(Resolv::DNS.new)
  end
end