Puppet::Type.type(:package).provide(:brewcask,
                                    :parent => :brewcommon,
                                    :source => :brewcommon) do
  desc "Package management using HomeBrew casks on OS X"

  def install
    name = install_name
    output = execute([command(:brew), :cask, :install, name, *install_options])
    # brewcask includes some funky beer characters that f*ck with encoding
    output = output.encode('UTF-8', :invalid => :replace, :undef => :replace)

    if output.empty?
      raise Puppet::ExecutionFailure, "Could not find package #{name}"
    end
  end

  def uninstall
    execute([command(:brew), :cask, :uninstall, @resource[:name]])
  end

  def update
    install
  end

  def self.package_list(options={})
    begin
      if name = options[:justme]
        # Of course brew-cask has a different --versions format than brew when
        # getting the version of a single package
        result = execute([command(:brew), :cask, :list, '--versions'])
        unless result.empty?
          result = Hash[result.lines.map {|line| line.split}]
          result = result[name] ? name + ' ' + result[name] : ''
        end
      else
        result = execute([command(:brew), :cask, :list, '--versions'])
      end
      list = result.lines.map {|line| name_version_split(line)}
    rescue Puppet::ExecutionFailure => detail
      raise Puppet::Error, "Could not list packages: #{detail}"
    end


    if options[:justme]
      return list.shift
    else
      return list
    end
  end

  def self.name_version_split(line)
    if line =~ (/^(\S+)\s+(.+)/)
      {
        :name     => $1,
        :ensure   => $2,
        :provider => :brewcask
      }
    else
      Puppet.warning "Could not match #{line}"
      nil
    end
  end
end