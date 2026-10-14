# Maintainer: Suborno Das <suborno.das@remedio.co.in>
pkgname=system-watchdog
pkgver=1.1.0
pkgrel=1
pkgdesc="Lightweight, pluggable health-monitoring and auto-recovery daemon for Linux"
arch=('any')
url="https://github.com/suborno-das/system-watchdog"
license=('MIT')
depends=('bash' 'iproute2' 'iputils')
optdepends=(
    'networkmanager: For NetworkManager profile reconnection'
    'libnotify: For desktop notifications'
    'systemd: For user service management'
)
provides=('system-watchdog')
conflicts=('system-watchdog')
source=()

package() {
    install -d "$pkgdir/usr/bin"
    install -d "$pkgdir/usr/share/system-watchdog/checks"
    install -d "$pkgdir/usr/share/system-watchdog/actions"
    install -d "$pkgdir/usr/share/system-watchdog/templates"
    install -d "$pkgdir/usr/share/licenses/$pkgname"
    install -d "$pkgdir/usr/lib/systemd/user"
    install -d "$pkgdir/etc/xdg/autostart"

    # Install CLI
    install -m755 "$srcdir/bin/watchdog" "$pkgdir/usr/bin/watchdog"

    # Install Modules & Templates
    install -m755 "$srcdir"/checks/*.sh* "$pkgdir/usr/share/system-watchdog/checks/"
    install -m755 "$srcdir"/actions/*.sh* "$pkgdir/usr/share/system-watchdog/actions/"
    install -m755 "$srcdir"/templates/*.sh* "$pkgdir/usr/share/system-watchdog/templates/"
    install -m644 "$srcdir/config.conf.example" "$pkgdir/usr/share/system-watchdog/config.conf.example"

    # Install Systemd & Autostart
    install -m644 "$srcdir/systemd/system-watchdog.service" "$pkgdir/usr/lib/systemd/user/system-watchdog.service"
    install -m644 "$srcdir/autostart/system-watchdog.desktop" "$pkgdir/etc/xdg/autostart/system-watchdog.desktop"

    # Install License
    install -m644 "$srcdir/LICENSE" "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
}
