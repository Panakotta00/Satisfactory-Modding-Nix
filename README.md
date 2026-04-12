# Satisfactory-Modding - Nix Setup

This repo contains a few Nix files helping to setup an Modding environment for Satisfactory.

Its not fully automated as there are two main private depencies: wwise & unreal engine,
and some personal difficulties nixifying the Unreal build process.

## Setup
0. Its preferred to use Direnv, so make sure it has been installed with nix.
1. Clone & open this repository:
   ```bash
   git clone https://github.com/Panakotta00/Satisfactory-Modding-Nix && cd Satisfactory-Modding-Nix
   ```
2. Allow the direnv to build the basic needed shell with dependencies.
   ```bash
   direnv allow
   ```
3. Setup Unreal Engine
   - By building the Unreal Engine from Source
     1. Clone the Unreal Engine Source Repository
        - Using a locally installed SSH Private Key with access to the repository
          ```bash
          git clone git@github.com:satisfactorymodding/UnrealEngine.git --depth=1 --branch 5.3.2-CSS-linux --single-branch
          ```
     2. Copy dbus library into Unreal Engine Source (idk why it is otherwise missing)
        ```bash
        cp $(pkg-config --variable=libdir dbus-1)/libdebus-1.so ./UnrealEngine/Engine/Source/ThirdParty/dbus/dbus-1.0/lib/Linux/
        ```
     3. Download & Setup Prerequisits of Unreal Engine
        ```
        bash -c "cd UnrealEngine && ./Setup.sh"
        ```
     4. Configure the Build Files
        ```bash
        bash -c "cd UnrealEngine && ./GenerateProjectFiles.sh
        ```
     5. Build the Engine (`-j1` is intended, actual build will still run in multiple parallel jobs)
        ```bash
        bash -c "cd UnrealEngine && make -j1
        ```
     6. Register the Engine (and for fix installation name)
        ```bash
        bash -c "cd UnrealEngine && .Engine/Binaries/Linux/UnrealVersionSelector-Linux-Shipping -register -unattended"
        echo "5.3.2-CSS=$(pwd)/UnrealEngine" >> ~/.config/Epic/UnrealEngine/Install.ini
        ```
4. Clone the Satisfactory-Mod-Loader repository (Saitsfactory Unreal Project Dummy)
   ```bash
   git clone https://github.com/SatisfactoryModding/SatisfactoryModLoader.git
   ```
5. Download the necessary wwise SDK version and integrate it, into the project. (not automated because requires credentials)
   ```bash
   wwise-cli download --sdk-version "2023.1.3.8471" --filter Packages=SDK --filter DeploymentPlatforms=Windows_vc160 --filter DeploymentPlatforms=Windows_vc170 --filter DeploymentPlatforms=Linux --filter DeploymentPlatforms=
   wwise-cli integrate-ue --integration-version "2023.1.3.2970" --project "$(pwd)/SatisfactoryModLoader/FactoryGame.uproject"
   ```
6. Genearte Project Files
   ```bash
   bash -c "cd SatisfactoryModLoader && ../UnrealEngine/Engine/Build/BatchFiles/Linux/Build.sh -projectfiles -project=$(pwd)/FactoryGame.uproject -game -makefile"
   ```
7. Build the Project
   ```bash
   make FactoryGameSteam-Win64-Shipping
   make FactoryGameEGS-Win64-Shipping
   ```
