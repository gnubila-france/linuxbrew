module OS
  module X11
    extend self

    def installed?
      @installed ||= detect_installed
    end

    def detect_installed
      version ? true : false
    end

    def version
      @version ||= detect_version
    end

    def detect_version
      begin
        version_string = `xterm -version`
        version_string = version_string.match /\((\d+)\)/
	if version_string.nil?
          "0.0.0"
        else
          #return a number as we do not know the real version number
          "2.10"
        end
      rescue Errno::ENOENT
      end
    end
  end
end
