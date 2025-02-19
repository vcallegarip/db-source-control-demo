
Exit ## safety switch


##
##  to script into a GIT repo folder for version review
##

#### TEST
## to script 'Interject-test' to 'Interject' folder. Folder is replaced.
powershell.exe -File "C:\GitHub\Parametrix\GenerateSqlScripts_v2.ps1" "AZRSQL01" "Interject-test" "Interject" "C:\GitHub\Parametrix\DB" true false true

## to script 'Interject_Reporting@Parametrix-test' to 'Interject_Reporting@Parametrix' folder. Folder is replaced.
powershell.exe -File "C:\GitHub\Parametrix\GenerateSqlScripts_v2_SchemaFilter.ps1" "AZRSQL01" "Interject_Reporting@Parametrix-test" "Interject_Reporting@Parametrix" "C:\GitHub\Parametrix\DB" true false true

#### PROD
## to script 'Interject-prod' to 'Interject' folder. Folder is replaced.
powershell.exe -File "C:\GitHub\Parametrix\GenerateSqlScripts_v2.ps1" "AZRSQL01" "Interject-prod" "Interject" "C:\GitHub\Parametrix\DB" true false true

## to script 'Interject_Reporting@Parametrix-prod' to 'Interject_Reporting@Parametrix' folder. Folder is replaced.
powershell.exe -File "C:\GitHub\Parametrix\GenerateSqlScripts_v2_SchemaFilter.ps1" "AZRSQL01" "Interject_Reporting@Parametrix-prod" "Interject_Reporting@Parametrix" "C:\GitHub\Parametrix\DB" true false true

