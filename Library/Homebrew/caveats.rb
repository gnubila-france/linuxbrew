class Caveats
  attr_reader :f

  def initialize(f)
    @f = f
  end

  def caveats
    caveats = []
    s = f.caveats.to_s
    caveats << s.chomp + "\n" if s.length > 0
    caveats << f.keg_only_text if f.keg_only? && f.respond_to?(:keg_only_text)
    caveats << bash_completion_caveats
    caveats << zsh_completion_caveats
    caveats << plist_caveats
    caveats << python_caveats
    caveats << app_caveats
    caveats.compact.join("\n")
  end

  def empty?
    caveats.empty?
  end

  private

  def keg
    @keg ||= [f.prefix, f.opt_prefix, f.linked_keg].map do |d|
      Keg.new(d.resolved_path) rescue nil
    end.compact.first
  end

  def bash_completion_caveats
    if keg and keg.completion_installed? :bash then <<-EOS.undent
      Bash completion has been installed to:
        #{HOMEBREW_PREFIX}/etc/bash_completion.d
      EOS
    end
  end

  def zsh_completion_caveats
    if keg and keg.completion_installed? :zsh then <<-EOS.undent
      zsh completion has been installed to:
        #{HOMEBREW_PREFIX}/share/zsh/site-functions
      EOS
    end
  end

  def python_caveats
    return unless keg
    return unless keg.python_site_packages_installed?

    s = nil
    homebrew_site_packages = Language::Python.homebrew_site_packages
    user_site_packages = Language::Python.user_site_packages "python"
    pth_file = user_site_packages/"homebrew.pth"
    instructions = <<-EOS.undent.gsub(/^/, "  ")
      mkdir -p #{user_site_packages}
      echo 'import site; site.addsitedir("#{homebrew_site_packages}")' >> #{pth_file}
    EOS

    if f.keg_only?
      keg_site_packages = f.opt_prefix/"lib/python2.7/site-packages"
      unless Language::Python.in_sys_path?("python", keg_site_packages)
        s = <<-EOS.undent
          If you need Python to find bindings for this keg-only formula, run:
            echo #{keg_site_packages} >> #{homebrew_site_packages/f.name}.pth
        EOS
        s += instructions unless Language::Python.reads_brewed_pth_files?("python")
      end
      return s
    end

    return if Language::Python.reads_brewed_pth_files?("python")

    if !Language::Python.in_sys_path?("python", homebrew_site_packages)
      s = <<-EOS.undent
        Python modules have been installed and Homebrew's site-packages is not
        in your Python sys.path, so you will not be able to import the modules
        this formula installed. If you plan to develop with these modules,
        please run:
      EOS
      s += instructions
    elsif keg.python_pth_files_installed?
      s = <<-EOS.undent
        This formula installed .pth files to Homebrew's site-packages and your
        Python isn't configured to process them, so you will not be able to
        import the modules this formula installed. If you plan to develop
        with these modules, please run:
      EOS
      s += instructions
    end
    s
  end

  def app_caveats
    if keg and keg.app_installed?
      <<-EOS.undent
        .app bundles were installed.
        Run `brew linkapps #{keg.name}` to symlink these to /Applications.
      EOS
    end
  end

  def plist_caveats
    return "" unless OS.mac?
    s = []
    if f.plist or (keg and keg.plist_installed?)
      destination = f.plist_startup ? '/Library/LaunchDaemons' \
                                    : '~/Library/LaunchAgents'

      plist_filename = if f.plist
        f.plist_path.basename
      else
        File.basename Dir["#{keg}/*.plist"].first
      end
      plist_link = "#{destination}/#{plist_filename}"
      plist_domain = f.plist_path.basename('.plist')
      destination_path = Pathname.new File.expand_path destination
      plist_path = destination_path/plist_filename

      # we readlink because this path probably doesn't exist since caveats
      # occurs before the link step of installation
      # Yosemite security measures mildly tighter rules:
      # https://github.com/Homebrew/homebrew/issues/33815
      if !plist_path.file? || !plist_path.symlink?
        if f.plist_startup
          s << "To have launchd start #{f.name} at startup:"
          s << "    sudo mkdir -p #{destination}" unless destination_path.directory?
          s << "    sudo cp -fv #{f.opt_prefix}/*.plist #{destination}"
          s << "    sudo chown root #{plist_link}"
        else
          s << "To have launchd start #{f.name} at login:"
          s << "    mkdir -p #{destination}" unless destination_path.directory?
          s << "    ln -sfv #{f.opt_prefix}/*.plist #{destination}"
        end
        s << "Then to load #{f.name} now:"
        if f.plist_startup
          s << "    sudo launchctl load #{plist_link}"
        else
          s << "    launchctl load #{plist_link}"
        end
      # For startup plists, we cannot tell whether it's running on launchd,
      # as it requires for `sudo launchctl list` to get real result.
      elsif f.plist_startup
          s << "To reload #{f.name} after an upgrade:"
          s << "    sudo launchctl unload #{plist_link}"
          s << "    sudo cp -fv #{f.opt_prefix}/*.plist #{destination}"
          s << "    sudo chown root #{plist_link}"
          s << "    sudo launchctl load #{plist_link}"
      elsif Kernel.system "/bin/launchctl list #{plist_domain} &>/dev/null"
          s << "To reload #{f.name} after an upgrade:"
          s << "    launchctl unload #{plist_link}"
          s << "    launchctl load #{plist_link}"
      else
          s << "To load #{f.name}:"
          s << "    launchctl load #{plist_link}"
      end

      if f.plist_manual
        s << "Or, if you don't want/need launchctl, you can just run:"
        s << "    #{f.plist_manual}"
      end

      s << "" << "WARNING: launchctl will fail when run under tmux." if ENV['TMUX']
    end
    s.join("\n") unless s.empty?
  end
end
