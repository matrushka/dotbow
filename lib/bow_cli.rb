class BowCli < Thor
	desc "list", "List domains"
	def list
		puts "LIST"
	end

	desc "edit", "Edit vhost file"
	def edit(vhost)
		system "$EDITOR #{Bow.instance.vhosts}/#{vhost}.conf"
		# plist watcher restarts apache after modification
	end

	desc "clear", "Clear ununsed vhost files"
	def clear
		puts "CLEAR -- NOT IMPLEMENTED YET --"
	end

	desc "install", "Installs bow"
	def install
		puts "Installing bow components"

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