
Puppet::Parser::Functions::newfunction(:download_file, :type => :rvalue, :doc =>
  "Downloads a file into a file server mount on the server, unless it's already there,
   and returns the appropriate puppet:/// URL for the puppet client to use.

       file { '/tmp/test':
         ensure => file,
         source => download_file('files', 'foo/bar/test', 'http://server/test')
       }

   You can pass a SHA-1 checksum as fourth argument to verify the download.") do |args|
    require 'digest/sha1'
    require 'fileutils'
    require 'open-uri'
    require 'puppet/file_serving/configuration'

    self.fail "Plugins mount point is not supported" if args[0] == 'plugins'

    mount = args[0]
    path = args[1]
    url = args[2]
    checksum = args[3]

    if mount == 'modules' then
      module_name, path = path.split('/', 2)
      mod = environment.module(module_name)
      base_dir = mod.file(nil)
    else
      mnt = Puppet::FileServing::Configuration.configuration.find_mount(mount, environment)
      if not mnt then
        self.fail "No mount found named #{mount}"
      end
      base_dir = mnt.path(compiler.node)
    end
    file_name = ::File.join(base_dir, path)

    unless ::FileTest.exist?(file_name) then
      Puppet.info "Downloading #{url} to #{file_name}"
      parent_dir = ::File.dirname(file_name)
      ::FileUtils.mkdir_p(parent_dir) unless ::FileTest.exist?(parent_dir)
      ::File.open(file_name, 'wb') do |file|
        open(url, 'rb') do |stream|
          until stream.eof?
            # StringIO doesn't support :readpartial
            if stream.respond_to?(:readpartial)
              file.write(stream.readpartial(1024))
            else
              file.write(stream.read(1024))
            end
          end
        end
      end
    end
    if checksum then
      hash = ::Digest::SHA1::new
      ::File.open(file_name, 'rb') do |file|
        until file.eof?
          hash.update(file.readpartial(1024))
        end
      end
      fail 'Non-matching SHA-1 checksum' unless checksum == hash.hexdigest
    end

    # Don't use #{path} as we changed the value in the 'modules' case
    "puppet:///#{mount}/#{args[1]}"
end
