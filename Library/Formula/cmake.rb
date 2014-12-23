require "formula"

class NoExpatFramework < Requirement
  def expat_framework
    "/Library/Frameworks/expat.framework"
  end

  satisfy :build_env => false do
    not File.exist? expat_framework
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
  url "http://www.cmake.org/files/v3.0/cmake-3.0.2.tar.gz"
  sha1 "379472e3578902a1d6f8b68a9987773151d6f21a"

  head do
    url "http://cmake.org/cmake.git"

    depends_on "xz" # For LZMA
  end

  bottle do
    cellar :any
    sha1 "29e403721a38731bb3015008b1fe39d0d334c11f" => :yosemite
    sha1 "4b8b26f60d28c85c0119cb9ab136c5b40f8db570" => :mavericks
    sha1 "a7bc77aa9b9855e5d4081ec689bb62c89be7c25d" => :mountain_lion
    sha1 "842240c9febb4123918cf62a3cea5ca4207ad860" => :lion
  end

  option "without-docs", "Don't build man pages"
  depends_on :python => :build if OS.mac? && MacOS.version <= :snow_leopard && build.with?("docs")

  depends_on "qt" => :optional

  resource "sphinx" do
    url "https://pypi.python.org/packages/source/S/Sphinx/Sphinx-1.2.3.tar.gz"
    sha1 "3a11f130c63b057532ca37fe49c8967d0cbae1d5"
  end

  resource "docutils" do
    url "https://pypi.python.org/packages/source/d/docutils/docutils-0.12.tar.gz"
    sha1 "002450621b33c5690060345b0aac25bc2426d675"
  end

  resource "pygments" do
    url "https://pypi.python.org/packages/source/P/Pygments/Pygments-1.6.tar.gz"
    sha1 "53d831b83b1e4d4f16fec604057e70519f9f02fb"
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
        r.stage { Language::Python.setup_install "python", buildpath/"sphinx" }
      end

      # There is an existing issue around OS X & Python locale setting
      # See http://bugs.python.org/issue18378#msg215215 for explanation
      ENV["LC_ALL"] = "en_US.UTF-8"
    end

    args = %W[
      --prefix=#{prefix}
      --system-libs
      --no-system-libarchive
      --datadir=/share/cmake
      --docdir=/share/doc/cmake
      --mandir=/share/man
    ]

    if build.with? "docs"
      args << "--sphinx-man" << "--sphinx-build=#{buildpath}/sphinx/bin/sphinx-build"
    end

    args << "--qt-gui" if build.with? "qt"

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
    bin.install_symlink Dir["#{prefix}/CMake.app/Contents/bin/*"] if build.with? "qt"
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
