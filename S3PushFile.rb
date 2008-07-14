#!/usr/bin/env ruby

#--
#    Name    : S3PushFile.rb
#    Author  : Jerod Santo
#    Contact : jerod.santo@gmail.com
#    Date    : 2008 July 2
#    About   : given a filename and bucket, uploads to AWS S3
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
  puts "Usage: S3PushFile.rb [file_name] [bucket_name]"
  exit
end

file_name = ARGV[0]
bucket = ARGV[1]

AWS::S3::Base.establish_connection!(
        :access_key_id      => ACCESS_KEY,
        :secret_access_key  => SECRET_KEY,
        :use_ssl            => 'true'
        )

AWS::S3::S3Object.store( file_name, open(file_name), bucket )
