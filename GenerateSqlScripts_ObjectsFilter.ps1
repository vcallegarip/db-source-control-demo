### THIS POWERSHELL FILE PROVIDES A CONSISTENT METHOD TO SCRIPT DATABASES FOR GIT SOURCE CONTROL
### 2023 COPYRIGHT INTERJECT DATA SYSTEMS. ALL RIGHTS RESERVED.

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
#  S  E  T  U  P
#  YOU MAY NEED TO ENABLE LOCAL POWERSHELL SCRIPTS 
#  NOTE:  In order to run Powershell scripts, you need to enable them... There is a security vulnerability if web-based scripts are downloaded and executed
#  ... if you see... MyFileName.ps1 cannot be loaded because running scripts is disabled on this system. For more information, see about_Execution_Policies at http://go.microsoft.com/fwlink/?LinkID=135170.
#  ... Setting RemoteSigned for CurrentUser allows local files and remote signed files and normally this is run
#  ... locally.  By default each policy is undefined.
#  ...
#  ... search for PowerShell, R-Click, Run As Administrator
#  ...           Get-ExecutionPolicy -List  
#  ...           set-executionpolicy -scope CurrentUser -executionPolicy RemoteSigned  -- only needed if not already RemotedSigned
#
#  ...           To restrict again afterwards
#  ...           Get-ExecutionPolicy -List
#  ...           set-executionpolicy -scope CurrentUser -executionPolicy Restricted
#
#            1) Find "Windows PowerShell ISE" as a program
#            2) Run as administrator
#            3) Run from a new window, not a saved file.... file based scripts are considered dangerous, so they can't run in some configurations
#
#  NOTE: For downloaded files, the file explorer may need to be used to change the file property.
#  See https://chribonn.medium.com/understanding-powershells-executionpolicy-and-scope-functionality-unblock-file-approach-fcfbdd9be2bf
#
#
#  YOU MAY NEED TO INSTALL THE SQL SERVER MODULE THAT IS USED IN THIS SCRIPT
#  NOTE:  This requires a SQL Server module (https://www.powershellgallery.com/packages/Sqlserver/)
#  See https://learn.microsoft.com/en-us/sql/powershell/download-sql-server-ps-module?view=sql-server-ver15
#
#  You may need to update the shell. See https://learn.microsoft.com/en-us/powershell/gallery/powershellget/install-powershellget
#  ...  Import-Module PowerShellGet 
#
#  ...  Install-Module -Name SqlServer  -- try this next, you may be asked to trust it
#           or you may have to use below to update/overwrite existing SqlServer module
#  ...  Install-Module -Name SqlServer -AllowClobber  
#
#  NOTE: Nuget may be required, but may also be outdated
#  Run the below in Powershell with Admin privleges, more info here https://stackoverflow.com/questions/51406685/powershell-how-do-i-install-the-nuget-provider-for-powershell-on-a-unconnected
#  ... Powershell Cmd: [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
#  ... Powershell Cmd: Install-PackageProvider -Name NuGet
#
#
#  HOW TO CHECK YOUR VERSION OF POWERSHELL (FYI only)
#  # To see what version of powershell you have, run this line:
#  $PSVersionTable.PSVersion
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# G  I  T
# GIT RECOMMENDATIONS/REMINDERS
# -) Install git https://git-scm.com/book/en/v2/Getting-Started-Installing-Git
# -) Clone repo  https://git-scm.com/book/en/v2/Git-Basics-Getting-a-Git-Repository
# -) git config --global user.email "name@gointerject.com"
# -) git config --global user.name "First Name Last Name"
# -) Use this script out the database.
# 
# In a shared database Git Repo, create a branch off of the Staging Branch with the following naming convection:
# Branch Naming Convection:
# Ticket#-Ticket-Description-FirstName-LastName
# 
# -) Push branches to remote
# -) Assign code reviewers in GitHub
# -) Once code review is approved and branch is deployed, delete the branch on merge into Master branch
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# E  X  A  M  P  L  E  S 
# HOW TO EXECUTE THIS SCRIPT
# call this script by running command prompt as administrator
# Use one of these example commands. Command arguments are separated by spaces and kept on a single line
#
#     powershell.exe -File 
#           "[Full-Path-To-This-Powershell-Script]"   # this  -- powershell path and file
#           "Server-Name"                             # arg 1
#           "Database-Name"                           # arg 2
#           "Database-Folder-Name"                    # arg 3 -- leave blank to equal database name
#           "[Path-To-Final-File-Location]            # arg 4
#           True/False                                # arg 5 -- DELETE ROOT FOLDER before scripting
#           True/False                                # arg 6 -- UseSchemaBasedFolderStructure
#           True/False                                # arg 7 -- SquareBracketFileNames
#           "SqlServer-Username"                      # arg 8
#           "SqlServer-Password"                      # arg 9
#           True/False                                # arg 10 -- ObjectSearchEnabled. Uses folder to facilitate which to script using file ".\PowershellScripts\ScriptOutDatabase_ObjectList.txt"
#           "View,Table"                              # arg 11 -- Specify specific object types to script options are ("StoredProcedure,View,Table,Role,Rule,Schema,UserDefinedFunction,User"). Blank = all types
#           True/False                                # arg 12 -- LoggingEnabled
#           "[Modified Date]"                         # arg 13 -- ModifiedDate. You can use the last Modified date to script only the objects that changed since the last modified date.
#  
#
#.......this is STANDARD to use for GIT
#       -- Root folder is deleted
#       -- Schema folders are not used
#       -- Square brackets are placed in file names
#
#       powershell.exe -File "D:\Powershell_Scripts\GenerateSqlScripts_v2.ps1" ".\SQLEXPRESS" "Sandbox" null "D:\Temp" true false true
#
#       FOR PMX: powershell.exe -File "C:\Users\jeffh\OneDrive\Documents\SQLServer\GenerateSqlScripts_v2.ps1" "." "TSC" "TSCFolder" "C:\Users\jeffh\OneDrive\Documents\SQLServer\ExportFolder1" true false true
#
#       FOR PMX with schema search: powershell.exe -File "C:\Users\jeffh\OneDrive\Documents\SQLServer\GenerateSqlScripts_v2.ps1" "." "TSC" "TSCFolder" "C:\Users\jeffh\OneDrive\Documents\SQLServer\ExportFolder1" true false true
#
#.......minimal use 
#       powershell.exe -File "D:\Powershell_Scripts\GenerateSqlScripts_v2.ps1" ".\SQLEXPRESS" "Sandbox" null "D:\Temp"    
#
#.......Change the parent folder to deviate from the database name. Used when dev/test/prod are separate databases that are combined into one repo
#       powershell.exe -File "D:\Powershell_Scripts\GenerateSqlScripts_v2.ps1" ".\SQLEXPRESS" "Sandbox-test" "Sandbox" "D:\Temp"    
#
#.......delete the root folder before scripting database
#       powershell.exe -File "D:\Powershell_Scripts\GenerateSqlScripts_v2.ps1" ".\SQLEXPRESS" "Sandbox" null "D:\Temp" true   
#
#.......store files by schema, then type, (not just type)
#       powershell.exe -File "D:\Powershell_Scripts\GenerateSqlScripts_v2.ps1" ".\SQLEXPRESS" "Sandbox" null "D:\Temp" false true   
#
#.......store files by object type, (ignore Schema in folder structure)
#       powershell.exe -File "D:\Powershell_Scripts\GenerateSqlScripts_v2.ps1" ".\SQLEXPRESS" "Sandbox" null "D:\Temp" false false   
#
#.......specifically use square brackets in file names
#       powershell.exe -File "D:\Powershell_Scripts\GenerateSqlScripts_v2.ps1" ".\SQLEXPRESS" "Sandbox" null "D:\Temp" false false true   
#
#.......specifically remove square brackets in file names
#       powershell.exe -File "D:\Powershell_Scripts\GenerateSqlScripts_v2.ps1" ".\SQLEXPRESS" "Sandbox" null "D:\Temp" false false false   
#
#.......use SQL Server Authentication (eg. to Azure in this example)
#       powershell.exe -File "D:\Users\IgorT_Interject\Desktop\PowershellDBToolsGui\PoShDbToolGUI\bin\Release\PowershellScripts\GenerateSqlScripts_v2.ps1" "pps-database-2.c82k4xpawjbr.us-west-2.rds.amazonaws.com" "270PI_v2" null "D:\Users\IgorT_Interject\Desktop\SQL DB Script\270PI_v2_Powershell" false false true "PPSBOT_Interject" "2zpKDkrg7C2X2XJ2"   

#==========================================================================
#====== Code Step 1 of 6... pull the command arguments from when this script was called, and log them in the output
#==========================================================================

#
# Loads the SQL Server Management Objects (SMO)  
#

# Wire up input parameters to this Powershell Script
param($Argument1,$Argument2,$Argument3,$Argument4,$Argument5,$Argument6,$Argument7,$Argument8,$Argument9,$Argument10,$Argument11,$Argument12,$Argument13,$DropCreate)

# Import-Module -Name SqlServer

function AddToLog($logText) {
    if ($LoggingEnabled -eq "True") {
	    add-content -Path $file -Value $logText
    }

    $logText
}

 "Argument1  " + $Argument1 
 "Argument2  " + $Argument2 
 "Argument3  " + $Argument3 
 "Argument4  " + $Argument4 
 "Argument5  " + $Argument5 
 "Argument6  " + $Argument6 
 "Argument7  " + $Argument7 
 "Argument8  " + $Argument8 
 "Argument9  **********" 
 "Argument10 " + $Argument10
 "Argument11 " + $Argument11
 "Argument12 " + $Argument12 
 "Argument13 " + $Argument13 #if date, will only script out objects on this date and after
 "DropCreate " + $DropCreate


#check if date if not then don't use
$Argument13 = $Argument13 -as [DateTime];
if (!$Argument13)
{  
    $Argument13 = $null;
}

$ObjectArray = @()
$ObjectArray = $Argument11 -split "," | Where-Object {$_}

$StoredProcedure      = $False
$View                 = $False
$Table                = $False
$Role                 = $False
$Rule                 = $False
$Schema               = $False
$UserDefinedFunction  = $False
$User                 = $False

if ($ObjectArray.count -eq 0) 
{
    $StoredProcedure      = $True
    $View                 = $True
    $Table                = $True
    $Role                 = $True
    $Rule                 = $True
    $Schema               = $True
    $UserDefinedFunction  = $True
    $User                 = $True
}

foreach ($Object in $ObjectArray) {

    $Object = $Object.replace(" ","")

    if($Object -eq "StoredProcedure") {$StoredProcedure = $True}
    if($Object -eq "View") {$View = $True}
    if($Object -eq "Table") {$Table = $True}
    if($Object -eq "Role") {$Role = $True}
    if($Object -eq "Rule") {$Rule = $True}
    if($Object -eq "Schema") {$Schema = $True}
    if($Object -eq "UserDefinedFunction") {$UserDefinedFunction = $True}
    if($Object -eq "User") {$User = $True}
}

"StoredProcedure: $StoredProcedure"
"View: $View"
"Table: $Table"
"Role: $Role"
"Rule: $Rule"
"Schema: $Schema"
"UserDefinedFunction: $UserDefinedFunction"
"User: $User"

if($Argument1 -eq $null){$Argument1 = ""} # server
if($Argument2 -eq $null){$Argument2 = ""} # dbname
if($Argument3 -eq $null){$Argument3 = ""} # db folder name
if($Argument4 -eq $null){$Argument4 = ""} # FileLocation
if(!($Argument4.EndsWith("\"))) { $Argument4 = $Argument4 + "\"}# Make sure there's a trailing backslash, used later in the file name.
if($Argument5 -eq $null){$Argument5 = "False"} #DELETE ROOT FOLDER... Should the root folder be completely deleted before scipting?
if($Argument6 -eq $null){$Argument6 = "False"} #UseSchemaFolders... Store items based on Schema then Type... root/dbo/Table   root/dbo/View
if($Argument7 -eq $null){$Argument7 = "False"} #Use Square Brackets In File Names ? (default is false, as before)
if($Argument8 -eq $null){$Argument8 = ""} # Username
if($Argument9 -eq $null){$Argument9 = ""} # Password

$server              = $Argument1
$dbname              = $Argument2
$dbfoldername        = $Argument3 
if($dbfoldername -eq ""){$dbfoldername = $dbname}
$FileLocation        = $Argument4
$DeleteRootFolder    = ($Argument5 -eq "True")
$UseSchemaFolders    = ($Argument6 -eq "True")
$UseSquareBrackets   = ($Argument7 -eq "True")
$username            = $Argument8
$password            = $Argument9
$ObjectSearchEnabled = $Argument10
$LoggingEnabled      = $Argument12
$ModifiedDate        = $Argument13

"Modified Date:"+$ModifiedDate
"dbfoldername: "+$dbfoldername

#Check if File Output Location exists else create
if (!(Test-Path $FileLocation)) {
    [void](new-item $FileLocation -itemType directory)
}

if($LoggingEnabled -eq "True")
{
    "LoggingEnabled: $LoggingEnabled"
    #check if output file path exists
    $LogFolderPath = $FileLocation + "\ScriptOutLogs"

    if (!(Test-Path $LogFolderPath)) {
		[void](new-item $LogFolderPath -itemType directory)
	}

    $date = (get-date).ToString('yyyy.MM.dd_HH.mm.ss')
	$dateToDisplay = (get-date).ToString('MM/dd/yyyy HH:mm:ss')

	$file = "$LogFolderPath\ScriptOutLog_$dbname_$date.txt"

    if(!(Test-Path -Path $file)){
		[void](New-Item -type file $file)
	}

    AddToLog ""
    AddToLog "----SQL SCRIPT EXECUTED ON: $dateToDisplay ------"
	AddToLog ""
}

AddToLog ""
AddToLog "Instance is $server" #                 server
AddToLog "Database is $dbname" #                 dbname
AddToLog "Output Location is $FileLocation" #    FileLocation
AddToLog "" 

#==========================================================================
#====== Code Step 2 of 6... Resolve Connection to Database and SMO object
#==========================================================================

$isAzure = ($server.Contains(".database.windows.net"))# This would be an AZURE database
if($isAzure -eq $true){"This is an Azure db."}

#Add a reference to the SQL SDK API 
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | out-null

#Get the server itself
if(($username.Length -gt 0) -and ($password.Length -gt 0))
{
    
    AddToLog "Using Connection String to connect to Database..."

    $TrustedConnectionSegment =""
    if($isAzure) 
    {
        $TrustedConnectionSegment = "Trusted_Connection=False;"
    }
    $connection = New-Object System.Data.SqlClient.SqlConnection
	$connection.ConnectionString = "Server=$server;  Database=$dbname;  User ID=$username;  Password=$password;  $TrustedConnectionSegment  Connection Timeout=30;"

    $SMOserver = New-Object ("Microsoft.SqlServer.Management.Smo.Server") $connection
}
else
{
    AddToLog "Using Windows Login to connect to Database..."
    #Uses Windows Credentials
    $SMOserver = New-Object ("Microsoft.SqlServer.Management.Smo.Server") -argumentlist $server
}

# original default used Windows Login....  $SMOserver = New-Object ('Microsoft.SqlServer.Management.Smo.Server') -argumentlist $server
if($SMOserver.InstanceName -eq $null)
{
    AddToLog "No SQL server was found with the name '$server'"
    return
}

AddToLog "Successfully opened server $server'"

#Get the database on the server
$db = $SMOserver.databases[$dbname]
if($db -eq $null)
{
    AddToLog "No database was found on the server with the name '$dbname'"
    return
}

AddToLog "Successfully opened database '$dbname'"


#==========================================================================
#====== Code Step 3 of 6... Resolve File System and Folders
#==========================================================================

#Build this portion of the directory structure out here in case scripting takes more than one minute.
$DateFolder = "" #get-date -format yyyyMMddHHmm
$RootPath = $FileLocation + $dbfoldername + "\" + $DateFolder
    
AddToLog ""
AddToLog "Server is set as $server [$dbname] and will be saved to $RootPath"
AddToLog ""

if($DeleteRootFolder -eq $true)
{
    AddToLog "Deleting existing root folders"
    if (( Test-Path -path "$RootPath" )) # Remove folder if existing
    {
        Remove-Item -Recurse -Force $RootPath 
    }
}    

if (!( Test-Path -path "$RootPath" )) # create it if not existing
{
    $progress ="attempting to create directory $RootPath"
    Try 
    { 
        New-Item "$RootPath" -type directory | out-null 
    }
    Catch [system.exception]
    {
        Write-Error "error while $progress. $_"
        AddToLog "error while $progress. $_"
        return
    }
}
    



#==========================================================================
#====== Code Step 4 of 6... Resolve Scripting Options
#==========================================================================
AddToLog "Preparing Scripting options"

# Set the list option for CREATE-IfNotExists for Tables
$IfNotExistsOptions = New-Object ("Microsoft.SqlServer.Management.Smo.Scripter") ($SMOserver)
# a full list of options is found here: https://msdn.microsoft.com/en-us/library/microsoft.sqlserver.management.smo.scriptingoptions.aspx
$IfNotExistsOptions.Options.AppendToFile = $False
$IfNotExistsOptions.Options.AllowSystemObjects = $False
$IfNotExistsOptions.Options.ClusteredIndexes = $True
$IfNotExistsOptions.Options.DriAll = $True
$IfNotExistsOptions.Options.ScriptDrops = $False
$IfNotExistsOptions.Options.IncludeHeaders = $False
$IfNotExistsOptions.Options.ToFileOnly = $True
$IfNotExistsOptions.Options.Indexes = $True
$IfNotExistsOptions.Options.Permissions = $True
$IfNotExistsOptions.Options.WithDependencies = $False
$IfNotExistsOptions.Options.IncludeIfNotExists = $True # For tables/views, the script should not just create
$IfNotExistsOptions.Options.AnsiFile = $True
$IfNotExistsOptions.Options.NoCollation = $True



# set up the script options for the DROP + CREATE of other objects
# a full list of options is found here: https://msdn.microsoft.com/en-us/library/microsoft.sqlserver.management.smo.scriptingoptions.aspx
$DropOptions = New-Object ("Microsoft.SqlServer.Management.Smo.Scripter") ($SMOserver)
$DropOptions.Options.AppendToFile = $False # does not append, this is a new file
$DropOptions.Options.AllowSystemObjects = $False
$DropOptions.Options.ClusteredIndexes = $True
$DropOptions.Options.DriAll = $True
$DropOptions.Options.ScriptDrops = $True
$DropOptions.Options.IncludeHeaders = $False
$DropOptions.Options.ToFileOnly = $True
$DropOptions.Options.Indexes = $True
$DropOptions.Options.WithDependencies = $False
$DropOptions.Options.IncludeIfNotExists = $True
$DropOptions.Options.AnsiFile = $True
$DropOptions.Options.NoCollation = $True

#Create Again
$CreateOptions = New-Object ("Microsoft.SqlServer.Management.Smo.Scripter") ($SMOserver)
$CreateOptions.Options.AppendToFile = $True # This appends to the DROP script file
$CreateOptions.Options.AllowSystemObjects = $False
$CreateOptions.Options.ClusteredIndexes = $True
$CreateOptions.Options.DriAll = $True
$CreateOptions.Options.ScriptDrops = $False
$CreateOptions.Options.IncludeHeaders = $False
$CreateOptions.Options.ToFileOnly = $True
$CreateOptions.Options.Indexes = $True
$CreateOptions.Options.Permissions = $True
$CreateOptions.Options.WithDependencies = $False
$CreateOptions.Options.AnsiFile = $True
$CreateOptions.Options.NoCollation = $True
    

#==========================================================================
#====== Code Step 5 of 6... Get List of Database Objects
#==========================================================================

$sp = New-Object ("Microsoft.SqlServer.Management.Smo.StoredProcedure")
$vw = New-Object ("Microsoft.SqlServer.Management.Smo.View")
$tb = New-Object ("Microsoft.SqlServer.Management.Smo.Table")
$uf = New-Object ("Microsoft.SqlServer.Management.Smo.UserDefinedFunction")
$ur = New-Object ("Microsoft.SqlServer.Management.Smo.User")
$sh = New-Object ("Microsoft.SqlServer.Management.Smo.Schema")


#defaults for sp
$typ = $sp.GetType()
$SMOserver.SetDefaultInitFields($typ,$false)
$SMOserver.SetDefaultInitFields($typ,"CreateDate","DateLastModified","IsSystemObject","ClassName")

#defaults for vw
$typ = $vw.GetType()
$SMOserver.SetDefaultInitFields($typ,"CreateDate","DateLastModified","IsSystemObject")

#defaults for table
$typ = $tb.GetType()
$SMOserver.SetDefaultInitFields($typ,"CreateDate","DateLastModified","IsSystemObject")

#defaults for user defined function
$typ = $uf.GetType()
$SMOserver.SetDefaultInitFields($typ,"CreateDate","DateLastModified","IsSystemObject")

#defaults for user defined function
$typ = $ur.GetType()
$SMOserver.SetDefaultInitFields($typ,"CreateDate","DateLastModified","IsSystemObject")

#defaults for schema
$typ = $sh.GetType()
$SMOserver.SetDefaultInitFields($typ, "Name", "IsSystemObject")  

"Looking up database objects..."

$Objects = @() # empty array

# if ($ObjectSearchEnabled -ne $True)
# {
#     if($StoredProcedure)      {$Objects += $db.StoredProcedures     | Where-Object {!($_.IsSystemObject) -and ($_.DateLastModified -ge $ModifiedDate -or $ModifiedDate -eq $null)}}
#     if($View)                 {$Objects += $db.Views                | Where-Object {!($_.IsSystemObject) -and ($_.DateLastModified -ge $ModifiedDate -or $ModifiedDate -eq $null)}}
#     if($Table)                {$Objects += $db.Tables               | Where-Object {!($_.IsSystemObject) -and ($_.DateLastModified -ge $ModifiedDate -or $ModifiedDate -eq $null)}}
#     if($Role)                 {$Objects += $db.Roles                | Where-Object {!($_.IsSystemObject) -and ($_.DateLastModified -ge $ModifiedDate -or $ModifiedDate -eq $null)}}
#     if($Rule)                 {$Objects += $db.Rules                | Where-Object {!($_.IsSystemObject) -and ($_.DateLastModified -ge $ModifiedDate -or $ModifiedDate -eq $null)}}
#     if($Schema)               {$Objects += $db.Schemas              | Where-Object {!($_.IsSystemObject) -and ($_.DateLastModified -ge $ModifiedDate -or $ModifiedDate -eq $null)}}
#     if($UserDefinedFunction)  {$Objects += $db.UserDefinedFunctions | Where-Object {!($_.IsSystemObject) -and ($_.DateLastModified -ge $ModifiedDate -or $ModifiedDate -eq $null)}}
#     if($User)                 {$Objects += $db.Users                | Where-Object {!($_.IsSystemObject) -and ($_.DateLastModified -ge $ModifiedDate -or $ModifiedDate -eq $null)}}
# }

if ($ObjectSearchEnabled -eq $True)
{
    $ObjectListPath = ".\ScriptOutDatabase_ObjectList.txt"
    
    if (!(Test-Path -Path $ObjectListPath))
    {
		[void](New-Item -type file $ObjectListPath)
    }
    
    #Get content of PayLoad File
	$ObjectList = get-content $ObjectListPath

	AddToLog "`r`n-- ObjectList --"

    #Get count of SQL files to Process
    foreach ($objectToSearch in $ObjectList) {
		# Extract object name and type
        if ($line -match "\[(.+?)\] (.+?) \((.+?)\)") {
            $objectName = $matches[2]  # Extracts the object name
            $objectType = $matches[3]  # Extracts the object type

            # Log object being processed
            AddToLog "Processing: $objectName ($objectType)"

            # Search in the correct category
            switch ($objectType) {
                "StoredProcedure"       { if($StoredProcedure)      {$Objects += $db.StoredProcedures     | Where-Object {($_.Name -eq $objectToSearch) -and ($_.DateLastModified -ge $ModifiedDate -or $ModifiedDate -eq $null)}} }
                "Table"                 { if($View)                 {$Objects += $db.Views                | Where-Object {($_.Name -eq $objectToSearch) -and ($_.DateLastModified -ge $ModifiedDate -or $ModifiedDate -eq $null)}} }
                "View"                  { if($Table)                {$Objects += $db.Tables               | Where-Object {($_.Name -eq $objectToSearch) -and ($_.DateLastModified -ge $ModifiedDate -or $ModifiedDate -eq $null)}} }
                "Role"                  { if($Role)                 {$Objects += $db.Roles                | Where-Object {($_.Name -eq $objectToSearch) -and ($_.DateLastModified -ge $ModifiedDate -or $ModifiedDate -eq $null)}} }
                "Rule"                  { if($Rule)                 {$Objects += $db.Rules                | Where-Object {($_.Name -eq $objectToSearch) -and ($_.DateLastModified -ge $ModifiedDate -or $ModifiedDate -eq $null)}} }
                "Schema"                { if($Schema)               {$Objects += $db.Schemas              | Where-Object {($_.Name -eq $objectToSearch)}} }
                "UserDefinedFunction"   { if($UserDefinedFunction)  {$Objects += $db.UserDefinedFunctions | Where-Object {($_.Name -eq $objectToSearch) -and ($_.DateLastModified -ge $ModifiedDate -or $ModifiedDate -eq $null)}} }
                "User"                  { if($User)                 {$Objects += $db.Users                | Where-Object {($_.Name -eq $objectToSearch) -and ($_.DateLastModified -ge $ModifiedDate -or $ModifiedDate -eq $null)}} }
                default                 { Write-Host "Unknown object type: $objectType" }
            }
    
            # if($StoredProcedure)      {$Objects += $db.StoredProcedures     | Where-Object {($_.Name -like $objectToSearch) -and ($_.DateLastModified -ge $ModifiedDate -or $ModifiedDate -eq $null)}}
            # if($View)                 {$Objects += $db.Views                | Where-Object {($_.Name -like $objectToSearch) -and ($_.DateLastModified -ge $ModifiedDate -or $ModifiedDate -eq $null)}}
            # if($Table)                {$Objects += $db.Tables               | Where-Object {($_.Name -like $objectToSearch) -and ($_.DateLastModified -ge $ModifiedDate -or $ModifiedDate -eq $null)}}
            # if($Role)                 {$Objects += $db.Roles                | Where-Object {($_.Name -like $objectToSearch) -and ($_.DateLastModified -ge $ModifiedDate -or $ModifiedDate -eq $null)}}
            # if($Rule)                 {$Objects += $db.Rules                | Where-Object {($_.Name -like $objectToSearch) -and ($_.DateLastModified -ge $ModifiedDate -or $ModifiedDate -eq $null)}}
            # if($Schema)               {$Objects += $db.Schemas              | Where-Object {($_.Name -like $objectToSearch)}}
            # if($UserDefinedFunction)  {$Objects += $db.UserDefinedFunctions | Where-Object {($_.Name -like $objectToSearch) -and ($_.DateLastModified -ge $ModifiedDate -or $ModifiedDate -eq $null)}}
            # if($User)                 {$Objects += $db.Users                | Where-Object {($_.Name -like $objectToSearch) -and ($_.DateLastModified -ge $ModifiedDate -or $ModifiedDate -eq $null)}}
        }
    }
}

$ObjectTotalCount = $Objects.Count
AddToLog "`r`nTotal Objects: $ObjectTotalCount"


""
""
#==========================================================================
#====== Code Step 6 of 6... Loop Over Objects - Generate Scripts
#==========================================================================
"Looping Over Objects"    
$ObjectCounter = 0
foreach ($ScriptThis in $Objects)
{

    $ObjectCounter = $ObjectCounter + 1
    $ObjectType = $ScriptThis.GetType().Name
    $Schema = $ScriptThis.Schema
    $ObjectName = $ScriptThis.Name

    If ($Schema -eq $null){$Schema = ""}
    
    #====== Decide Which scripting option to use in this case.
    if (($ObjectType -eq "Table" -or $ObjectType -eq "Schema"-or $ObjectType -eq "StoredProcedure" -or $ObjectType -eq "User") -and $DropCreate -eq $False) #($ObjectType -eq "Table" -or $ObjectType -eq "View" -or $ObjectType -eq "Schema"-or $ObjectType -eq "StoredProcedure")
    { 
        $CreateIfNotExists = $True 
    }
    else
    {
        $CreateIfNotExists = $false # DropAndCreate
    }


    #====== Decide which folder structure to use
    if($UseSchemaFolders -eq $true -and $Schema -ne "") # if Schema is missing (as with Users and Roles) then use the same root folder strutctre
    {
        # Group all folders first based on Schema, and then type
        $Folder = "$RootPath$Schema\$ObjectType"
    }
    else
    {
        $Folder = "$RootPath$ObjectType" # Group folder just based on type
    }


    #====== Decide which file Name structure to use
    if ($UseSquareBrackets -and $Schema -ne "") # if Schema is missing (as with Users and Roles) then don't use square brackets anyhow
    {
        $FileName = "[$Schema].[$ObjectName]"            
    }
    else
    {
        $FileName = $ScriptThis -replace "\[|\]|\\" ###### Remove all square brackets in file names
    }


    #====== Build folder structures.  Remove the type folder if you want to overwrite.
    if ((Test-Path -Path $Folder) -eq $false) # eg... c:\MyFolder\StoredProcedure   
    {
        #Create the folder for "StoredProcedure" to hold scripted files.
        AddToLog "Creating Folder $Folder"
        [system.io.directory]::CreateDirectory($Folder)
    }
        


    if($ObjectType -eq "Table" -or $ObjectType -eq "View" -or $ObjectTYpe -eq "StoredProcedure" -or $ObjectType -eq "User" -or $ObjectType -eq "DatabaseRole") {
        $DateLastModified = $ScriptThis.DateLastModified
        AddToLog "	Scripting $ObjectCounter/$ObjectTotalCount $ObjectType $ScriptThis DateLastModified: $DateLastModified" 
    }
    else
    {
        AddToLog "	Scripting $ObjectCounter/$ObjectTotalCount $ObjectType $ScriptThis"
    }

    #====== SCRIPT the object, this is where each object actually gets scripted one at a time.
    If($CreateIfNotExists -eq $true)
    {
        $IfNotExistsOptions.Options.FileName = "$Folder\$FileName.SQL"
        $IfNotExistsOptions.Script($ScriptThis) 
    }
    else # DropAndCreate
    {
        $DropOptions.Options.FileName = "$Folder\$FileName.SQL"
        $CreateOptions.Options.FileName = "$Folder\$FileName.SQL"
        $DropOptions.Script($ScriptThis) 
        $CreateOptions.Script($ScriptThis) 
    }

} #This ends the loop
     
AddToLog ""
AddToLog "Done Scripting"   
