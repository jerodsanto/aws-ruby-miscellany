#!/usr/bin/env ruby

#--
#    Name  : S3FolderSync.rb
#    Author: Jerod Santo
#    Date  : 2008 July 02
#    About : Given local folder and AWS S3 bucket,
#            synchronizes files stored on each
#--

require 'find'
require 'syslog'
require 'rubygems'
require 'aws/s3'


ACCESS_KEY = ENV["S3_ACCESS"]
SECRET_KEY = ENV["S3_SECRET"]

unless ACCESS_KEY and SECRET_KEY
  puts "You must set S3_ACCESS and S3_SECRET environment variables with your AWS info"
  exit
end


# monkeypatch aws/s3 gem to allow for S3 folders
# see: http://rubyurl.com/vRaf
module AWS
  module S3
    class S3Object
      class << self

        alias :original_store :store
        def store(key, data, bucket = nil, options = {})
          store_folders(key, bucket, options) if options[:use_virtual_directories]
          original_store(key, data, bucket, options)
        end

        def store_folders(key, bucket = nil, options = {})
          folders = key.split("/")
          folders.slice!(0)
          folders.pop
          current_folder = "/"
          folders.each {|folder|
            current_folder += folder
            store_folder(current_folder, bucket, options)
            current_folder += "/"
          }
        end

        def store_folder(key, bucket = nil, options = {})
          original_store(key + "_$folder$", "", bucket, options) # store the magic entry that emulates a folder
        end
      end
    end
  end
end

unless ARGV.length == 2
  puts "Usage: S3FolderSync.rb [local directory] [S3 bucket name]"
  exit
end

local_dir = File.expand_path(ARGV[0])
aws_bucket = ARGV[1]

def is_folder?(file)
  return true if file.match(/\$folder\$$/)
  false
end

def folder_name(file)
  file.match(/\/?(\w+)_/)
  $1
end

def on_aws?(local,aws_files)
  rval = false
  aws_files.each do |remote|
    if is_folder?(remote)
      remote = folder_name(remote) 
    end
    if local == remote
      rval = true
    end
  end
  rval
end

def on_local?(aws,local_files)
  rval = false
  if is_folder?(aws)
    aws = folder_name(aws)
  end
  local_files.each do |local|
    if local == aws
      rval = true
    end
  end
  rval
end

local_files = Array.new
aws_files = Array.new

Syslog.open( 'S3FolderSync' )

AWS::S3::Base.establish_connection!(
:access_key_id  => ACCESS_KEY,
:secret_access_key  => SECRET_KEY,
:use_ssl  => true )

bucket = AWS::S3::Bucket.find(aws_bucket)

#recursively load all local files
Find.find(local_dir) do |path|
  path.gsub!(local_dir + "/", "") #we want relative dirs, not absolute
  unless path.match(/^\./) or path == local_dir #ignore dotfiles and root directory
    local_files << path
  end
  if FileTest.directory?(path)
    next
  end
end

#load all aws files
bucket.each { |object| aws_files << object.key }
#aws_files.each { |f| puts "#{f} = #{is_folder?(f)} = #{folder_name(f) }" }
#exit

#if local files aren't on aws, ulpoad them
local_files.each do |local_file|
  unless on_aws?(local_file,aws_files)
    if FileTest.directory?(local_dir + "/" + local_file)
      Syslog.notice( "#{local_file} is not on AWS: creating directory..." )
      AWS::S3::S3Object.store_folder( local_file, aws_bucket )
    else
      Syslog.notice( "#{local_file} is not on AWS: uploading..." )
      AWS::S3::S3Object.store( local_file, open( local_dir + "/" + local_file ), aws_bucket )
    end
  end
end

#if aws files aren't on local, delete them
aws_files.each do |aws_file|
  unless on_local?(aws_file,local_files)
    Syslog.notice("#{aws_file} is not on local: removing...")
    AWS::S3::S3Object.delete( aws_file,aws_bucket )
  end
end

Syslog.notice( "Terminating process." )
Syslog.close
