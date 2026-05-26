# update_urgi_magazines.ps1
# Vereinheitlicht das im Gewehr geladene Magazin aller URGI-Loadouts
# auf den Base_Rifleman Standard: MCC_PMAG_556_FDE_556_30_M855A1
#
# Hintergrund:
# Base_Rifleman benutzt im Gewehr ["MCC_PMAG_556_FDE_556_30_M855A1",30].
# Andere URGI-Loadouts haben dort noch ["rhs_mag_30Rnd_556x45_M855A1_PMAG_Tan",30].
# Die Ersatz-Magazine (Vest/Backpack) sind bereits MCC_PMAG... und bleiben unveraendert.

$loadoutPath = Join-Path $PSScriptRoot "Loadouts"

# URGI-Waffe (wird zur Identifikation der betroffenen Loadouts benutzt)
$urgiWeapon = "MCC_M4A1_556_URGI"

# Magazin-Ersetzung
$oldMagazine = '"rhs_mag_30Rnd_556x45_M855A1_PMAG_Tan"'
$newMagazine = '"MCC_PMAG_556_FDE_556_30_M855A1"'

# Base_Rifleman wird ausgeschlossen, da er bereits der Standard ist
$skipFiles = @("Base_Rifleman.txt")

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  URGI Magazin Vereinheitlichung" -ForegroundColor Cyan
Write-Host "  -> $newMagazine" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

$txtFiles = Get-ChildItem -Path $loadoutPath -Filter *.txt
$updatedCount = 0
$skippedCount = 0

foreach ($file in $txtFiles) {
    if ($skipFiles -contains $file.Name) {
        Write-Host "`n--- $($file.Name) --- UEBERSPRUNGEN (Standard)" -ForegroundColor DarkGray
        $skippedCount++
        continue
    }

    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8

    # Nur Loadouts mit URGI-Waffe bearbeiten
    if ($content -notmatch [regex]::Escape($urgiWeapon)) {
        Write-Host "`n--- $($file.Name) --- UEBERSPRUNGEN (keine URGI)" -ForegroundColor DarkGray
        $skippedCount++
        continue
    }

    Write-Host "`n=== $($file.Name) ===" -ForegroundColor Yellow

    $original = $content

    # Ersetze alle Vorkommen des alten Magazin-Namens (in-gun und ggf. Reserve)
    if ($content -match [regex]::Escape($oldMagazine)) {
        $occurrences = ([regex]::Matches($content, [regex]::Escape($oldMagazine))).Count
        $content = $content.Replace($oldMagazine, $newMagazine)
        Write-Host "    Ersetzt: $oldMagazine -> $newMagazine ($occurrences x)" -ForegroundColor Green
    } else {
        Write-Host "    Kein altes Magazin gefunden" -ForegroundColor Gray
    }

    if ($content -ne $original) {
        Set-Content -Path $file.FullName -Value $content -Encoding UTF8 -NoNewline
        Write-Host "  >>> GESPEICHERT <<<" -ForegroundColor Green
        $updatedCount++
    } else {
        Write-Host "  Keine Aenderungen notwendig" -ForegroundColor Gray
    }
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "  Fertig! Aktualisiert: $updatedCount | Uebersprungen: $skippedCount" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Read-Host "Druecke Enter zum Beenden"
