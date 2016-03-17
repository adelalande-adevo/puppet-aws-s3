
# Get files from AWS S3 or S3 compatible API like Ceph or Cleversafe
#
# Example with config file:
#
#   s3 { '/path/to/my/filesystem':
#       ensure => present,
#       source => '/bucket/path/to/object',
#   }
#
# or s3:
#
#   s3 { '/path/to/my/filesystem':
#       ensure            => present,
#       source            => '/bucket/path/to/object',
#       access_key_id     => 'mysecret',
#       secret_access_key => 'anothersecret',
#       region            => 'eu-west-1',
#   }
# or s3 compatible storage:
#
#   s3 { '/path/to/my/filesystem':
#       ensure            => present,
#       source            => '/bucket/path/to/object',
#       access_key_id     => 'mysecret',
#       secret_access_key => 'anothersecret',
#       region            => 'dummy',
#       endpoint          => 'https://my-endpoint.com'
#       ssl_verify_peer   => false,
#       force_path_style  => true
#   }
#
#   Author: François Gouteroux, francois.gouteroux@gmail.com

require 'rubygems'
require 'aws-sdk' if Puppet.features.awssdk?
require 'hash_validator' if Puppet.features.hashvalidator?
require 'digest'
require 'tempfile'

Puppet::Type.type(:s3).provide(:s3) do
  confine :feature => :awssdk
  confine :feature => :hashvalidator

  desc "Get S3 files"

  def s3_client

    valid_s3_config = {
      :access_key_id     => 'string',
      :secret_access_key => 'string',
      :region            => 'string'
    }

    s3_config = {
      :access_key_id     => resource[:access_key_id],
      :secret_access_key => resource[:secret_access_key],
      :region            => resource[:region]
    }

    if resource[:endpoint]
      s3_config[:endpoint]         = resource[:endpoint]
      s3_config[:ssl_verify_peer]  = resource[:ssl_verify_peer]
      s3_config[:force_path_style] = resource[:force_path_style]

      valid_s3_config[:endpoint]         = 'string'
      valid_s3_config[:ssl_verify_peer]  = 'boolean'
      valid_s3_config[:force_path_style] = 'boolean'
    end

    s3_resource_config = HashValidator.validate(s3_config, valid_s3_config)

    if s3_resource_config.valid?
      Puppet.debug "Using Aws S3 config from s3 class."
    else
      Puppet.debug "Config from s3 class not valid. Some parameters are missing or not defined #{s3_resource_config.errors}"

      # Try to load config from file
      config_file = File.join([File.dirname(Puppet.settings[:config]), "aws_config.yaml"])
      if File.exist?(config_file) and !File.zero?(config_file)
        config = YAML.load_file(config_file)
        Puppet.debug "Using Aws S3 config from file: #{config_file}"

        s3_config = {
          :access_key_id     => config[:access_key_id],
          :secret_access_key => config[:secret_access_key],
          :region            => config[:region]
        }

        if config[:endpoint]
          s3_config[:endpoint]         = config[:endpoint]
          s3_config[:ssl_verify_peer]  = config[:ssl_verify_peer]
          s3_config[:force_path_style] = config[:force_path_style]

          valid_s3_config[:endpoint]         = 'string'
          valid_s3_config[:ssl_verify_peer]  = 'boolean'
          valid_s3_config[:force_path_style] = 'boolean'
        end

        s3_config_file = HashValidator.validate(s3_config, valid_s3_config)

        if s3_config_file.valid?
          Puppet.debug "Aws S3 config file loaded."
        else
          raise Puppet.err "Failed to load s3 config from #{config_file}. Some parameters are missing or not defined #{s3_config_file.errors}"
        end
      else
        Puppet.debug "Aws config file #{config_file} missing or not readable"
        raise Puppet.err "No s3 valid config found"
      end
    end

    # Create a new S3 client object
    s3 = Aws::S3::Client.new(s3_config)


    return s3
      
  end

  def create
    begin
      # Get the name of the bucket and path to the object:
      source_ary  = resource[:source].chomp.split('/')
      source_ary.shift # Remove prefixed white space

      bucket      = source_ary.shift
      key         = File.join(source_ary)

      # Handle new S3 object
      resp = s3_client.get_object(
          response_target: resource[:path],
          bucket:          bucket,
          key:             key,
      )
    rescue Aws::S3::Errors::ServiceError => e
      raise Puppet::Error, "#{e.code}: #{e.message}"

    end
  end

  def destroy

      # rm rf some file on the filesystem that points to resource[:path]
    
  end

  def exists?

    if File.exists?(resource[:path])
      true
    else
      false
    end
  end

  def update
    begin
      if File.exists?(resource[:path])

        # Do all the same stuff I did for create
        source_ary  = resource[:source].chomp.split('/')
        source_ary.shift # Remove prefixed white space
        
        bucket      = source_ary.shift
        key         = File.join(source_ary)

        Puppet.debug('Comparing MD5 values for file: ' + key)
        # Retrieves metadata from an object without returning the object itself.
        s3_object = s3_client.head_object(
            bucket: bucket,
            key: key
        )
        # Remove trailing quotes
        s3_object_md5 = s3_object.etag.gsub(/"/, '')

        # Compare the MD5 hashes, return true or false 
        file_md5 = Digest::MD5.file(resource[:path]).hexdigest

        if file_md5 == s3_object_md5
          Puppet.debug("File #{key} already up-to-date")
        else
          Puppet.debug("Update file from #{file_md5} to #{s3_object_md5}")
          s3_client.get_object(
            response_target: resource[:path],
            bucket:          bucket,
            key: key
          )
        end
      else
        create
      end
    rescue Aws::S3::Errors::ServiceError => e
      raise Puppet::Error, "#{e.code}: #{e.message}"
    end
  end
end
