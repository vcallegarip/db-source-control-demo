
Exit ## safety switch


##
##  to script into a GIT repo folder for version review
##

#### TEST
powershell.exe -File ".\GenerateSqlScripts.ps1" "INTERJECT" "Database-SourceControl-Demo" "Database-SourceControl-Demo" ".\DB" true false true

#### PROD
# powershell.exe -File ".\GenerateSqlScripts.ps1" "INTERJECT" "Database-SourceControl-Demo-Prod" "Database-SourceControl-Demo-Prod" ".\DB" true false true
