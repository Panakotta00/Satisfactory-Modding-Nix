{
	stdenv,
	msitools,
	zstd,
	dos2unix,
	python3,
	wineWow64Packages,
	clang,
	lld,
	cacert,
	perl,
	autoPatchelfHook,
	rsync,

	msvc-wine-src ? builtins.fetchGit {
		url = "ssh://git@github.com/mircearoata/msvc-wine.git";
		ref = "ue-patches";
	},

	msvc-version ? "17.4",
	sdk-version ? "10.0.18362",
	msvc-channel ? "release.ltsc.17.4",
	msvc-hash ? "sha256-Lp/rMVDrEeNKMjZtjScvNthXwn8XVpgGMYgbsiITs+g=",
}: let
	msvc-wine-source = stdenv.mkDerivation {
		name = "Source of MSVC-Wine for Unreal Engine";

		src = msvc-wine-src;

		outputHashAlgo = "sha256";
		outputHash = msvc-hash;
		outputHashMode = "recursive";

		nativeBuildInputs = [
			msitools
			zstd
			dos2unix
			wineWow64Packages.staging
			python3
			clang.cc
			lld
			cacert
			perl
			stdenv.cc.cc.lib
		];

		buildPhase = ''
			patchShebangs .
			mkdir -p "$out/opt/msvc"
			./vsdownload.py --accept-license --dest "$out/opt/msvc" --msvc-version "${msvc-version}" --sdk-version "${sdk-version}" --channel "${msvc-channel}"
		'';
	};
in stdenv.mkDerivation {
	name = "MSVC-Wine for Unreal Engine";

	src = msvc-wine-src;

	nativeBuildInputs = [
		msitools
		zstd
		dos2unix
		wineWow64Packages.staging
		python3
		clang.cc
		lld
		cacert
		perl
		stdenv.cc.cc.lib
		msvc-wine-source
		autoPatchelfHook
		rsync
	];

	installPhase = ''
		HOME=$(pwd)
		patchShebangs .
		cp -rL ${msvc-wine-source}/opt/msvc .
		chmod 777 . -R
		sh -x ./install.sh "./msvc"
		patchShebangs ./msvc
		autoPatchelf ./msvc
		mkdir -p $out/opt
		rsync -l --safe-links -r ./msvc $out/opt
	'';
}

