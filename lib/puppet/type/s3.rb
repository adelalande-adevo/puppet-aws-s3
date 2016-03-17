Puppet::Type.newtype(:s3) do

  @@doc =  %q{Get files from S3
   
      Example:
        
        s3 {'/path/on/my/filesystem':
            ensure              => present,
            source              => '/bucket/subdir/s3_object',
            region              => 'us-east-1'
            access_key_id       => 'ITSASECRET',
            secret_access_key   => 'ITSASECRETTOO',
        }

      Or: 
        s3 {'/path/on/my/filesystem':
            ensure              => present,
            source              => '/bucket/subdir/s3_object',
            region              => 'dummy',
            access_key_id       => 'ITSASECRET',
            secret_access_key   => 'ITSASECRETTOO',
            endpoint            => 'https://my-endpoint',
            ssl_verify_peer     => false,
            force_path_style    => true,
        }
  }
  
  ensurable do
    defaultto :present
    newvalue :present do
      provider.create
    end
    newvalue :absent do
      provider.destroy
    end
    newvalue :latest do
      provider.update
    end
  end

  newparam(:path, :namevar => true) do
    desc "Path to the file on the local filesystem"
    validate do |v|
        path = Pathname.new(v)
        unless path.absolute?
            raise ArgumentError, "Path not absolute: #{path}"
        end
    end
  end

  newparam(:source) do
      desc "The aws s3 bucket path"
  end

  newparam(:access_key_id) do
      desc "AWS secret access key id"
  end

  newparam(:secret_access_key) do
      desc "AWS secret access key"
  end

  newparam(:region) do
      desc "AWS region of S3"
  end

  newparam(:endpoint) do
      desc "AWS endpoint of S3"
  end

  newparam(:ssl_verify_peer, :boolean => true) do
      desc "Verify ssl peer for s3 endpoint"
  end

  newparam(:force_path_style, :boolean => true) do
      desc "Left the bucket name in the request URI"
  end

end

