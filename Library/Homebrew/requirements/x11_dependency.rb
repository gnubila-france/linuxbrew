require 'requirement'
require 'extend/set'
require 'os/linux/x11'

class X11Dependency < Requirement
  include Comparable
  attr_reader :min_version

  fatal true

  if OS.mac?
    env { ENV.x11 }
  end

  def initialize(name="x11", tags=[])
    @name = name
    @min_version = tags.shift if /(\d\.)+\d/ === tags.first
    super(tags)
  end

  satisfy :build_env => false do
    if OS.mac?
      OS.MacOS::XQuartz.installed? && (@min_version.nil? || @min_version <= MacOS::XQuartz.version)
    elsif OS.linux?
      OS::Linux::X11.installed?
    else
      true
    end
  end

  def message
    if OS.mac?
      OS::MacOS::XQuartz.message_missing_dependency
    elsif OS.linux?
      OS::Linux::X11.message_missing_dependency
    else
      "Unsatisfied dependency: X11 #{@min_version}"
    end
  end

  def <=> other
    return nil unless X11Dependency === other

    if min_version.nil? && other.min_version.nil?
      0
    elsif other.min_version.nil?
      1
    elsif min_version.nil?
      -1
    else
      min_version <=> other.min_version
    end
  end
end
