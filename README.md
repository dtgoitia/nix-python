# Python development environment with nix

## What is this?

The bare minimum code needed to set up a Python environment using [nix flakes][2].

In this setup, the Python packages are not installed using [nix][1]. Instead, nix is only used to build the desired Python version, then this Python version is used to create a virtual environment, and inside the virtual environment you are free to install whatever you whish using `pip`.

In this case, nix is effectively replacing [pyenv][3], with the benefit that you could include non-Python packages (e.g.: `jq`) and pin their versions.

### Why not install Python packages directly with nix?

nix is capable of [directly installing Python packages][4] as well. However, at this point in my nix journey, I find the process too rigid for my taste.

## Usage

```shell
nix develop
python -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
```

### For the curious

#### What do the above instructions do?

The first line spawns a [nix shell][5]:

```shell
nix develop
```
The first time it takes a bit (~7min) to build. Bear in mind that this step is build your desired Python version from source. After the first run, the build is cached, so it takes ~1s to load.

At this point you are inside a nix shell, and the desired Python version should be available to you:

```shell
which python
# /nix/store/sxazgaidqcw9gzarla17qka6071vwgv0-python3-3.10.1-env/bin/python

python -V
# Python 3.10.1
```

You could be now tempted to use `pip` to install Python packages - after all, we have Python installed, right? Not quite. Try to find the version of `pip`:

```shell
pip -V
```

You will either (a) get an error saying `pip` command is not found, or (b) you had `pip` installed system-wide (outside this nix flake, that is). Use `which pip` to confirm.

Regardless of you observing (a) or (b), if you haven't modified `flake.nix`, `pip` should not have been installed with the nix flake alongside the Python you chose. This is desired. Why? You won't be able to install packages as usual if you install `pip` using the nix flake. See [_Can I install pip via nix flake?_](#can-i-install-pip-via-nix-flake) for a more detailed explanation.

How can you install Python packages then? From within the nix shell, create a Python virtual environment, and follow your preferred way of installing dependencies inside this Python virtual environment:

```shell
python -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
```

#### Can I install `pip` via nix flake?

Let's give it a go and see what happens, shall we?

1. Make sure you are not in any previous nix shell.
2. Edit `flake.nix` to include `pip` as a nix package of the `myPython` nix package.

    ```diff
          pkgs = import nixpkgs { inherit system; };
          myPython = nixpkgs-python.packages.${system}.${pythonVersion};
    +     myPythonWithPackages = myPython.withPackages (ps: with ps; [
    +       pip
    +     ]);
        in
        {
          devShells.${system}.default = pkgs.mkShell {
            buildInputs = [
    -         myPython
    +         myPythonWithPackages
            ];
            shellHook = ''
    ```

3. Rebuild and jump into the shell:

    ```shell
    nix develop
    ```

4. Confirm `pip` is installed via nix shell - must have the `/nix/store` prefix below with a different hash:
    ```shell
    which pip
    # /nix/store/sxazgaidqcw9gzarla17qka6071vwgv0-python3-3.10.1-env/bin/pip
    ```

5. Install any Python package using the `pip` installed via nix flake:

    ```shell
    pip install ipdb
    # Collecting ipdb
    # (...)
    # ERROR: Could not install packages due to an OSError: [Errno 13] Permission denied: '/nix/store/sxazgaidqcw9gzarla17qka6071vwgv0-python3-3.10.1-env/lib/python3.10/site-packages/wcwidth'
    # Check the permissions.
    ```

Ta-da! 🎉 In the nix world, you are not supposed to use `pip` directly to install Python packages. Instead, you wrap those Python packages to convert nix packages, and you install those wrapped nix packages. See [docs][4].

## Acknowledgement

Thank you [`nixpkgs-python`][6] for making it so accessible.

<!-- TOOD: specify Python version -->

<!-- External references -->

[1]: https://nix.dev/ "nix"
[2]: https://nix.dev/concepts/flakes.html "nix | flakes"
[3]: https://github.com/pyenv/pyenv "pyenv"
[4]: https://nixos.wiki/index.php?title=Python#Installation "NixOS Wiki | Python | Installation"
[5]: https://nix.dev/tutorials/first-steps/declarative-shell.html "nix | shell"
[6]: https://github.com/cachix/nixpkgs-python "nixpkgs-python"
