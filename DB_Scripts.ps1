
Exit ## safety switch


##
##  to script into a GIT repo folder for version review
##

#### TEST
powershell.exe -File ".\GenerateSqlScripts.ps1" "INTERJECT" "Database-SourceControl-Demo" "Database-SourceControl-Demo" ".\DB" true false true
# powershell.exe -File ".\GenerateSqlScripts_ObjectsFilter.ps1" "INTERJECT" "Database-SourceControl-Demo" "Database-SourceControl-Demo" ".\DB" true false true "" "" true

#### PROD
# powershell.exe -File ".\GenerateSqlScripts.ps1" "INTERJECT" "Database-SourceControl-Demo-Prod" "Database-SourceControl-Demo-Prod" ".\DB" true false true
