#!/usr/bin/env bash
##########################################################################
# This is the Fake bootstrapper script for Linux and OS X.
##########################################################################

# Define directories.
SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
TOOLS_DIR=$SCRIPT_DIR/tools
SIGNCLIENT_DIR=$TOOLS_DIR/signclient
NUGET_EXE=$TOOLS_DIR/nuget.exe
NUGET_URL=https://dist.nuget.org/win-x86-commandline/v5.8.0/nuget.exe
FAKE_VERSION=4.63.0
FAKE_EXE=$TOOLS_DIR/FAKE/tools/FAKE.exe
DOCFX_VERSION=2.59.4
DOCFX_EXE=$TOOLS_DIR/docfx.console/tools/docfx.exe

# Define default arguments.
TARGET="Default"
CONFIGURATION="Release"
VERBOSITY="verbose"
DRYRUN=
SCRIPT_ARGUMENTS=()

# Parse arguments.
for i in "$@"; do
    case $1 in
        -t|--target) TARGET="$2"; shift ;;
        -c|--configuration) CONFIGURATION="$2"; shift ;;
        -v|--verbosity) VERBOSITY="$2"; shift ;;
        -d|--dryrun) DRYRUN="-dryrun" ;;
        --) shift; SCRIPT_ARGUMENTS+=("$@"); break ;;
        *) SCRIPT_ARGUMENTS+=("$1") ;;
    esac
    shift
done

# Make sure the tools folder exist.
if [ ! -d "$TOOLS_DIR" ]; then
  mkdir "$TOOLS_DIR"
fi

###########################################################################
# INSTALL NUGET
###########################################################################

# Download NuGet if it does not exist.
if [ ! -f "$NUGET_EXE" ]; then
    echo "Downloading NuGet..."
    curl -Lsfo "$NUGET_EXE" $NUGET_URL
    if [ $? -ne 0 ]; then
        echo "An error occured while downloading nuget.exe."
        exit 1
    fi
fi

###########################################################################
# INSTALL FAKE
###########################################################################

if [ ! -f "$FAKE_EXE" ]; then
    mono "$NUGET_EXE" install Fake -ExcludeVersion -Version $FAKE_VERSION -OutputDirectory "$TOOLS_DIR"
    if [ $? -ne 0 ]; then
        echo "An error occured while installing Cake."
        exit 1
    fi
fi

# Make sure that Fake has been installed.
if [ ! -f "$FAKE_EXE" ]; then
    echo "Could not find Fake.exe at '$FAKE_EXE'."
    exit 1
fi

###########################################################################
# INSTALL DOCFX
###########################################################################
if [ ! -f "$DOCFX_EXE" ]; then
    mono "$NUGET_EXE" install docfx.console -ExcludeVersion -Version $DOCFX_VERSION -OutputDirectory "$TOOLS_DIR"
    if [ $? -ne 0 ]; then
        echo "An error occured while installing DocFx."
        exit 1
    fi
fi

# Make sure that DocFx has been installed.
if [ ! -f "$DOCFX_EXE" ]; then
    echo "Could not find docfx.exe at '$DOCFX_EXE'."
    exit 1
fi

###########################################################################
# INSTALL SignTool
###########################################################################
if [ ! -f "$SIGNTOOL_EXE" ]; then
    dotnet tool install SignClient --version 1.3.155 --tool-path "$SIGNCLIENT_DIR"
    if [ $? -ne 0 ]; then
        echo "SignClient already installed."
    fi
fi


###########################################################################
# WORKAROUND FOR MONO
###########################################################################
export FrameworkPathOverride=/usr/lib/mono/4.5/

###########################################################################
# RUN BUILD SCRIPT
###########################################################################

# Start Fake
exec mono "$FAKE_EXE" build.fsx "${SCRIPT_ARGUMENTS[@]}" --verbosity=$VERBOSITY --configuration=$CONFIGURATION --target=$TARGET $DRYRUN