require 'formula'

class Bzip2 < Formula
  homepage 'http://apr.apache.org/'
  url 'http://www.bzip.org/1.0.6/bzip2-1.0.6.tar.gz'
  sha1 '3f89f861209ce81a6bab1fd1998c0ef311712002'

  keg_only :provided_by_osx

  def install
    # Compilation will not complete without deparallelize
    ENV.deparallelize

    system "make install PREFIX=#{prefix}"
  end
end
