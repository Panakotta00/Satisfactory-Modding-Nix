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
	writers,
	fetchurl,

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
			./vsdownload.py --accept-license --dest "$out/opt/msvc" --msvc-version "${msvc-version}" --sdk-version "${sdk-version}" --channel "${msvc-channel}" Microsoft.Net.4.8.SDK Microsoft.VisualStudio.MinShell
		'';
	};
	dbg-and-tools = fetchurl {
		url = "https://github.com/kbandla/installers/releases/latest/download/X64.Debuggers.And.Tools-x64_en-us.msi";
		sha256 = "0bd2yin9ppq7hk1565h4h43pqvp4na259j4lvjc6jajhchqakvg9";
	};
	wine-pdbcopy = writers.writeBash "pdbcopy" ''
. "$(dirname "$0")"/msvcenv.sh
SDKDEBUGBINDIR="$SDKBASE/Debuggers/x64"
"$(dirname "$0")"/wine-msvc.sh "$SDKDEBUGBINDIR/pdbcopy.exe" "$@"
'';
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
		find ./msvc -type f \( -iname "*.targets" -or -iname "*.props" \) -exec sed -Ei 's/([A-Za-z0-9_.]+)\.(Targets|Props)/\1.\L\2/g' {} \;
		find ./msvc -type f \( -iname "*.targets" -or -iname "*.props" \) -exec sed -Ei 's/Microsoft\.Build\.CppTasks\.Common\.dll/Microsoft.Build.CPPTasks.Common.dll/g' {} \;
		mkdir -p $out/opt
		rsync -l --safe-links -r ./msvc $out/opt
		msiextract -C $out/opt/msvc ${dbg-and-tools}
		cp ${wine-pdbcopy} $out/opt/msvc/bin/x64/pdbcopy
		cp ${wine-pdbcopy} $out/opt/msvc/bin/x64/pdbcopy.exe
	'';
}

