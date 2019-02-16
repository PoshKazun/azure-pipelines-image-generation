################################################################################
##  File:  Validate-Go.ps1
##  Team:  CI-X
##  Desc:  Validate Go
################################################################################

# Function that gets the version of Go at the specified path
function Get-GoVersion
{
    Param
    (
        [String]$goRootPath
    )

    $env:Path = "$goRootPath\bin;" + $env:Path
    if( $(go version) -match 'go version go(?<version>.*) win.*' )
    {
        $goVersion = $Matches.version
        return $goVersion
    }

    Write-Host "Unable to determine Go version at " + $goRootPath
    exit 1
}

# Verify that go.exe is on the path
if(Get-Command -Name 'go')
{
    Write-Host "$(go version) is on the path."
}
else
{
    Write-Host "Go is not on the path."
    exit 1
}

# Get available versions of Go
$goVersion1_9 = Get-GoVersion -goRootPath "C:\Go1.9.7"
$goVersion1_10 = Get-GoVersion -goRootPath "C:\Go1.10.8"
$goVersionOnPath = Get-GoVersion -goRootPath "C:\Go1.11.5"

# Add details of available versions in Markdown
$SoftwareName = "Go (x64)"
$Description = @"
#### $goVersion1_9

_Environment:_
* GOROOT_1_9_X64: root directory of the Go $goVersion1_9 installation

#### $goVersion1_10
* GOROOT_1_10_X64: root directory of the Go $goVersion1_10 installation

#### $goVersionOnPath

_Environment:_
* PATH: contains the location of go.exe version $goVersionOnPath
* GOROOT: root directory of the Go $goVersionOnPath installation
* GOROOT_1_11_X64: root directory of the Go $goVersionOnPath installation
"@

Add-SoftwareDetailsToMarkdown -SoftwareName $SoftwareName -DescriptionMarkdown $Description
