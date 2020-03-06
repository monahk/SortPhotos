# SortPhotos
PowerShell script that sorts photos from multiple folders into a year/month/day folder structure. Dates are found using Photo Taken Date, Date in filename, Date in folder name or Last Modified date.

The move operation will not move files if a file with the same name already exist in a destination folder. You should use this script along with the Windows Explorer to move files with conflicting file names to reduce the duplicate photos. Windows will help you compare if the source and destination files have the same name, date and size, and therefore you can decide to safely overwrite the existing copies, thus eliminating duplicate copies.

Before running the scripts, edit the 5 settings in the top 11 lines:

o $sourcePath: Source path for folder containing photos. Example: 'C:\My Pictures'
o $targetPath: Destination path where the photos will be moved under. This folder will be created automatically 'C:\Sorted Pictures'
o $keepOriginalFolder: #If set to $true, keeps the files in a folder with the name of original folder name where the photos where before. If set to $false then it will be under a folder yyyy-mm-dd
$RealMode: #Set this to $false or any other value to do a test run and not move the files or create folders. Set it to "REAL" to move the photos. Be super careful with this setting. Test your changes prior to making this change. 
$MaxThreads: #number of concurrent move threads. Example: 10
     
DISCLAIMER: THIS SCRIPT WILL MOVE FILES FROM ONE LOCATION TO ANOTHER. IF CONFIGURED INCORRECTLY YOU COULD MOVE FILES THAT ARE NOT MEANT TO BE MOVED. BE VERY CAREFUL RUNNING THIS SCRIPT AT YOUR OWN1 RISK. YOU TAKE FULL RESPONSIBILITY FOR EXECUTING THIS SCRIPT. 

COMMENT LINE 178 IF YOU WANT TO TEST THE SCRIPT FIRST WITHOUT RISKING UNINTENTIONAL MOVE OF ANY FILES. 
