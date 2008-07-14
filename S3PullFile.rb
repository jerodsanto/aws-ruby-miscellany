#!/usr/bin/env ruby

#--
#    Name    : S3PullFile.rb
#    Author  : Jerod Santo
#    Contact : jerod.santo@gmail.com
#    Date    : 2008 July 2
#    About   : given a filename and bucket, downloads from AWS S3
#--

require 'rubygems'
require 'aws/s3'

ACCESS_KEY = ENV["S3_ACCESS"]
SECRET_KEY = ENV["S3_SECRET"]

unless ACCESS_KEY and SECRET_KEY
  puts "You must set S3_ACCESS and S3_SECRET environment variables with your AWS info"
  exit
end

unless ARGV.length == 2
  puts "Usage: S3GrabFile.rb [file_name] [bucket_name]"
  exit
end

file_name = ARGV[0]
bucket = ARGV[1]

AWS::S3::Base.establish_connection!(
        :access_key_id      => ACCESS_KEY,
        :secret_access_key  => SECRET_KEY,
        :use_ssl            => 'true'
        )

file = AWS::S3::S3Object.find( file_name, bucket )

File.open(file_name,"w") do |new_file|
  new_file.syswrite(file.value)
end
