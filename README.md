
This module provides a `download_file` function to download files on the puppet
master to then serve them to the puppet agents.

This is (almost) equivalent to having the following, but running on the puppet
master rather than the puppet agent:

    exec { '/usr/bin/wget -q -O /tmp/test http://server/test':
      creates => '/tmp/test',
    }

The (almost) equivalent to the above would be:

    file { '/tmp/test':
      ensure => present,
      source => download_file('files', 'server/test',
                    'http://server/test'),
    }

The puppet master would download the file into the `files` file server mount at the
`server/test` relative path, unless that file already exists, and return
`puppet:///files/server/test` so the puppet agent can download it from the file
server.

The `modules` mount point is also supported.

Use case
========

 * The puppet master's `/etc/puppet` is managed as a Git repository.
 * I don't want to store large binaries in Git when they can easily be downloaded.
 * I don't want puppet agents to download files themselves using `wget` or `curl`.
   I prefer they load files from the puppet master where all files are centralized.

Note this is **not** about reducing network load (a caching HTTP proxy would do that
more easily), it's about not storing large binaries in Git (where they'd be kept for
posterity in the Git history).

