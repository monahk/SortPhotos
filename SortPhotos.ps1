$sourcePath = 'X:\My Pictures\2016'
$targetPath = 'D:\New Pictures\2016-3'

#If set to true, keeps the files in a folder with the same original containing folder name . If set to false then it will be under a folder yyyy-mm-dd
$keepOriginalFolder = $true

#Set this to $false or any other value to do a test run and not move files or create folders. Set it to "REAL" to make actual changes
$RealMode = "REAL"

#number of concurrent move threads
$MaxThreads = 10
     
# Target Folder where files should be moved to. 
#The script will automatically create a folder in the format Year\Month\(Old folder Name from previous path)

 $ScriptBlock = 
 {  
     #accept the thread value
     param($thread, $files, $targetPath, $keepOriginalFolder, $MaxThreads, $RealMode) 
  
     function Get-DateFromName
     {
         param ($Name)
         
         $DateFromName = 'Empty'
         
         #match 199x, 200x, 201x, 202x dates in the format yyyyMMdd or yyyy-MM-dd
         $dateFormats = @("(\.*)(199\d\d\d\d\d)(\.*)", "(\.*)(200\d\d\d\d\d)(\.*)", "(\.*)(201\d\d\d\d\d)(\.*)", "(\.*)(202\d\d\d\d\d)(\.*)", "(\.*)(199\d-\d\d-\d\d)(\.*)", "(\.*)(200\d-\d\d-\d\d)(\.*)", "(\.*)(201\d-\d\d-\d\d)(\.*)", "(\.*)(202\d-\d\d-\d\d)(\.*)")
         
         $matchingFormat = 0
         foreach($format in $dateFormats)
         {
             $matchingFormat = $matchingFormat + 1
             If($Name -match $format ) 
             {
                 If($matchingFormat -le 4)
                 {
                     $DateFromName = [DateTime]::ParseExact($Matches.2,"yyyyMMdd", $null)                  
                 } Else 
                 {
                     $DateFromName = [DateTime]::ParseExact($Matches.2,"yyyy-MM-dd", $null)                  
                 }
                 
                 break
             }          
         }
         $DateFromName 
     }
         
     function Get-DateTaken
     {
       param 
       (
         [Parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
         [Alias('FullName')]
         [String]
         $Path
       )
  
       begin
       {
         $shell = New-Object -COMObject Shell.Application
       }
  
       process
       {
           $returnvalue = 1 | Select-Object -Property DateTaken
           $Name = Split-Path $path -Leaf
           $Folder = Split-Path $path
           $shellfolder = $shell.Namespace($Folder)
           $shellfile = $shellfolder.ParseName($Name)
           $DateTaken = $shellfolder.GetDetailsOf($shellfile, 12)   
      
           if ($DateTaken -eq '')
           {
               'Empty'
           }
           else
           {
               $DateTaken = $DateTaken -Replace([char]8206, '')
               $DateTaken = $DateTaken -Replace([char]0, '')
               $DateTaken = $DateTaken -Replace([char]8207, '')
           
               $returnvalue.DateTaken = $DateTaken
          
               [datetime]$returnvalue.DateTaken
           }
       }
     }
     
     foreach ($file in $files)
     {
         $sum = 0
         foreach($letter in $file.FullName.toCharArray())
         {
             $sum = $sum + [int16]$letter           
         }
         
         $mod = $sum % $MaxThreads 
      
         if($mod -ne $thread)
         {
             continue
         }
         
         #try using the DateTaken attribute first
         #if DateTaken is not available then use the file date/time
         # Get year and Month of the file
         # If failed, use the LastWriteTime   
         
         $DateTaken = Get-DateTaken $file.FullName  
         $DateFromFile = Get-DateFromName $file.Name
         $DatefromFolder = Get-DateFromName $file.Directory.Split('\')[-1]

         If($DateTaken -ne 'Empty')
         {
             $year = $DateTaken.Year
             $month= $DateTaken.Month
             $day = $DateTaken.Day

             Write-Host "Found a file with a Date Taken: " $file.FullName

         } ElseIf ($DateFromFile -ne 'Empty')
         {
             $year = $DateFromFile.Year
             $month= $DateFromFile.Month
             $day = $DateFromFile.Day

             Write-Host "Found a file with a Date in Name: " $file.FullName

         } ElseIf ($DateFromFolder -ne 'Empty')
         {
             $year = $DateFromFolder.Year
             $month= $DateFromFolder.Month
             $day = $DateFromFolder.Day

             Write-Host "Found a file with a Date in Folder Name: " $file.FullName

         } Else
         {
             $year = $file.LastWriteTime.Year
             $month = $file.LastWriteTime.Month
             $day = $file.LastWriteTime.Day
         }
         
         $month = "{0:D2}" -f ($month)
         $day = "{0:D2}" -f ($day)
         
         # Out FileName, year and month
         #$file.Name
         #$year
         #$month
         
         # Set Directory Path         
         If($keepOriginalFolder -eq $True)
         {
             $directory = $targetPath + "\" + $year + "\" + $month.ToString() + "\" + $file.DirectoryName.Split('\')[-1]
         } Else 
         {
             $directory = $targetPath + "\" + $year + "\" + $month.ToString() + "\" + $year + "-" + $month + "-" + $day
         }
         
         # Create directory if it doesn't exsist
         if (!(Test-Path $directory))
         {
             if($RealMode -eq "REAL")
             {
               #using $null to prevent this line for echoing to console
               $null = New-Item $directory -type directory
             }
         }
                 
         # Copy File to new location but do not overwrite existing file if exists
         # TODO: Do not use folder name if it's not a date or a string that has alphabetic characters
         # 
         if($RealMode -eq "REAL")
         {
             $file | Move-Item -Destination $Directory -Exclude (Get-ChildItem $Directory)    
         }
         Write-Host "Moved file: " $file.FullName " to " $Directory
     }
 }
 
 "Eumerating Files..."
 $files = Get-ChildItem $sourcePath -Recurse | where {!$_.PsIsContainer}
 "File Enumeration Complete"
   
 For ($thread=0; $thread -lt $MaxThreads; $thread++) 
 {   
     # pass the loop variable across the job-context barrier
     Start-Job $ScriptBlock -ArgumentList $thread, $files, $targetPath, $keepOriginalFolder, $MaxThreads, $RealMode 
 }

# Wait for all to complete and meanwhile update the output every 2 seconds
While (Get-Job -State "Running") 
{
    Get-Job | Receive-Job
    Start-Sleep 2 
}

# Display remaining output from jobs
Get-Job | Receive-Job

# Cleanup
Stop-Job *
Remove-Job *

