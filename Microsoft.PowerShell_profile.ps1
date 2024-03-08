Set-Alias -Name ll -Value dir
Set-Alias -Name which -Value Get-Command
Set-Alias -Name ss -Value Select-String

function Get-FolderSize {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$FolderPath
    )

    if (Test-Path $FolderPath) {
        $files = Get-ChildItem -Path $FolderPath -Recurse -File -ErrorAction SilentlyContinue
        $totalSize = ($files | Measure-Object -Property Length -Sum).Sum
        $formattedSize = [Math]::Round($totalSize / 1MB, 2)
        Write-Output "The total size of files in '$FolderPath' is $formattedSize MB"
    } else {
        Write-Error "The path '$FolderPath' does not exist."
    }
}


function Get-FolderSizeByExtension {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$FolderPath,

	    [Parameter(Position=1)]
        [string]$CsvFilePath
    )

    if (Test-Path $FolderPath) {

      $data = Get-ChildItem -Path $FolderPath -Recurse | 
        Where-Object {!$_.PSIsContainer} |
        Group-Object Extension |
        Select-Object Name, 
                      @{Name="FileCount";Expression={$_.Count}}, 
                      @{Name="TotalSizeMB";Expression={($_.Group | Measure-Object Length -Sum).Sum / 1MB}} |
        Sort-Object TotalSizeMB -Descending |
        Select-Object Name, FileCount, @{Name="TotalSizeMB";Expression={"{0:N2} MB" -f $_.TotalSizeMB}} 

      if ($CsvFilePath) {
        $data | Export-Csv -Path $CsvFilePath -NoTypeInformation
        Write-Host "Data exported to '$CsvFilePath'"
      } else {
        $data | Format-Table -AutoSize | Out-String | Write-Host
      }

    } else {
        Write-Error "The path '$FolderPath' does not exist."
    }
}

function Get-FilesByExtensionInDirectory {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$FolderPath,
		
	 [Parameter(Mandatory=$true, Position=1)]
	[string]$Extension,

        [Parameter(Position=2)]
        [string]$TxtFilePath
    )

    if (Test-Path $FolderPath) {

       $files = Get-ChildItem -Path $FolderPath -Recurse -Filter *.$Extension | Select-Object FullName, Length

        $totalCount = $files.Count
	$totalSizeKB = "{0:N2}" -f (($files | Measure-Object -Property Length -Sum).Sum / 1KB)

        $header = "size: $($totalSizeKB) KB,`r`files: $totalCount`r`n---"
        
        if ($TxtFilePath) {
            $header | Out-File $TxtFilePath
            $files | ForEach-Object { $_.FullName } | Add-Content -Path $TxtFilePath
            Write-Host "Data exported to '$TxtFilePath' with header"
        } else {
            Write-Host $header
            $files | ForEach-Object { Write-Host $_.FullName }
        }

    } else {
        Write-Error "The path '$FolderPath' does not exist."
    }
}
