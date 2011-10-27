class BowCli < Thor
	desc "list", "List domains"
	def list
		vhosts = {}
		Dir["#{Bow.instance.vhosts}/*.conf"].each do |vhost|
			domain_name = File.basename(vhost,'.conf')
			tab_size = `echo -e "\t"`.length
			vhosts[domain_name] = (domain_name.length.to_f/tab_size.to_f)
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
			puts "#{domain}#{"\t" * (vhosts.max[1]-tab_count)}\t#{framework}"
		end
	end

	desc "edit", "Edit vhost file"
	def edit(vhost)
		system "$EDITOR #{Bow.instance.vhosts}/#{vhost}.conf"
		# plist watcher restarts apache after modification
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