require 'formula'

class Gtkglext < Formula
  homepage 'http://projects.gnome.org/gtkglext/'
  url 'https://downloads.sourceforge.net/gtkglext/gtkglext-1.2.0.tar.gz'
  sha1 'db9ce38ee555fd14f55083ec7f4ae30e5338d5cc'

  bottle do
    cellar :any
    revision 1
    sha1 "b858e7878b3106fbdc3060afb480f52415007e6c" => :yosemite
    sha1 "93ffc6a0ce780238f417fc2d53b4408ddab1e462" => :mavericks
    sha1 "03c196737dbef40fef3bd51f7feba9040a039d3a" => :mountain_lion
  end

  depends_on 'pkg-config' => :build
  depends_on 'glib'
  depends_on 'gtk+'
  depends_on 'pangox-compat'
  depends_on :x11

  # fixes an incompatibility with recent GTK versions
  # patch from: http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=585155
  patch :DATA

  def install
    # Include Linuxbrew include path where to search for X11
    system "sed -i -e 's#ac_x_header_dirs=\'.*#ac_x_header_dirs=\'#{prefix}/include#' ./configure"

    system "./configure", "--disable-debug", "--disable-dependency-tracking",
                          "--prefix=#{prefix}"
    system "make install"
    if OS.linux?
      system "sed -i -e 's# -L/usr/lib64 ##g' #{prefix}/lib/pkgconfig/gdkglext-x11-1.0.pc"
      system "sed -i -e 's# -L/usr/lib64 ##g' #{prefix}/lib/pkgconfig/gdkglext-1.0.pc"
    end
  end
end

__END__
diff --git a/examples/pixmap-mixed.c b/examples/pixmap-mixed.c
index 2346afd..3e53f14 100644
--- a/examples/pixmap-mixed.c
+++ b/examples/pixmap-mixed.c
@@ -154,7 +154,7 @@ expose_event (GtkWidget      *widget,
               gpointer        data)
 {
   gdk_draw_drawable (widget->window,
-		     widget->style->fg_gc[GTK_WIDGET_STATE (widget)],
+		     widget->style->fg_gc[gtk_widget_get_state (widget)],
 		     pixmap,
 		     event->area.x, event->area.y,
 		     event->area.x, event->area.y,
diff --git a/examples/pixmap.c b/examples/pixmap.c
index 10e6fc1..a14a1b7 100644
--- a/examples/pixmap.c
+++ b/examples/pixmap.c
@@ -137,7 +137,7 @@ expose_event (GtkWidget      *widget,
               gpointer        data)
 {
   gdk_draw_drawable (widget->window,
-		     widget->style->fg_gc[GTK_WIDGET_STATE (widget)],
+		     widget->style->fg_gc[gtk_widget_get_state (widget)],
 		     pixmap,
 		     event->area.x, event->area.y,
 		     event->area.x, event->area.y,
diff --git a/gtk/gtkglwidget.c b/gtk/gtkglwidget.c
index 76a93d6..ca60626 100644
--- a/gtk/gtkglwidget.c
+++ b/gtk/gtkglwidget.c
@@ -129,7 +129,7 @@ gtk_gl_widget_size_allocate (GtkWidget       *widget,
    * Synchronize OpenGL and window resizing request streams.
    */
 
-  if (GTK_WIDGET_REALIZED (widget) && private->is_realized)
+  if (gtk_widget_get_realized (widget) && private->is_realized)
     {
       gldrawable = gdk_window_get_gl_drawable (widget->window);
       gdk_gl_drawable_wait_gdk (gldrawable);
@@ -156,7 +156,7 @@ gtk_gl_widget_unrealize (GtkWidget       *widget,
    * Remove OpenGL-capability from widget->window.
    */
 
-  if (GTK_WIDGET_REALIZED (widget))
+  if (gtk_widget_get_realized (widget))
     gdk_window_unset_gl_capability (widget->window);
 
   private->is_realized = FALSE;
@@ -176,7 +176,7 @@ gtk_gl_widget_parent_set (GtkWidget   *widget,
    */
 
   toplevel = gtk_widget_get_toplevel (widget);
-  if (GTK_WIDGET_TOPLEVEL (toplevel) && !GTK_WIDGET_REALIZED (toplevel))
+  if (gtk_widget_is_toplevel (toplevel) && !gtk_widget_get_realized (toplevel))
     {
       GTK_GL_NOTE (MISC,
         g_message (" - Install colormap to the top-level window."));
@@ -196,7 +196,7 @@ gtk_gl_widget_style_set (GtkWidget *widget,
    * Set a background of "None" on window to avoid AIX X server crash.
    */
 
-  if (GTK_WIDGET_REALIZED (widget))
+  if (gtk_widget_get_realized (widget))
     {
       GTK_GL_NOTE (MISC,
         g_message (" - window->bg_pixmap = %p",
@@ -252,8 +252,8 @@ gtk_widget_set_gl_capability (GtkWidget    *widget,
   GTK_GL_NOTE_FUNC ();
 
   g_return_val_if_fail (GTK_IS_WIDGET (widget), FALSE);
-  g_return_val_if_fail (!GTK_WIDGET_NO_WINDOW (widget), FALSE);
-  g_return_val_if_fail (!GTK_WIDGET_REALIZED (widget), FALSE);
+  g_return_val_if_fail (gtk_widget_get_has_window (widget), FALSE);
+  g_return_val_if_fail (!gtk_widget_get_realized (widget), FALSE);
   g_return_val_if_fail (GDK_IS_GL_CONFIG (glconfig), FALSE);
 
   /* 
@@ -434,7 +434,7 @@ gtk_widget_create_gl_context (GtkWidget    *widget,
   GTK_GL_NOTE_FUNC ();
 
   g_return_val_if_fail (GTK_IS_WIDGET (widget), NULL);
-  g_return_val_if_fail (GTK_WIDGET_REALIZED (widget), NULL);
+  g_return_val_if_fail (gtk_widget_get_realized (widget), NULL);
 
   gldrawable = gdk_window_get_gl_drawable (widget->window);
   if (gldrawable == NULL)
@@ -476,7 +476,7 @@ gtk_widget_get_gl_context (GtkWidget *widget)
   GLWidgetPrivate *private;

   g_return_val_if_fail (GTK_IS_WIDGET (widget), NULL);
-  g_return_val_if_fail (GTK_WIDGET_REALIZED (widget), NULL);
+  g_return_val_if_fail (gtk_widget_get_realized (widget), NULL);
 
   private = g_object_get_qdata (G_OBJECT (widget), quark_gl_private);
   if (private == NULL)
@@ -503,7 +503,7 @@ GdkGLWindow *
 gtk_widget_get_gl_window (GtkWidget *widget)
 {
   g_return_val_if_fail (GTK_IS_WIDGET (widget), NULL);
-  g_return_val_if_fail (GTK_WIDGET_REALIZED (widget), NULL);
+  g_return_val_if_fail (gtk_widget_get_realized (widget), NULL);
 
   return gdk_window_get_gl_window (widget->window);
 }

