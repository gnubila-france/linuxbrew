class TcpWrappers < Formula
  homepage "ftp://ftp.porcupine.org/pub/security/index.html"
  url "ftp://ftp.porcupine.org/pub/security/tcp_wrappers_7.6.tar.gz"
  sha1 "61689ec85b80f4ca0560aef3473eccd9e9e80481"

  # Fixes some build issues and adds building a shared library
  # see: http://www.linuxfromscratch.org/blfs/view/6.3/basicnet/tcpwrappers.html
  patch do
    url "http://www.linuxfromscratch.org/patches/blfs/6.3/tcp_wrappers-7.6-shared_lib_plus_plus-1.patch"
    sha1 "915652d43c57f346d6f0a14eeaf706bbfed98ffa"
  end

  # scaffold.c: Removes an obsolete C declaration which causes the build to fail if using GCC >= 3.4.x
  # Makefile: fix installation paths
  patch :DATA

  def install

    ENV["DESTDIR"] = "#{prefix}"
    ENV["STYLE"] = "-DPROCESS_OPTIONS"

    system "make", "linux"
    lib.mkdir
    include.mkdir
    mkdir_p "#{share}/man/man3"
    system "make", "install-lib"
    system "make", "install-dev"
  end
end

__END__
diff -ur tcp_wrappers_7.6/Makefile tcp_wrappers_7.6.fixed/Makefile
--- tcp_wrappers_7.6/Makefile	2012-04-10 11:45:38.000000000 -0700
+++ tcp_wrappers_7.6.fixed/Makefile	2012-04-10 14:11:58.000000000 -0700
@@ -768,9 +768,9 @@
 install: install-lib install-bin install-dev
 
 install-lib:
-	install -o root -g root -m 0755 $(SHLIB) ${DESTDIR}/usr/lib/
-	ln -sf $(notdir $(SHLIB)) ${DESTDIR}/usr/lib/$(notdir $(SHLIBSOMAJ))
-	ln -sf $(notdir $(SHLIBSOMAJ)) ${DESTDIR}/usr/lib/$(notdir $(SHLIBSO))
+	install -m 0755 $(SHLIB) ${DESTDIR}/lib/
+	ln -sf $(notdir $(SHLIB)) ${DESTDIR}/lib/$(notdir $(SHLIBSOMAJ))
+	ln -sf $(notdir $(SHLIBSOMAJ)) ${DESTDIR}/lib/$(notdir $(SHLIBSO))
 
 install-bin:
 	install -o root -g root -m 0755 tcpd ${DESTDIR}/usr/sbin/
@@ -787,12 +787,12 @@
 	install -o root -g root -m 0644 hosts_options.5 ${DESTDIR}/usr/share/man/man5/
 
 install-dev:
-	install -o root -g root -m 0644 hosts_access.3 ${DESTDIR}/usr/share/man/man3/
-	install -o root -g root -m 0644 tcpd.h ${DESTDIR}/usr/include/
-	install -o root -g root -m 0644 $(LIB) ${DESTDIR}/usr/lib/
-	ln -sf hosts_access.3 ${DESTDIR}/usr/share/man/man3/hosts_ctl.3
-	ln -sf hosts_access.3 ${DESTDIR}/usr/share/man/man3/request_init.3
-	ln -sf hosts_access.3 ${DESTDIR}/usr/share/man/man3/request_set.3
+	install -m 0644 hosts_access.3 ${DESTDIR}/share/man/man3/
+	install -m 0644 tcpd.h ${DESTDIR}/include/
+	install -m 0644 $(LIB) ${DESTDIR}/lib/
+	ln -sf hosts_access.3 ${DESTDIR}/share/man/man3/hosts_ctl.3
+	ln -sf hosts_access.3 ${DESTDIR}/share/man/man3/request_init.3
+	ln -sf hosts_access.3 ${DESTDIR}/share/man/man3/request_set.3
 
 shar:	$(KIT)
 	@shar $(KIT)
diff -ur tcp_wrappers_7.6/scaffold.c tcp_wrappers_7.6.fixed/scaffold.c
--- tcp_wrappers_7.6/scaffold.c	2012-04-10 11:45:38.000000000 -0700
+++ tcp_wrappers_7.6.fixed/scaffold.c	2012-04-10 12:48:14.000000000 -0700
@@ -25,7 +25,7 @@
 #define	INADDR_NONE	(-1)		/* XXX should be 0xffffffff */
 #endif
 
-extern char *malloc();
+/* extern char *malloc(); */
 
 /* Application-specific. */
 
Only in tcp_wrappers_7.6.fixed: scaffold.c-e
