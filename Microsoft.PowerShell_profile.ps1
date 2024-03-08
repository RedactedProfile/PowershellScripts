Set-Alias -Name ll -Value dir
Set-Alias -Name which -Value Get-Command
Set-Alias -Name ss -Value Select-String

<#
.SYNOPSIS
Calculates and displays the total size of a specified folder.

.DESCRIPTION
The Get-FolderSize function calculates the total size of all files within the specified folder, including files in its subfolders. It then displays the total size in megabytes (MB). This function is useful for quickly assessing the amount of disk space used by a folder and its contents.

.PARAMETER FolderPath
The path of the folder whose size will be calculated. This parameter is mandatory.

.EXAMPLE
Get-FolderSize -FolderPath "C:\Users\Example\Documents"

This command calculates and displays the total size of the Documents folder, including all subfolders and files, in megabytes.

.EXAMPLE
Get-FolderSize "C:\Users\Example\Pictures"

This example shows a shorter syntax for calling the function, assuming the FolderPath is the first positional parameter. It calculates and displays the total size of the Pictures folder.

.NOTES
The function provides a quick way to understand the size of folder contents, helping users manage storage and organize files more effectively. It can be particularly useful for identifying large folders that may need to be cleaned up or archived.

#>
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

<#
.SYNOPSIS
Calculates and displays the total size of files in a specified folder, broken down by file extension.

.DESCRIPTION
The Get-FolderSizeByExtension function analyzes a specified folder (including all subfolders) and calculates the total size of files grouped by their file extension. It outputs a list of file extensions found, the number of files for each extension, and the total size of files for each extension in megabytes. Optionally, the output can be exported to a CSV file for further analysis.

.PARAMETER FolderPath
The path to the folder that will be analyzed. This parameter is mandatory.

.PARAMETER CsvFilePath
An optional path to save the output of the function into a CSV file. If this parameter is not provided, the output will be displayed in the console.

.EXAMPLE
Get-FolderSizeByExtension -FolderPath "C:\Users\Example\Documents"

This command calculates and displays the total size of files in the Documents folder, grouped by file extension, in the console.

.EXAMPLE
Get-FolderSizeByExtension "C:\Users\Example\Documents" -CsvFilePath "C:\Users\Example\Documents\FolderSizes.csv"

This command calculates the total size of files in the Documents folder, grouped by file extension, and exports the results to a CSV file named FolderSizes.csv.

.NOTES
This function is useful for analyzing disk usage by file type within a folder structure. It can help identify which types of files are using the most disk space.

#>
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

<#
.SYNOPSIS
Searches a directory (and its subdirectories) for files with a specific extension and writes their paths to a text file or outputs them to the console.

.DESCRIPTION
The Get-FilesByExtensionInDirectory function recursively searches a specified folder for files with a given extension. It then either writes the absolute paths of these files to a text file, along with a header detailing the total size in KB and the number of files found, or outputs the paths to the console if no text file path is provided.

.PARAMETER FolderPath
The path of the directory to search in.

.PARAMETER Extension
The file extension to search for (do not include the dot).

.PARAMETER TxtFilePath
Optional. The full path to the text file where the list of file paths will be saved. If not provided, the function outputs the file paths to the console.

.EXAMPLE
Get-FilesByExtensionInDirectory -FolderPath "C:\Users\Example\Documents" -Extension "txt" -TxtFilePath "C:\output\filePaths.txt"
Searches for all .txt files within "C:\Users\Example\Documents" and its subdirectories, then writes their paths to "C:\output\filePaths.txt".

.EXAMPLE
Get-FilesByExtensionInDirectory -FolderPath "D:\Data" -Extension "jpg"
Searches for all .jpg files within "D:\Data" and its subdirectories, then outputs their paths to the console.

.NOTES
Be careful with the file paths and extensions you specify. The function will recursively search through all subdirectories of the provided folder path, which can take some time for directories with a large number of files or subdirectories.

.LINK
https://docs.microsoft.com/en-us/powershell/scripting/developer/cmdlet/get-help?view=powershell-7.1

#>
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


<#
.SYNOPSIS
Deletes files listed in a text file that has an absolute path to the file per line. It will automatically ignore lines that do not appear to be file paths. This is a companion function to Get-FilesByExtensionInDirectory which can generate the file this would read.

.DESCRIPTION
The Remove-FilesFromList function reads a text file line by line and deletes each file whose path is found in the text file. The function checks each line for a pattern that matches a typical file path before attempting deletion. It is designed for Windows-style paths.

.PARAMETER FilePath
The path to the text file containing the list of file paths to delete. Each line in the file should contain one file path.

.EXAMPLE
Remove-FilesFromList -FilePath "C:\path\to\filelist.txt"
This command reads each line from "filelist.txt" and attempts to delete the files listed, printing a message for each deletion.

.NOTES
Use this function with caution, as it will delete files without additional confirmation prompts. Ensure you have backups of important files before running this script.

.LINK
https://docs.microsoft.com/en-us/powershell/scripting/developer/cmdlet/get-help?view=powershell-7.1

#>
function Remove-FilesFromList {
    param(
        [Parameter(Mandatory=$true)]
        [string]$FilePath
    )
    
    if (Test-Path $FilePath) {
        $lines = Get-Content -Path $FilePath

        foreach ($line in $lines) {
            # Check if the line looks like it contains a file path. Adjust the condition as necessary.
            if ($line -match '^[A-Z]:\\') {
                try {
                    Remove-Item -Path $line -Force -ErrorAction Stop
                    Write-Host "Deleted: $line"
                } catch {
                    Write-Warning "Could not delete: $line. Error: $_"
                }
            }
        }
    } else {
        Write-Error "The file '$FilePath' does not exist."
    }
}
