{
  description = "Python development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-python.url = "github:cachix/nixpkgs-python";
  };

  outputs = { self, nixpkgs, nixpkgs-python }: 
    let
      system = "x86_64-linux";
      # system = "x86_64-rwin";

      pythonVersion = "3.10.1";


      pkgs = import nixpkgs { inherit system; };
      myPython = nixpkgs-python.packages.${system}.${pythonVersion};
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [
          myPython
        ];
        shellHook = ''
          python --version
          exec fish
        '';
      };
    };
}
