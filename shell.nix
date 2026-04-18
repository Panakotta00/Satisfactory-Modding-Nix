let
	# Got to pin wine packages to specific nixpkgs version which compiled wine 10.3 (staging)
	pkgs_wine = import (fetchTarball { url = "https://github.com/NixOS/nixpkgs/archive/dd613136ee91f67e5dba3f3f41ac99ae89c5406b.tar.gz"; }) {};
	pkgs = import <nixpkgs>{ overlays = [
		(self: super: {
			wine64 = pkgs_wine.wineWow64Packages.staging;
			wine = pkgs_wine.wineWow64Packages.staging;
			wineWow64Packages = pkgs_wine.wineWow64Packages;
		})];};

	msvc = pkgs.callPackage ./msvc.nix {};

	# Should be changed to Fork-Parent repo, once PR got accepted (or maybe even normal nixpkgs)
	wwise-cli = pkgs.callPackage (fetchTarball { url = "https://github.com/Panakotta00/wwise-cli/archive/master.tar.gz"; }) {};

	nix-ld-lib-path = pkgs.lib.makeLibraryPath (with pkgs; [ libgbm dbus.lib dbus dbus.dev ]);

	fhs = pkgs.buildFHSEnv {
		name = "ue-shell-fhs";
		targetPkgs = pkgs: (with pkgs; [
			bash
		]);
	};

	unreal-build = pkgs.writeShellScriptBin "UnrealBuild" "/home/yannic/SF-Modding/UnrealEngine/Engine/Build/BatchFiles/Linux/Build.sh $@";
in pkgs.mkShell {	
	buildInputs = with pkgs; [
		msvc

		wwise-cli
		unreal-build

		git
		clang
		lld
		pkg-config
		openssl
		dbus.dev
		dbus.lib
		libgbm
		libsForQt5.qt5.qttools
		dotnet-sdk_6
		dos2unix
		msitools
		zstd
		dos2unix
		python3
		clang.cc
		lld
		cacert
		perl
		stdenv.cc.cc.lib
		wineWow64Packages.stagingFull
		cmake
	];
	packages = [ msvc fhs ];
	
	shellHook = ''
		export DOTNET_ROOT="${pkgs.dotnet-sdk_6}/share/dotnet";
		export NIX_LD_LIBRARY_PATH=${nix-ld-lib-path}:$NIX_LD_LIBRARY_PATH
		export LD_LIBRARY_PATH=${pkgs.dbus.lib}/lib:${pkgs.dbus}/lib:${pkgs.dbus.dev}/lib:$LD_LIBRARY_PATH
		export LDFLAGS="-L${pkgs.dbus.lib}/lib -L${pkgs.dbus.dev}/lib"
		export LD_FLAGS=$LDFLAGS
		export UE_WINE_MSVC=${msvc}/opt/msvc
		export VCTargetsPath=$UE_WINE_MSVC/MSBuild/Microsoft/VC/v170
	'';
}
