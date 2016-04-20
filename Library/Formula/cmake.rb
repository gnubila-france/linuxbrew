class Cmake < Formula
  desc "Cross-platform make"
  homepage "https://www.cmake.org/"
  url "https://cmake.org/files/v3.5/cmake-3.5.1.tar.gz"
  sha256 "93d651a754bcf6f0124669646391dd5774c0fc4d407c384e3ae76ef9a60477e8"
  head "https://cmake.org/cmake.git"

  bottle do
    cellar :any_skip_relocation
    sha256 "be1164384380a996c9233fffdaf919c93a0e5bccb1c04e26bb3ba449067abc05" => :el_capitan
    sha256 "fe2f9efc496738dd3da3baa22e8e75ea629fd5e4fb3c891117b866592547dc6f" => :yosemite
    sha256 "2cfe0cca180054794fff3818c2bcba49900eed68e4dd7ce0b79ac5b915e2cf7b" => :mavericks
    sha256 "04b6c1489a02cfed4a7f2f2f8b41fa5257251db7b75a5699c48322e481adb9fc" => :x86_64_linux
  end

  option "without-docs", "Don't build man pages"
  option "with-completion", "Install Bash completion (Has potential problems with system bash)"

  depends_on "sphinx-doc" => :build if build.with? "docs"
  depends_on "bzip2" unless OS.mac?
  depends_on "curl" unless OS.mac?

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

  def install
    args = %W[
      --prefix=#{prefix}
      --no-system-libs
      --parallel=#{ENV.make_jobs}
      --datadir=/share/cmake
      --docdir=/share/doc/cmake
      --mandir=/share/man
      --system-zlib
      --system-bzip2
    ]

    # https://github.com/Homebrew/homebrew/issues/45989
    if MacOS.version <= :lion
      args << "--no-system-curl"
    else
      args << "--system-curl"
    end

    if build.with? "docs"
      # There is an existing issue around OS X & Python locale setting
      # See https://bugs.python.org/issue18378#msg215215 for explanation
      ENV["LC_ALL"] = "en_US.UTF-8"
      args << "--sphinx-man" << "--sphinx-build=#{Formula["sphinx-doc"].opt_bin}/sphinx-build"
    end

   # #Find X11 library
   # system "sed -i '/\s*set(X11_INC_SEARCH_PATH/a #{HOMEBREW_PREFIX}/include' Modules/FindX11.cmake"
   # system "sed -i '/\s*set(X11_LIB_SEARCH_PATH/a #{HOMEBREW_PREFIX}/lib' Modules/FindX11.cmake"
   # #Find prefix unix path
   # system "sed -i -e '/list(APPEND CMAKE_SYSTEM_PREFIX_PATH/a   #LinuxBrew\\n  #{HOMEBREW_PREFIX}' Modules/Platform/UnixPaths.cmake"
   # #Find include unix path
   # system "sed -i -e '/list(APPEND CMAKE_SYSTEM_INCLUDE_PATH/a   #LinuxBrew\\n  #{HOMEBREW_PREFIX}/include' Modules/Platform/UnixPaths.cmake"
   # #Find library unix path
   # system "sed -i -e '/list(APPEND CMAKE_SYSTEM_LIBRARY_PATH/a   #LinuxBrew\\n  #{HOMEBREW_PREFIX}/lib' Modules/Platform/UnixPaths.cmake"
   # # Default include directories. Only search include dire inside linuxbrew (might break non standalone installation)
   # system "sed -i -e 's# /usr/include$# #{HOMEBREW_PREFIX}/include#g' Modules/Platform/UnixPaths.cmake"

    system "./bootstrap", *args
    system "make"
    system "make", "install"

    if build.with? "completion"
      cd "Auxiliary/bash-completion/" do
        bash_completion.install "ctest", "cmake", "cpack"
      end
    end

    (share/"emacs/site-lisp/cmake").install "Auxiliary/cmake-mode.el"

    rm_f pkgshare/"Modules/CPack.OSXScriptLauncher.in" unless OS.mac?
  end

  test do
    (testpath/"CMakeLists.txt").write("find_package(Ruby)")
    system "#{bin}/cmake", "."
  end
end
