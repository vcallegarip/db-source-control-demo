
Exit ## safety switch


##
##  to script into a GIT repo folder for version review
##

#### TEST

powershell.exe -File `
    ".\GenerateSqlScripts.ps1" `
    "localhost,1407" `
    "Interject_Reporting@SourceControl-test" `
    "Interject_Reporting@SourceControl-test" `
    ".\DB" `
    true `
    false `
    true `
    "sa" `
    "nt4work123!!"

powershell.exe -File `
    ".\GenerateSqlScripts.ps1" `
    "localhost,1407" `
    "Interject@SourceControl-test" `
    "Interject@SourceControl-test" `
    ".\DB" `
    true `
    false `
    true `
    "sa" `
    "nt4work123!!"


#### PROD