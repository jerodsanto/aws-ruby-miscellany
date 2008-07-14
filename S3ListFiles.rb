#!/usr/bin/env ruby
#--
#    Name    : S3ListFiles.rb
#    Author  : Jerod Santo
#    Contact : "moc.liamg@otnas.dorej".reverse
#    Date    : 2008 July 11
#    About   : Lists all buckets and associated files on S3 Account
#--

require 'rubygems'
require 'aws/s3'

ACCESS_KEY = ENV["S3_ACCESS"]
SECRET_KEY = ENV["S3_SECRET"]

unless ACCESS_KEY and SECRET_KEY
  puts "You must set S3_ACCESS and S3_SECRET environment variables with your AWS info"
  exit
end

AWS::S3::Base.establish_connection!(
:access_key_id  => ACCESS_KEY,
:secret_access_key  => SECRET_KEY,
:use_ssl  => true )

buckets = AWS::S3::Service.buckets

buckets.each do |bucket|
  puts bucket.name
  
  bucket.objects.each do |object|
    puts "    #{object.key}" unless object.key.match(/_\$folder\$$/)
  end
  puts
end