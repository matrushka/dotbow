require 'singleton'
class Apache
  include Singleton
  attr_accessor :path, :config_path 
  def initialize
    # load apache path to be used with bow
    @path = ENV['BOW_APACHE_PATH']
    # find apache path if none given
    if @path.nil?
      @path = File.dirname(`which apachectl`)
    end 
    @config_path = `#{@path}/apachectl -V`[/SERVER_CONFIG_FILE="(.+)"/,1]
  end
  
  def check_config string
    `cat #{@config_path}`[string].nil?
  end
  
  def inject_config string
    open(@config_path, 'a') do |f|
      f.puts string
    end
  end
  
  def restart
    `#{@path}/apachectl restart`
  end
end