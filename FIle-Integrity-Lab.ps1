### General Functions ###

Function Calculate-File-Hash($filepath) {
    $filehash = Get-FileHash -Path $filepath -Algorithm SHA512
    return $filehash
}
Function Erase-Baseline() {
    $baselineExists = Test-Path -Path .\baseline.txt

    if ($baselineExists) {
        # Delete it
        Remove-Item -Path .\baseline.txt
    }
}

Function Collect-Files() {
    $files = Get-ChildItem -Path .\Files
    return $files
}

### Option A Functions ###
Function Write-To-Baseline() {
    
    $files = Collect-Files
    # For each file, calculate the hash, and write to baseline.txt
    foreach ($f in $files) {
        $hash = Calculate-File-Hash $f.FullName
        "$($hash.Path)|$($hash.Hash)" | Out-File -FilePath .\baseline.txt -Append
        Print-To-Console($hash)
    }    
}

#Function to print hash values of current files in target folder to console
Function Print-To-Console($hash){
    "$($hash.Path) | $($hash.Hash)"
}


### Option B Functions ###
Function Update-Dictionary() {

    # Load file|hash from baseline.txt and store them in a dictionary
    $filePathsAndHashes = Get-Content -Path .\baseline.txt
    
    foreach ($f in $filePathsAndHashes) {
         $fileHashDictionary.add($f.Split("|")[0],$f.Split("|")[1])
    }    
}

Function Start-Delay() {
    Start-Sleep -Seconds 2
}

Function Check-Files() {
    $files = Get-ChildItem -Path .\Files

        # # For each file, calculate its hash and check if it has been created, modified, or unchanged
        foreach ($f in $files) {
            $hash = Calculate-File-Hash $f.FullName

            # Notify if a new file has been created
            if ($fileHashDictionary[$hash.Path] -eq $null) {
                # A new file has been created!
                Write-Host "$($hash.Path) has been created!" -ForegroundColor Green
            }
            else {

                # Notify if contents of an existing file has been changed
                if ($fileHashDictionary[$hash.Path] -eq $hash.Hash) { #checking the content hash in the dictionary vs the new hash of the content just taken
                    # The file has not changed
                }
                else {
                    # File file has been compromised!, notify the user
                    Write-Host "$($hash.Path) has changed!!!" -ForegroundColor Yellow
                }
            }
        }

}

# dictionary (key,value) = (path, hash value)
# no iteration needed, we are using th e Test-Path cmdlet
Function Check-File-Exist() {
    foreach ($key in $fileHashDictionary.Keys) {
            $baselineFileStillExists = Test-Path -Path $key
            if (-Not $baselineFileStillExists) {
                # One of the baseline files must have been deleted, notify the user
                Write-Host "$($key) has been deleted!" -ForegroundColor DarkRed -BackgroundColor Gray
            }
        }
}

### Introduction ###
Write-Host "Welcome to File Integrity Checker!"
Write-Host "A) Collect a new Baseline?"
Write-Host "B) Begin monitoring files with saved Baseline?"
$option = Read-Host -Prompt "Please enter 'A' or 'B'"


if ($option -eq "A".ToUpper()) {
    # Delete baseline.txt if it already exists to avoid multiples
    Erase-Baseline

    #Write a new Baseline.txt file & print to console to show user
    Write-To-Baseline
    
}

elseif ($option -eq "B".ToUpper()) {
    
    #Create empty  hash dictionary
    $fileHashDictionary = @{}

    #take files from baseline.txt and update to dictionary
    Update-Dictionary

    # Begin (continuously) monitoring files with saved Baseline
    while ($true) {

        #Check every 2 seconds
        Start-Delay
        
        #Check if file has been changed, created, altered
        Check-Files

        #Check if file was deleted
        Check-File-Exist
        
    }
}

