class NoExpatFramework < Requirement
  def expat_framework
    "/Library/Frameworks/expat.framework"
  end

  satisfy :build_env => false do
    !File.exist? expat_framework
  end

  def message; <<-EOS.undent
    Detected #{expat_framework}

    This will be picked up by CMake's build system and likely cause the
    build to fail, trying to link to a 32-bit version of expat.

    You may need to move this file out of the way to compile CMake.
    EOS
  end
end

class Cmake < Formula
  homepage "http://www.cmake.org/"
  head "http://cmake.org/cmake.git"
  revision 1

  stable do
    url "http://www.cmake.org/files/v3.1/cmake-3.1.1.tar.gz"
    sha1 "e96098e402903e09f56d0c4cfef516e591088d78"

    # Patching CMake for OpenSSL 1.0.2
    # Already commited upstream. Should be in next release.
    # http://www.cmake.org/gitweb?p=cmake.git;a=commit;h=de4ccee75a89519f95fcbcca75abc46577bfefea
    patch do
      url "https://github.com/Kitware/CMake/commit/c5d9a828.diff"
      sha1 "61b15b638c1409233f36e6e3383b98cab514c3bb"
    end

    # This patch fixes ncurse finding issue: http://public.kitware.com/Bug/view.php?id=15011
    patch do
      url "https://github.com/Kitware/CMake/commit/6c8364e6.diff"
      sha1 "32d20530ac5efc3e2ec2ae9091924562022be60f"
    end

    # Fix: http://public.kitware.com/Bug/view.php?id=15220
    patch do
      url "https://github.com/Kitware/CMake/commit/f11f9579.diff"
      sha1 "8faca235b85862f46fb33e8dd954b4accb079a73"
    end

  end

  bottle do
    cellar :any
    sha1 "4b2f2b564e8714815bcf7f2e739ecbee06880453" => :yosemite
    sha1 "4819694722d8330444915b1696cb1b3f56c78881" => :mavericks
    sha1 "ed7d6626d1c1685ff4a4bc795a3b559fab7aeb01" => :mountain_lion
  end

  option "without-docs", "Don't build man pages"
  depends_on :python => :build if OS.mac? && MacOS.version <= :snow_leopard && build.with?("docs")
  depends_on "xz" # For LZMA

  # The `with-qt` GUI option was removed due to circular dependencies if
  # CMake is built with Qt support and Qt is built with MySQL support as MySQL uses CMake.
  # For the GUI application please instead use brew install caskroom/cask/cmake.

  resource "sphinx" do
    url "https://pypi.python.org/packages/source/S/Sphinx/Sphinx-1.2.3.tar.gz"
    sha1 "3a11f130c63b057532ca37fe49c8967d0cbae1d5"
  end

  resource "docutils" do
    url "https://pypi.python.org/packages/source/d/docutils/docutils-0.12.tar.gz"
    sha1 "002450621b33c5690060345b0aac25bc2426d675"
  end

  resource "pygments" do
    url "https://pypi.python.org/packages/source/P/Pygments/Pygments-2.0.2.tar.gz"
    sha1 "fe2c8178a039b6820a7a86b2132a2626df99c7f8"
  end

  resource "jinja2" do
    url "https://pypi.python.org/packages/source/J/Jinja2/Jinja2-2.7.3.tar.gz"
    sha1 "25ab3881f0c1adfcf79053b58de829c5ae65d3ac"
  end

  resource "markupsafe" do
    url "https://pypi.python.org/packages/source/M/MarkupSafe/MarkupSafe-0.23.tar.gz"
    sha1 "cd5c22acf6dd69046d6cb6a3920d84ea66bdf62a"
  end

  depends_on NoExpatFramework

  # Temporary patch to prevent:
  # -- extracting... [tar xfz]
  # CMake Error: Problem with archive_write_finish_entry(): Can't restore time
  # CMake Error: Problem extracting tar: /tmp/sailfish-n30248/sailfish-0.6.3/external/cmph-2.0.tar.gz
  #
  patch :DATA

  def install
    if build.with? "docs"
      ENV.prepend_create_path "PYTHONPATH", buildpath+"sphinx/lib/python2.7/site-packages"
      resources.each do |r|
        r.stage do
          system "python", *Language::Python.setup_install_args(buildpath/"sphinx")
        end
      end

      # There is an existing issue around OS X & Python locale setting
      # See http://bugs.python.org/issue18378#msg215215 for explanation
      ENV["LC_ALL"] = "en_US.UTF-8"
    end

    args = %W[
      --prefix=#{prefix}
      --system-libs
      --parallel=#{ENV.make_jobs}
      --no-system-libarchive
      --datadir=/share/cmake
      --docdir=/share/doc/cmake
      --mandir=/share/man
    ]

    if build.with? "docs"
      args << "--sphinx-man" << "--sphinx-build=#{buildpath}/sphinx/bin/sphinx-build"
    end

    system "./bootstrap", *args
    system "make"
    #Find X11 library
    system "sed -i '/\s*set(X11_INC_SEARCH_PATH/a #{HOMEBREW_PREFIX}/include' Modules/FindX11.cmake"
    system "sed -i '/\s*set(X11_LIB_SEARCH_PATH/a #{HOMEBREW_PREFIX}/lib' Modules/FindX11.cmake"
    #Find include unix path
    system "sed -i -e '/list(APPEND CMAKE_SYSTEM_INCLUDE_PATH/a   #LinuxBrew\\n  #{HOMEBREW_PREFIX}/include' Modules/Platform/UnixPaths.cmake"
    system "sed -i -e '/list(APPEND CMAKE_SYSTEM_LIBRARY_PATH/a   #LinuxBrew\\n  #{HOMEBREW_PREFIX}/lib' Modules/Platform/UnixPaths.cmake"
    # Default include directories
    system "sed -i -e 's# /usr/include$# #{HOMEBREW_PREFIX}/include /usr/include#g' Modules/Platform/UnixPaths.cmake"
    system "make", "install"
  end

  test do
    (testpath/"CMakeLists.txt").write("find_package(Ruby)")
    system "#{bin}/cmake", "."
  end
end

__END__
diff --git a/Utilities/cmlibarchive/libarchive/archive_write_disk_posix.c b/Utilities/cmlibarchive/libarchive/archive_write_disk_posix.c
index a7cf53f..feeaf3c 100644
--- a/Utilities/cmlibarchive/libarchive/archive_write_disk_posix.c	2014-09-11 15:24:02.000000000 +0200
+++ b/Utilities/cmlibarchive/libarchive/archive_write_disk_posix.c	2014-12-18 14:07:04.000000000 +0100
@@ -1730,7 +1730,7 @@
                return (a->lookup_gid)(a->lookup_gid_data, name, id);
        return (id);
 }
-
+
 int64_t
 archive_write_disk_uid(struct archive *_a, const char *name, int64_t id)
 {
@@ -2938,7 +2938,7 @@
 	if (r1 != 0 || r2 != 0) {
 		archive_set_error(&a->archive, errno,
 				  "Can't restore time");
-		return (ARCHIVE_WARN);
+		return (ARCHIVE_OK);
 	}
 	return (ARCHIVE_OK);
 }
