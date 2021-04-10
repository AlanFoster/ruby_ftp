#!/usr/bin/env ruby

require 'bundler/setup'
require 'ruby_ftp'

host = '127.0.0.1'
port = 21

client = RubyFtp::Client.new(port: port, host: host)

# Create a breakpoint with:
#   require 'pry'; binding.pry

puts "Connecting to #{port} #{host}"

puts 'client.banner:'
puts client.banner
puts

puts 'client.help:'
puts client.help
puts

puts 'client.login:'
puts client.login(username: 'ftpuser', password: 'ftpuser')
puts

puts 'client.pwd:'
puts client.pwd
puts

puts 'client.ls:'
puts client.ls
puts

puts 'client.cat:'
puts client.cat('abc.txt')
puts

client.close
