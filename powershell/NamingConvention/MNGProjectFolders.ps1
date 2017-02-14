[cmdletbinding()]

Param
(
    [Parameter(Mandatory=$true)]
    [string]$Client,
    [Parameter(Mandatory=$true)]
    [string]$Brand,
    [Parameter(Mandatory=$false)]
    [ValidateRange(2017,2022)]
    [int32]$Year=(get-date).Year,
    [Parameter(Mandatory=$true)]
    [string]$ProductCode,
    [Parameter(Mandatory=$True)]
    [ValidatePattern("^M\d{4,6}$")]
    [string]$MCode,
    [Parameter(Mandatory=$false)]
    [int]$Segment=0,
    [Parameter(Mandatory=$false)]
    [ValidatePattern("[A-Za-z]")]
    [string]$DriveLetter="M"
)

Process {
    Trap {
        $err = $_.Exception
        write-error $err.Message
        while ( $err.InnerException) {
            $err = $err.InnerException
            Write-Error $err.Message
        }
        break;
    }

    Set-PSDebug -Strict
    $ErrorActionPreference = "stop"

    $fullPathIncFileName = $MyInvocation.MyCommand.Definition
    $currentScriptName = $MyInvocation.MyCommand.Name
    $currentExecutingPath = $fullPathIncFileName.Replace($currentScriptName, "")

    ###############

    $YearCodeMapping = import-csv ".\YearCodeMapping.csv"
    $ProductCodes = import-csv ".\ProductCodes.csv"
    [xml]$DirectoryStructure = Get-Content ".\newdirstuct.xml"

    $BaseFolder = $DriveLetter, ($Client,$Brand,$Year -join "\") -join ":\"
    
    $AMFolder = $BaseFolder,"AccountManagement" -join "\"
    New-Item -ItemType Directory -Path $AMFolder -Force

    for ([int32]$count=0;$count -le $segment; $count++) {
        $yearCode = ($YearCodeMapping | Where-Object {$_.year -match $year}).code
        $count
        if ($Segment -gt 1) {
            $yearCode = $yearCode,($count+1) -join "_"
        }
        write-host $productcode
        $RequiredFolders = $ProductCodes | Where-Object {$_.Code -match ("^"+[regex]::Escape($ProductCode)+"$")}

        $ProjectCodeFolder = $MCode.ToUpper(),$Brand,$ProductCode.ToUpper(),$yearCode -join "_"

        $TeamFolders = $DirectoryStructure.SelectNodes("Client/Brand/Year/Project/Team")
        foreach ($team in $TeamFolders) {
            if ($RequiredFolders.($team.name) -eq "Y") {
                $team.folder | ForEach-Object {
                    $folder = $BaseFolder,$ProjectCodeFolder,$team.name,$_.name -join "\"
                    $folder
                    #$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                    New-Item -ItemType Directory -Path $folder -Force
                }
            }

        }
    }
}