version := `cat VERSION`

# Install Emacs, ACPICA iASL, and the ASL mode.
install: (_install "false")

# Force reinstall Emacs and ACPICA iASL, then reinstall the ASL mode.
reinstall: (_install "true")

_install force:
    #!/usr/bin/env bash
    set -euo pipefail
    site_start_dir=/usr/share/emacs/site-lisp/site-start.d
    if [[ "$EUID" -eq 0 ]]; then
      root=()
    elif command -v sudo >/dev/null 2>&1; then
      root=(sudo)
    else
      echo "Run this recipe as root or install sudo." >&2
      exit 1
    fi
    if command -v apt-get >/dev/null 2>&1; then
      "${root[@]}" apt-get update
      if [[ "{{force}}" == "true" ]]; then
        "${root[@]}" apt-get install --reinstall -y emacs acpica-tools
      else
        "${root[@]}" apt-get install -y emacs acpica-tools
      fi
      site_start_dir=/etc/emacs/site-start.d
    elif command -v dnf >/dev/null 2>&1; then
      if [[ "{{force}}" == "true" ]]; then
        "${root[@]}" dnf reinstall -y emacs acpica-tools
      else
        "${root[@]}" dnf install -y emacs acpica-tools
      fi
    elif command -v yum >/dev/null 2>&1; then
      if [[ "{{force}}" == "true" ]]; then
        "${root[@]}" yum reinstall -y emacs acpica-tools
      else
        "${root[@]}" yum install -y emacs acpica-tools
      fi
    else
      echo "Supported package managers: apt-get, dnf, and yum." >&2
      exit 1
    fi
    mode_dir=/usr/share/emacs/site-lisp/asl-mode
    "${root[@]}" install -d "$mode_dir" "$site_start_dir"
    "${root[@]}" install -pm 0644 asl-mode.el "$mode_dir/asl-mode.el"
    "${root[@]}" install -pm 0644 packaging/asl-mode-init.el "$site_start_dir/50asl-mode.el"

# Build the Emacs Lisp tests.
test:
    emacs -Q --batch -L . -l test/asl-mode-test.el -f ert-run-tests-batch-and-exit

# Check byte-compilation without leaving build artifacts in the repository.
check:
    emacs -Q --batch -L . --eval '(progn (require (quote bytecomp)) (let ((byte-compile-dest-file-function (lambda (_) (expand-file-name "asl-mode.elc" temporary-file-directory)))) (byte-compile-file "asl-mode.el")))'

# Compile the self-contained example with ACPICA iASL.
compile-example:
    tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT; iasl -p "$tmp/simple-device" examples/simple-device.asl

# Build a Debian package in dist/.
deb:
    #!/usr/bin/env bash
    set -euo pipefail
    command -v dpkg-deb >/dev/null || { echo "dpkg-deb is required; install dpkg-dev (Debian or Ubuntu) or dpkg (Fedora)." >&2; exit 1; }
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    root="$tmp/root"
    mkdir -p "$root/DEBIAN" "$root/usr/share/emacs/site-lisp/asl-mode" "$root/etc/emacs/site-start.d" "$root/usr/share/doc/emacs-asl"
    sed 's/@VERSION@/{{version}}/' packaging/debian-control.in > "$root/DEBIAN/control"
    install -pm 0644 asl-mode.el "$root/usr/share/emacs/site-lisp/asl-mode/asl-mode.el"
    install -pm 0644 packaging/asl-mode-init.el "$root/etc/emacs/site-start.d/50asl-mode.el"
    install -pm 0644 README.md "$root/usr/share/doc/emacs-asl/README.md"
    install -pm 0644 LICENSE "$root/usr/share/doc/emacs-asl/copyright"
    mkdir -p dist
    dpkg-deb --build --root-owner-group "$root" "dist/emacs-asl_{{version}}_all.deb"

# Build a noarch RPM package in dist/.
rpm:
    #!/usr/bin/env bash
    set -euo pipefail
    command -v rpmbuild >/dev/null || { echo "rpmbuild is required; install rpm (Debian or Ubuntu) or rpm-build (Fedora)." >&2; exit 1; }
    tmp="$PWD/.build/rpm-{{version}}-$$"
    trap 'rm -rf "$tmp"' EXIT
    top="$tmp/rpmbuild"
    mkdir -p "$top/BUILD" "$top/BUILDROOT" "$top/RPMS" "$top/SOURCES" "$top/SPECS" "$top/SRPMS" "$top/TMP"
    tar -czf "$top/SOURCES/emacs-asl-{{version}}.tar.gz" --transform='s,^,emacs-asl-{{version}}/,' asl-mode.el LICENSE README.md packaging/asl-mode-init.el
    sed 's/@VERSION@/{{version}}/g' packaging/emacs-asl.spec.in > "$top/SPECS/emacs-asl.spec"
    rpmbuild -ba --define "_topdir $top" --define "_tmppath $top/TMP" "$top/SPECS/emacs-asl.spec"
    mkdir -p dist
    cp "$top"/RPMS/noarch/emacs-asl-*.noarch.rpm dist/

# Run tests, compile the sample, and byte-compile the mode.
all: test check compile-example
