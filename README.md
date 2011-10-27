# Bow is an Apache manager daemon for web developers using Mac OS X
-----
Make the directories on your users Sites directory accessible from apache by using '.dev' tld.

Example: /Users/matrushka/Sites/test will be available as http://test.dev

You do not have to make any configurations like hosts file etc.

Currently under construction. You can dig in to see and make it work but nothing is guaranteed yet.

## Installation

Clone git to ~/.bow

```shell
git clone git@github.com:matrushka/dotbow.git ~/.bow
```

Run install script as super user (LaunchDaemon installation requires root user rights)

```shell
sudo ~/.bow/bow install
```

## Usage

Lets assume you have a folder named test under ~/Sites. When you type test.dev to your browser bow will detect it and create a vhost file to be loaded by apache. It may take a few refreshes but when apache restarts you'll be able to visit that test directory by using test.dev.

Bow tries to detect the framework you are using to fill the initial vhost file. Bow currently supports Rack (if you have passenger for apache installed), Symfony 1, Symfony 2. It is possible to add more frameworks (so i am waiting for pull requests!).

### Edit
You can easily edit the vhost file of your domain by typing

```shell
~/.bow/bow edit DOMAIN_NAME
```

This will open the vhost file in your shells $EDITOR (you can use vim, nano, Textmate, Sublime Text) and reloads apache after the file is saved.

### List (NOT IMPLEMENTED YET)
```shell
~/.bow/bow list
```
This will list all domains managed by .bow

### Clear (NOT IMPLEMENTED YET)
```shell
~/.bow/bow clear
```
And this one will clear vhost files which are bound to non-existing directories

## Detectors

You can add your own detectors for other frameworks all you have to do is create a DETECTOR_NAME.rb file for detector module in detectors directory and a vhost.DETECTOR_NAME.erb file for vhost template in templates directory. Existing template and detector codes are easy to understand.

Currently only the application path (Such as ~/Sites/test) is provided for detector module and application path with domain name is provided for detector template file. But further parameters can be added if necessary.

You can see existing Rack Detector codes below.

### Rack Detector Module
```ruby
module RackDetector
  Bow.instance.detectors.push self
  def self.detect path
    return File.exists?("#{path}/config.ru") && File.directory?("#{path}/public") && File.directory?("#{path}/tmp")
  end
end
```
### Rack Detector Template
```
<VirtualHost *:80>
  ServerName <%= domain_name %>
  ServerAlias *.<%= domain_name %>
  DocumentRoot "<%= document_root %>/public"
  <Directory "<%= document_root %>/public">
    Allow from all
    Options -MultiViews
  </Directory>
</VirtualHost>
```

-----
&copy; 2011 Baris Gumustas
