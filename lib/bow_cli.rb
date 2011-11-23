class BowCli < Thor
	desc "list", "List domains"
	def list
		vhosts = {}
		max_domain_length = 0
		tab_size = `echo -e "\t"`.length
		Dir["#{Bow.instance.vhosts}/*.conf"].each do |vhost|
			domain_name = File.basename(vhost,'.conf')
			domain_length_in_tabs = (domain_name.length.to_f/tab_size.to_f)
			vhosts[domain_name] = domain_length_in_tabs
			if domain_length_in_tabs > max_domain_length
				max_domain_length = domain_length_in_tabs.floor
			end
		end

		vhosts.each do |domain,tab_count|
			directory = "#{Bow.instance.home}/Sites/#{domain}"
			if File.directory? directory
				domain = domain.bold.green
			else
				domain = domain.bold.red
			end
			framework = Bow.instance.match_template directory
			framework ||= 'default'.black
			puts "#{domain}#{"\t" * (max_domain_length-tab_count)}\t#{framework}"
		end
	end

	desc "switch", "Switch to the specified domain directory"
	def switch(domain)
		command = "cd #{Bow.instance.home}/Sites/#{domain}"
		print "execute:"+command+"\n"
	end

	desc "edit", "Edit vhost file"
	def edit(vhost)
		# plist watcher restarts apache after modification (this is why i have to touch it first)
		# WatchPaths in launchd does not detect file changes it'll only detect new and deleted files (also touches on that directory)
		print "execute_and_refresh:#{ENV['EDITOR']} #{Bow.instance.vhosts}/#{vhost}.conf"
	end

	desc "clear", "Clear ununsed vhost files"
	def clear
		Dir["#{Bow.instance.vhosts}/*.conf"].each do |vhost|
			domain_name = File.basename(vhost,'.conf')
			directory = "#{Bow.instance.home}/Sites/#{domain_name}"
			unless File.directory? directory
				puts "Deleting: #{domain_name}".bold.red
				File.delete("#{Bow.instance.vhosts}/#{domain_name}.conf")
			end
		end
	end

	desc "install", "Installs bow"
	def install
		puts "Installing bow components".bold

		if ENV['USER'] != 'root' || ENV['SUDO_USER'] == 'root'
			puts "Bow install must be run as root through sudo from your own user"
			exit
		end

		if Bow.instance.prepare_resolver
			puts "[+] Created .#{domain} resolver".bold.green
		else
			puts "[ ] Resolver already exists".yellow.green
		end

		if Bow.instance.prepare_apache
			puts "[+] Injected Apache configs".bold.green
		else
			puts "[ ] Apache already injected".yellow.green
		end

		if Bow.instance.prepare_daemon
			puts "[+] Generated & loaded daemon plist".bold.green
		else
			puts "[ ] Daemon plist already exists".yellow.green
		end

		if Bow.instance.prepare_agent
			puts "[+] Generated & loaded agent plist".bold.green
		else
			puts "[ ] Agent plist already exists".yellow.green
		end

		puts "---------------------------------------".black.bold
		puts "Please add the line below to your shell profile"
		puts "#{Bow.instance.path}/bow_profile.sh # Load Bow".bold
		puts "---------------------------------------".black.bold
	end

	desc "uninstall", "Uninstalls bow"
	def uninstall
		puts "UNINSTALL -- NOT IMPLEMENTED YET --"
	end

	desc "server", "Start bow server"
	def server
		# Start DNS Server
		Bow.instance.dns_server_start
	end
end