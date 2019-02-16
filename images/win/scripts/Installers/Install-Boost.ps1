################################################################################
##  File:  Install-Boost.ps1
##  Team:  CI-Platform
##  Desc:  Install Boost
################################################################################

Import-Module -Name ImageHelpers -Force
function Install-BoostRelease
{
    Param
    (
        [String]$BoostRootDirectory,
        [String]$ReleaseVersion,
        [Switch]$AddToDefaultPath
    )

    $SourceUri = 'https://github.com/boostorg/boost.git'
    $VersionTag = $ReleaseVersion.Replace('.','_')
    $ReleaseDirectory = "$BoostRootDirectory\boost_$VersionTag"

    if (-not (Test-Path $BoostRootDirectory)) {
        $null = New-Item -ItemType Directory -Path $BoostRootDirectory -Force
    }

    Write-Host "Downloading Boost $ReleaseVersion..."
    git clone --recursive --branch "boost-$ReleaseVersion" $SourceUri $ReleaseDirectory --depth 1 -q *> $null

    # Check vswhere util
    $vswhere = (Get-Command vswhere -ErrorAction Ignore).Path
    if ( -not $vswhere ) {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        $vswhere = "$BoostRootDirectory\vswhere.exe"
        $vswhereApiUri = "https://api.github.com/repos/Microsoft/vswhere/releases/latest"
        $tag = (Invoke-RestMethod -Uri $vswhereApiUri)[0].tag_name
        $vswhereUri = "https://github.com/Microsoft/vswhere/releases/download/$tag/vswhere.exe"
        $null = Invoke-WebRequest -Uri $vswhereUri -OutFile $vswhere
    }

    # Import Visual Studio environment variables
    $installationPath = & $vswhere -prerelease -legacy -latest -property installationPath
    $batchFilePath = Join-Path $installationPath "Common7\Tools\vsdevcmd.bat"

    if (Test-Path $batchFilePath) {
        & "${env:COMSPEC}" /s /c "`"$batchFilePath`" -no_logo && set" | Where-Object {$_ -match "="} | Foreach-Object {
            $name, $value = $_ -split '=', 2
            Set-Content env:\"$name" $value
        }
    } 

    # VS 2015 - 14
    # VS 2017 - 15
    # VS 2019 - 16
    # msvc-14.0 - VS 2015
    # msvc-14.1 - VS 2017, 2019
    $installationVersion = & $vswhere -prerelease -legacy -latest -property installationVersion
    if ($installationVersion  -match "^1[56]") {
        Set-Content env:\"VS150COMNTOOLS" "$installationPath\Common7\Tools\"
        $toolset="msvc-14.1"
    }
    if ($installationVersion  -match "^14") {
        Set-Content env:\"VS140COMNTOOLS" "$installationPath\Common7\Tools\"
        $toolset="msvc-14.0"
    }

    # Building Boost
    Write-Host "Building Boost $ReleaseVersion release."
    Set-Location -Path $ReleaseDirectory
    Write-Host "Running bootstrap.bat"
    $null = & "$ReleaseDirectory\bootstrap.bat" msvc
    Write-Host "Running b2"
    $null = & "$ReleaseDirectory\b2" install variant="debug,release" link="static,shared" address-model="32,64" toolset="$toolset" --prefix="$ReleaseDirectory"
    Set-Location -Path $BoostRootDirectory

    # Make this the default version of Boost?
    if ($AddToDefaultPath)
    {
        Write-Host "Adding Boost $ReleaseVersion to the path..."
        # Add the Boost binaries to the path.
        Add-MachinePathItem $ReleaseDirectory | Out-Null
        # Set the BOOST_ROOT environment variable.
        setx BOOST_ROOT $ReleaseDirectory /M | Out-Null
    }
    
    # Cleaning boost folder
    if (Test-Path "$ReleaseDirectory\bin.v2") {
        Remove-Item -Path "$ReleaseDirectory\bin.v2" -Force -Recurse
    }

    # Cleaning vswhere.exe
    if (Test-Path "$ReleaseDirectory\vswhere.exe") {
        Remove-Item -Path "$ReleaseDirectory\vswhere.exe"
    }
    
    # Set environment BOOST_ROOT_X_XX_X
    $EnvBoostPath = "BOOST_ROOT_$VersionTag"
    setx $EnvBoostPath $ReleaseDirectory /M

    # Done
    Write-Host "Done installing Boost $ReleaseVersion."
}

# Root folder of all Boost releases
$BoostRootPath = 'C:\Program Files\Boost'

# Install Boost 1.66.x
Install-BoostRelease -BoostRootDirectory $BoostRootPath -ReleaseVersion '1.66.0'

# Install Boost 1.67.x
Install-BoostRelease -BoostRootDirectory $BoostRootPath -ReleaseVersion '1.67.0'

# Install Boost 1.68.x
Install-BoostRelease -BoostRootDirectory $BoostRootPath -ReleaseVersion '1.68.0'

# Install Boost 1.69.x
Install-BoostRelease -BoostRootDirectory $BoostRootPath -ReleaseVersion '1.69.0' -AddToDefaultPath

