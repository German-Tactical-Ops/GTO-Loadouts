# update_to_base_standard.ps1
# Bringt alle Loadouts auf den neuen Base_Rifleman Standard
# Aendert: Uniform-Items, Vest-Items, Waffe (M4/MK18 -> MCC)

$loadoutPath = Join-Path $PSScriptRoot "Loadouts"

# === KONFIGURATION ===

# Nur diese Dateien werden bearbeitet (Uniform/Vest/Waffe Update)
$filesToUpdate = @(
    "Ammo_Carrier.txt",
    "EOD.txt",
    "Grenadier.txt",
    "HAT.txt",
    "JTAC.txt",
    "Junior_Medic.txt",
    "Platoon_Leader.txt",
    "Platoon_Medic.txt",
    "SL.txt",
    "Squad-Medic_ARFR.txt"
)

# === HILFSFUNKTIONEN ===

# Parsed komma-separierte Items unter Beruecksichtigung von Klammern
function Parse-ArrayItems {
    param([string]$arrayContent)

    $items = [System.Collections.ArrayList]::new()
    $current = ""
    $depth = 0
    $inStr = $false

    for ($i = 0; $i -lt $arrayContent.Length; $i++) {
        $c = $arrayContent[$i]
        if ($c -eq '"' -and ($i -eq 0 -or $arrayContent[$i-1] -ne '\')) {
            $inStr = -not $inStr
        }
        if (-not $inStr) {
            if ($c -eq '[') { $depth++ }
            elseif ($c -eq ']') { $depth-- }
            if ($c -eq ',' -and $depth -eq 0) {
                if ($current.Trim()) { [void]$items.Add($current.Trim()) }
                $current = ""
                continue
            }
        }
        $current += $c
    }
    if ($current.Trim()) { [void]$items.Add($current.Trim()) }
    return ,$items
}

# Extrahiert den Item-Namen aus einem Array-Eintrag wie ["ItemName",1]
function Get-ItemName {
    param([string]$itemStr)
    if ($itemStr -match '^\["([^"]+)"') { return $matches[1] }
    return $null
}

# Findet einen Array-Block anhand eines Regex-Patterns
function Find-BlockByPattern {
    param([string]$content, [string]$pattern)

    if ($content -match $pattern) {
        $start = $content.IndexOf($matches[0])
        $arrayStart = $start + $matches[0].Length
        $depth = 1; $pos = $arrayStart
        while ($depth -gt 0 -and $pos -lt $content.Length) {
            if ($content[$pos] -eq '[') { $depth++ }
            elseif ($content[$pos] -eq ']') { $depth-- }
            $pos++
        }
        if ($depth -eq 0) {
            return @{
                Start      = $start
                ArrayStart = $arrayStart
                ArrayEnd   = $pos - 1
                Content    = $content.Substring($arrayStart, $pos - $arrayStart - 1)
                Prefix     = $matches[0]
            }
        }
    }
    return $null
}

# Modifiziert Items in einem Array-Block (Uniform oder Vest)
function Update-ArrayBlock {
    param(
        [string]$content,
        [string]$blockPattern,
        [string[]]$removeItems,
        [string[]]$addItems,
        [hashtable]$changeItems,
        [string]$blockName
    )

    $block = Find-BlockByPattern -content $content -pattern $blockPattern
    if (-not $block) {
        Write-Host "    $blockName Block nicht gefunden" -ForegroundColor DarkGray
        return @{ Content = $content; Removed = @() }
    }

    $items = Parse-ArrayItems -arrayContent $block.Content
    $removed = @()

    # Items entfernen und aendern
    $filtered = [System.Collections.ArrayList]::new()
    foreach ($item in $items) {
        $name = Get-ItemName $item
        $shouldRemove = $false

        foreach ($r in $removeItems) {
            if ($name -eq $r) {
                $shouldRemove = $true
                $removed += $name
                Write-Host "    [$blockName] Entfernt: $name" -ForegroundColor Red
                break
            }
        }

        if (-not $shouldRemove) {
            if ($changeItems -and $name -and $changeItems.ContainsKey($name)) {
                [void]$filtered.Add($changeItems[$name])
                Write-Host "    [$blockName] Geaendert: $name" -ForegroundColor Yellow
            } else {
                [void]$filtered.Add($item)
            }
        }
    }

    # Neue Items hinzufuegen (wenn nicht bereits vorhanden)
    foreach ($newItem in $addItems) {
        $newName = Get-ItemName $newItem
        $exists = $false
        foreach ($f in $filtered) {
            if ((Get-ItemName $f) -eq $newName) { $exists = $true; break }
        }
        if (-not $exists) {
            [void]$filtered.Add($newItem)
            Write-Host "    [$blockName] Hinzugefuegt: $newName" -ForegroundColor Green
        } else {
            Write-Host "    [$blockName] Bereits vorhanden: $newName" -ForegroundColor Gray
        }
    }

    # Block zusammenbauen
    $newArrayContent = ($filtered -join ",")
    $before = $content.Substring(0, $block.ArrayStart)
    $after = $content.Substring($block.ArrayEnd)

    return @{
        Content = $before + $newArrayContent + $after
        Removed = $removed
    }
}

# === HAUPTPROGRAMM ===

$txtFiles = Get-ChildItem -Path $loadoutPath -Filter *.txt

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Loadout Update auf Base_Rifleman Standard" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Gefundene Dateien: $($txtFiles.Count)" -ForegroundColor Cyan
Write-Host "Zu aktualisieren: $($filesToUpdate -join ', ')" -ForegroundColor Cyan

foreach ($file in $txtFiles) {
    if ($filesToUpdate -notcontains $file.Name) {
        Write-Host "`n--- $($file.Name) --- UEBERSPRUNGEN" -ForegroundColor DarkGray
        continue
    }

    Write-Host "`n=== $($file.Name) ===" -ForegroundColor Yellow

    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
    $original = $content

    # --------------------------------------------------
    # 1. UNIFORM aktualisieren
    # --------------------------------------------------
    # Pattern matcht TPW_ und U_B_ Uniformen
    $uniformPattern = '(\["(?:TPW_|U_B_)[^"]*"\s*,\s*\[)'

    # Bandagen anpassen je nach Extra-Items in der Uniform
    $bandageCount = 35
    if ($file.Name -in @("SL.txt", "Platoon_Leader.txt")) {
        $bandageCount = 33  # ACE_MapTools (Mass 2)
        Write-Host "    Bandagen reduziert auf $bandageCount (ACE_MapTools)" -ForegroundColor Yellow
    }
    if ($file.Name -eq "JTAC.txt") {
        $bandageCount = 29  # MapTools(2) + microDAGR(1) + PlottingBoard(2) + notepad(1) = 6
        Write-Host "    Bandagen reduziert auf $bandageCount (MapTools+microDAGR+PlottingBoard+notepad)" -ForegroundColor Yellow
    }

    $uniformResult = Update-ArrayBlock `
        -content $content `
        -blockPattern $uniformPattern `
        -removeItems @("ACM_FieldBloodTransfusionKit_500", "ItemAndroid", "rhsusf_mag_17Rnd_9x19_JHP") `
        -addItems @('["ACM_EmergencyTraumaDressing",2]') `
        -changeItems @{ "ACM_PressureBandage" = "[`"ACM_PressureBandage`",$bandageCount]" } `
        -blockName "Uniform"

    $content = $uniformResult.Content
    $removedFromUniform = $uniformResult.Removed

    # --------------------------------------------------
    # 2. VEST aktualisieren
    # --------------------------------------------------
    # Pattern matcht 3DMA_WD_AVS_ und V_TacVest_ Westen
    $vestPattern = '(\["(?:3DMA_WD_AVS|V_TacVest)[^"]*"\s*,\s*\[)'

    # Vest-Items: Saline immer, ItemAndroid und Pistol-Mag nur wenn aus Uniform entfernt
    $vestAdds = [System.Collections.ArrayList]::new()
    [void]$vestAdds.Add('["ACE_salineIV_500",3]')

    if ($removedFromUniform -contains "ItemAndroid") {
        [void]$vestAdds.Add('["ItemAndroid",1]')
    }
    if ($removedFromUniform -contains "rhsusf_mag_17Rnd_9x19_JHP") {
        [void]$vestAdds.Add('["rhsusf_mag_17Rnd_9x19_JHP",1,17]')
    }

    $vestResult = Update-ArrayBlock `
        -content $content `
        -blockPattern $vestPattern `
        -removeItems @() `
        -addItems $vestAdds.ToArray() `
        -changeItems @{} `
        -blockName "Vest"

    $content = $vestResult.Content

    # --------------------------------------------------
    # 3. WAFFE -> MCC aktualisieren (M4 und MK18)
    # --------------------------------------------------
    Write-Host "  Waffe -> MCC" -ForegroundColor Cyan

    # M4 Weapon + Grip
    $content = $content.Replace('"rhs_weap_m4_urgi_kac"', '"MCC_M4A1_556_URGI"')
    $content = $content.Replace('"rhs_acc_m4_urgi_d"', '""')

    # MK18 Weapon + Grip (EOD, Junior_Medic, Platoon_Medic)
    $content = $content.Replace('"rhs_weap_mk18_urgi_kac"', '"MCC_M4A1_556_URGI"')
    $content = $content.Replace('"rhs_acc_mk18_urgi_d"', '""')

    # Attachments
    $content = $content.Replace('"rhsusf_acc_nt4_tan"', '"MCC_RC2_556_FDE"')
    $content = $content.Replace('"rhsusf_acc_anpeq15_wmx"', '"MCC_AR_PEQ15_M300C_Tail_FDE_IRL"')
    $content = $content.Replace('"rhsusf_acc_anpeq15side"', '"MCC_AR_PEQ15_M300C_Tail_FDE_IRL"')

    # Optic: "rhsusf_acc_su230" -> "rhsusf_acc_su230_3d"
    # (matcht NICHT su230a oder su230a_c dank der Anfuehrungszeichen)
    $content = $content.Replace('"rhsusf_acc_su230"', '"rhsusf_acc_su230_3d"')

    # Waffen-Magazin (im Gewehr geladen): ["..._PMAG",30] -> ["..._PMAG_Tan",30]
    $content = $content.Replace(
        '["rhs_mag_30Rnd_556x45_M855A1_PMAG",30]',
        '["rhs_mag_30Rnd_556x45_M855A1_PMAG_Tan",30]'
    )

    # Ersatz-Magazine (Vest/Backpack): restliche _PMAG -> MCC
    $content = $content.Replace(
        '"rhs_mag_30Rnd_556x45_M855A1_PMAG"',
        '"MCC_PMAG_556_FDE_556_30_M855A1"'
    )

    Write-Host "    Waffe und Magazine aktualisiert" -ForegroundColor Green

    # --------------------------------------------------
    # 4. DATEI SPEICHERN
    # --------------------------------------------------
    if ($content -ne $original) {
        Set-Content -Path $file.FullName -Value $content -Encoding UTF8 -NoNewline
        Write-Host "  >>> GESPEICHERT <<<" -ForegroundColor Green
    } else {
        Write-Host "  Keine Aenderungen notwendig" -ForegroundColor Gray
    }
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "  Fertig!" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Read-Host "Druecke Enter zum Beenden"
