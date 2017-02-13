Get-ADComputer -Filter * | where {$_.name -match [regex]"(?i)(^.*(\-(wks$|lt$)))" } | select name | foreach {($_.name).tolower()} | Out-File \\mngdirect.com\install\BareOS\ConfigBackup\system_names.txt