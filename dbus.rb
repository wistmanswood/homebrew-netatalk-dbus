class Dbus < Formula
  # releases: even (1.12.x) = stable, odd (1.13.x) = development
  desc "Message bus system, providing inter-application communication"
  homepage "https://wiki.freedesktop.org/www/Software/dbus"
  url "https://dbus.freedesktop.org/releases/dbus/dbus-1.15.12.tar.xz"
  sha256 "0589c9c707dd593e31f0709caefa5828e69c668c887a7c0d2e5ba445a86bae4d"
  license any_of: ["AFL-2.1", "GPL-2.0-or-later"]

  livecheck do
    url "https://dbus.freedesktop.org/releases/dbus/"
    regex(/href=.*?dbus[._-]v?(\d+\.\d*?[02468](?:\.\d+)*)\.t/i)
  end

  head do
    url "https://gitlab.freedesktop.org/dbus/dbus.git"  
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => :build

  depends_on "xmlto" => :build

  uses_from_macos "expat"

  # Patch applies the config templating fixed in https://bugs.freedesktop.org/show_bug.cgi?id=94494
  # Homebrew pr/issue: 50219
  patch do
    on_macos do
      url "https://raw.githubusercontent.com/Homebrew/formula-patches/0a8a55872e/d-bus/org.freedesktop.dbus-session.plist.osx.diff"
      sha256 "a8aa6fe3f2d8f873ad3f683013491f5362d551bf5d4c3b469f1efbc5459a20dc"
    end
  end

  def install
    # Fix the TMPDIR to one D-Bus doesn't reject due to odd symbols
    ENV["TMPDIR"] = "/tmp"
    ENV["XML_CATALOG_FILES"] = "#{etc}/xml/catalog"

    args = %w[
      -Ddbus_user=root
      -Dlaunchd=disabled
      -Ddoxygen_docs=disabled
      -Dlaunchd=disabled
      -Dxml_docs=enabled
      -Dx11_autolaunch=disabled
      -Dmodular_tests=disabled
    ]

    system "meson", "setup", "build", *args, *std_meson_args, "--localstatedir=#{var}", "--sysconfdir=#{etc}"
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
    system "mkdir", "-p", "#{etc}/dbus-1/system.d"
  end

  service do
    run [opt_bin/"dbus-daemon", "--nofork", "--system"]
    require_root true
    keep_alive true
    environment_variables PATH: std_service_path_env
  end

  def post_install
    # Fix 'no LC_RPATH's found' error
    system "install_name_tool", "-add_rpath", "#{lib}", bin/"dbus-daemon"
    # Generate D-Bus's UUID for this machine
    system bin/"dbus-uuidgen", "--ensure=#{var}/lib/dbus/machine-id"
  end

  test do
    system bin/"dbus-daemon", "--version"
  end
end
