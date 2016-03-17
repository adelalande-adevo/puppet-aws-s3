# puppet-aws-s3

Get files from AWS S3 or S3 compatible API like Ceph or Cleversafe.

## Requirements

```gem install aws-sdk``` (at least 2.x.x)
```gem install hash_validator```

Ensure to ```include s3``` in your catalogue so those gems get installed. 

## How to use

**List of available parameters:**
- **access_key_id**: Used to set credentials statically
- **secret_access_key**: Used to set credentials statically
- **region**: The AWS region to connect to. The region is used to construct the client endpoint.
- **endpoint**: A default endpoint is constructed from the :region
- **ssl_verify_peer**: Verify ssl peer
- **force_path_style**: When set to true, the bucket name is always left in the request URI and never moved to the host as a sub-domain. 

The s3 resource is instanciated as such:

```ruby
s3 { '/path/to/file/on/my/local/filesystem':
    ensure              => present,
    source              => '/bucket/path/to/object',
    access_key_id       => 'mysecret',
    secret_access_key   => 'anothersecret',
    region              => 'us-west-1',
}
```

For S3 Compatible API:

```ruby
s3 { '/path/to/file/on/my/local/filesystem':
    ensure              => present,
    source              => '/bucket/path/to/object',
    access_key_id       => 'mysecret',
    secret_access_key   => 'anothersecret',
    region              => 'dummy',
    endpoint            => 'https://my-endpoint.com'
    ssl_verify_peer     => false,
    force_path_style    => true
}
```

## Setting

Parameters can be setting up from:
- resource class
- config file

First the provider look for resource class and after for a config file

### resource config

```ruby
s3 { '/path/to/file/on/my/local/filesystem':
    ensure              => present,
    source              => '/bucket/path/to/object',
    access_key_id       => 'mysecret',
    secret_access_key   => 'anothersecret',
    region              => 'us-west-1',
}
```

### Config file

```ruby
s3 { '/path/to/file/on/my/local/filesystem':
    ensure => present,
    source => '/bucket/path/to/object',
}
```

**aws_config.yaml** in puppet config dir

    ---
    :access_key_id: access-key-id
    :secret_access_key: secret-key-id
    :region: dummy

    # S3 compatible
    :endpoint: https://my-endpoint.com
    :ssl_verify_peer: false
    :force_path_style: true


This provider support the md5 check file. If you set:

```ruby
s3 { '/path/to/file/on/my/local/filesystem':
    ensure => latest,
    source => '/bucket/path/to/object',
}
```

It will compare the **s3 remote file etag** with the **md5 checksum of local file**.
If it's false, the **local file** will be replaced by the **s3 remote file**.


    Info: Applying configuration version '1458146261'
    Debug: Comparing MD5 values for file: certcmd.txt
    Debug: Using Aws S3 config from s3 class.
    Debug: Update file from 0eb5b8524d8680fc260d658b1c6d8d6c to 176c8bad69d42bbad238311d95e38063
    Debug: Using Aws S3 config from s3 class.
    Notice: /Stage[main]/Test/S3[/tmp/test.txt]/ensure: ensure changed 'present' to 'latest'
    Debug: /Stage[main]/Test/S3[/tmp/test.txt]: The container Class[Test] will propagate my refresh event
    Debug: Class[Test]: The container Stage[main] will propagate my refresh event
    Debug: Finishing transaction 70348243477820
    Debug: Storing state
    Debug: Stored state in 0.00 seconds
    Notice: Finished catalog run in 0.92 seconds

Licence
-------

Copyright 2016 - François Gouteroux <francois.gouteroux@gmail.com>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
