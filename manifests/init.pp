class s3 {

	package { "rubygems":
        ensure => 'installed'
    }

    package { 'aws-sdk':
        ensure   => 'latest',
        provider => 'gem',
    }

    package { 'hash_validator':
    	 ensure   => installed,
    	 provider => 'gem',
    }

    Package['aws-sdk'] ->
    Package['hash_validator'] -> S3 <| |>
}
