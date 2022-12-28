# hugo serve --disableFastRender --source '.\themes\LoveIt\exampleSite\' --themesDir ..\..\
$themes = Get-ChildItem .\themes -directory
$count = $themes.Count

if ($count -eq 0) {
    Write-Host "No themes were found"
    Exit 1
}
elseif ($count -eq 1) {
    $theme = $themes[0] 
}
else {
    Clear-Host
    $themeNumber = -1
    Do {  
        Write-Host "Select theme:"
        for ($i = 0; $i -lt $count; $i++) {            
            Write-Host "`t$($i+1)`: $($themes[$i].Name)"
        }
        
        $choice = Read-Host   
        $success = [Int32]::TryParse($choice, [ref]$themeNumber) -and ($themeNumber -gt 0) -and ($themeNumber -le $count)
    } while (-Not ($success))   
    $theme = $themes[$themeNumber - 1]
}

Write-Host "Starting example for theme $theme"
$source = Join-Path -Path $theme -ChildPath "exampleSite"  
hugo serve --disableFastRender --source $source --themesDir ..\..\