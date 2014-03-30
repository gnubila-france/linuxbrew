module OS
  module Linux
    X11 = Module.new

    module X11
      extend self

      def version
        @version ||= detect_version
      end

      def detect_version
        version_string = `X -version 2>&1`.strip
        version_string.split("\n")[0].match(/(\d+\.?)+/)[0]
      end

      def installed?
        @installed ||= detect_installed
      end

      def detect_installed
        `ldconfig -p`.split("\n").select{|s| s =~ /libX11.so/}
      end

      def message_missing_dependency
        "Unsatisfied dependency: X11 #{@min_version}"
      end

    end
  end
end
