require "rubygems"
require "bundler/setup"

Bundler.require(:default)

require "#{File.dirname(__FILE__)}/lib/bow"
require "#{File.dirname(__FILE__)}/lib/apache"

if RUBY_PLATFORM.downcase.include?("darwin")
	puts "Installing LaunchAgents"
	service_name = "com.bow.bowd"
	launch_agent_location = "#{Bow.instance.home}/#{service_name}.plist"
	unless File.exists? launch_agent_location
		open(launch_agent_location,'w') do |f|
			f.puts Bow.instance.render("#{service_name}.plist",{
				
			})
		end
	end
end

# if [ uname == "Darwin" ]; then
# 	echo "Setting up LaunchAgent"
# 	# copy PLIST and (re)install it
# 	SERVICE_NAME = "com.bow.bowd"
# 	PLIST_FILE = "$SERVICE_NAME.plist"
# 	# Place user agent file
# 	cp $PLIST_FILE $HOME/LaunchAgents/.
# 	launchctl stop $SERVICE_NAME
# 	launchctl unload $HOME/LaunchAgents/$PLIST_FILE
# 	launchctl load $HOME/LaunchAgents/$PLIST_FILE
# 	launchctl start $SERVICE_NAME
# else
# 	echo ""
# fi
# 
# echo "FINISHED";