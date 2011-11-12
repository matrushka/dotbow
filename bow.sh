#! /usr/bin/env ruby

$0 = 'bow'

# Warn user for non-root accesses
# if ENV['USER'] != 'root' || ENV['SUDO_USER'] == 'root'
#   puts "Bow must be run as root through sudo from your own user"
#   exit
# end

# Init bundler
require 'rubygems'
require 'bundler'
Dir.chdir "#{File.dirname(__FILE__)}"
Bundler.require(:default)
ENV['BUNDLE_GEMFILE'] ||= File.join(Dir.pwd, 'Gemfile')

# Load classes
require "#{File.dirname(__FILE__)}/lib/bow"
require "#{File.dirname(__FILE__)}/lib/bow_cli"
require "#{File.dirname(__FILE__)}/lib/apache"

# Define domain
domain = ENV['BOW_DOMAIN']
domain ||= 'dev'

# Define DNS port
port = ENV['BOW_DNS_PORT']
port ||= 5300

Bow.new domain, port
BowCli.start
