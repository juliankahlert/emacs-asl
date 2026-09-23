# emacs-asl

`emacs-asl` provides `asl-mode`, an Emacs major mode for ACPI Source Language.
It highlights ASL declarations, methods, devices, operators, resource
descriptors, constants, namespace names, numbers, preprocessor directives,
comments, and strings. It also supports nested-block indentation, continued
argument alignment, comment commands, and Imenu navigation for methods, devices,
and scopes.

Emacs selects `asl-mode` for files with the `.asl`, `.dsl`, and `.asi`
extensions.

## Install

Clone the repository into a directory on your computer:

```sh
git clone https://github.com/juliankahlert/emacs-asl.git ~/.emacs.d/site-lisp/emacs-asl
```

Add the directory to your Emacs configuration file, usually `~/.emacs` or
`~/.emacs.d/init.el`:

```elisp
(add-to-list 'load-path "~/.emacs.d/site-lisp/emacs-asl")
(require 'asl-mode)
```

Restart Emacs or evaluate these forms in Emacs. Emacs then loads `asl-mode`
when you open an ASL file.

If you use `use-package`, add this configuration instead:

```elisp
(use-package asl-mode
  :load-path "~/.emacs.d/site-lisp/emacs-asl"
  :mode (("\\.asl\\'" . asl-mode)
         ("\\.dsl\\'" . asl-mode)
         ("\\.asi\\'" . asl-mode)))
```

## Use

Open an ASL file with `C-x C-f` (`M-x find-file`) and enter its path. Emacs
selects `asl-mode` based on the file extension. For example, opening
`examples/simple-device.asl` loads the mode and highlights the source.

To enable the mode in an already open buffer, run `M-x asl-mode`.

Use `TAB` to indent the current line. Nested blocks indent by four columns by
default; customize `asl-mode-indent-offset` to change the indentation step.
When Emacs' Electric Indent mode is enabled, pressing `RET` or typing a closing
brace also reindents the line automatically.

## Examples

[examples/simple-device.asl](examples/simple-device.asl) is a small ASL file
that compiles with ACPICA's `iasl` compiler.

[examples/upstream](examples/upstream) contains three ASL files from TianoCore's
`edk2-platforms` project. The files use platform headers, so they need the
original project environment to compile. Their source links and license details
are in [examples/upstream/README.md](examples/upstream/README.md).

## Install Emacs, iASL, and the mode

Run `just install` to install Emacs, ACPICA's `iasl` compiler, and `asl-mode`.
Run `just reinstall` to force reinstall Emacs and ACPICA's compiler, then
reinstall `asl-mode`.
The mode is installed system-wide and loaded automatically when Emacs starts;
restart any Emacs session that was already open during installation.
The target supports Debian and Ubuntu with `apt-get`, and Fedora and related
RPM systems with `dnf` or `yum`. It uses `sudo` when it runs as a regular user.
Install `just` separately before running this command.

## Build packages

Install the package builders before building: use `dpkg-dev` and `rpm` on
Debian or Ubuntu, or `dpkg` and `rpm-build` on Fedora. Then run these commands
to build installable packages in `dist/`:

```sh
just deb  # Build dist/emacs-asl_<version>_all.deb
just rpm  # Build a noarch RPM package
```

The Debian and RPM packages declare Emacs 26.1 or newer as a dependency. The
RPM also depends on `emacs-filesystem`. Install a package with your system
package manager. For example:

```sh
sudo apt install ./dist/emacs-asl_*_all.deb
sudo dnf install ./dist/emacs-asl-*.noarch.rpm
```

Both packages install a startup file that loads `asl-mode` automatically.

## Checks

The project uses `just` to run its checks:

```sh
just test             # Run the Emacs Lisp tests
just check            # Byte-compile asl-mode.el
just compile-example  # Compile the example with iasl
just all              # Run all three checks
```

`just all` requires Emacs and ACPICA's `iasl` compiler on `PATH`.

GitHub Actions runs these checks, builds the Debian and RPM packages, and stores
them as workflow artifacts.
