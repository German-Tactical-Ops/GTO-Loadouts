# Array-Austausch Skript fuer Uniform-Items
# Fuehre dieses Skript im Ordner mit den .txt-Dateien aus

# Definition der zu entfernenden Items (aus Alpha)
$itemsToRemove = @(
    "ACE_packingBandage",
    "ACE_painkillers"
)

# Definition der hinzuzufuegenden Items (aus Bravo)
$itemsToAdd = @(
    '["ACM_PressureBandage",22]',
    '["ACM_FieldBloodTransfusionKit_500",1]',
    '["ACM_ChestSeal",2]',
    '["ACM_Paracetamol",1,10]'
)

# Funktion zum Parsen und Bearbeiten des Uniform-Arrays
function Update-UniformArray {
    param([string]$content)
    
    # Finde den TPW_ Uniform-Block
    if ($content -match '(\["TPW_[^"]+"\s*,\s*\[)') {
        $uniformStart = $content.IndexOf($matches[0])
        $arrayStart = $uniformStart + $matches[0].Length
        
        # Finde das Ende des Arrays durch Klammer-Zaehlung
        $depth = 1
        $pos = $arrayStart
        while ($depth -gt 0 -and $pos -lt $content.Length) {
            $char = $content[$pos]
            if ($char -eq '[') { $depth++ }
            elseif ($char -eq ']') { $depth-- }
            $pos++
        }
        
        if ($depth -eq 0) {
            # Extrahiere den Array-Inhalt
            $arrayContent = $content.Substring($arrayStart, $pos - $arrayStart - 1)
            $prefix = $content.Substring($uniformStart, $arrayStart - $uniformStart)
            
            # Parse die Items im Array
            $items = @()
            $currentItem = ""
            $itemDepth = 0
            $inString = $false
            
            for ($i = 0; $i -lt $arrayContent.Length; $i++) {
                $char = $arrayContent[$i]
                
                if ($char -eq '"' -and ($i -eq 0 -or $arrayContent[$i-1] -ne '\')) {
                    $inString = -not $inString
                }
                
                if (-not $inString) {
                    if ($char -eq '[') { $itemDepth++ }
                    elseif ($char -eq ']') { $itemDepth-- }
                    
                    if ($char -eq ',' -and $itemDepth -eq 0) {
                        if ($currentItem.Trim()) {
                            $items += $currentItem.Trim()
                        }
                        $currentItem = ""
                        continue
                    }
                }
                
                $currentItem += $char
            }
            
            # Letztes Item hinzufuegen
            if ($currentItem.Trim()) {
                $items += $currentItem.Trim()
            }
            
            # Filtere Items die entfernt werden sollen
            $filteredItems = @()
            foreach ($item in $items) {
                $shouldRemove = $false
                foreach ($removeItem in $itemsToRemove) {
                    if ($item -match '^\["' + [regex]::Escape($removeItem) + '"') {
                        $shouldRemove = $true
                        Write-Host "    Entfernt: $removeItem" -ForegroundColor Red
                        break
                    }
                }
                if (-not $shouldRemove) {
                    $filteredItems += $item
                }
            }
            
            # Fuege neue Items hinzu (wenn nicht bereits vorhanden)
            foreach ($newItem in $itemsToAdd) {
                $itemName = ($newItem -split '"')[1]
                $alreadyExists = $false
                
                foreach ($existingItem in $filteredItems) {
                    if ($existingItem -match '^\["' + [regex]::Escape($itemName) + '"') {
                        $alreadyExists = $true
                        Write-Host "    Bereits vorhanden: $itemName" -ForegroundColor Gray
                        break
                    }
                }
                
                if (-not $alreadyExists) {
                    $filteredItems += $newItem
                    Write-Host "    Hinzugefuegt: $itemName" -ForegroundColor Green
                }
            }
            
            # Baue das neue Array zusammen
            $newArrayContent = $filteredItems -join ","
            $newUniformBlock = $prefix + $newArrayContent + "]]"
            
            # Ersetze im Original-Content
            $endPos = $pos + 1
            $before = $content.Substring(0, $uniformStart)
            $after = $content.Substring($endPos)
            
            return $before + $newUniformBlock + $after
        }
    }
    
    return $content
}

# Alle .txt-Dateien im aktuellen Verzeichnis finden
$txtFiles = Get-ChildItem -Path . -Filter *.txt

Write-Host "Gefundene .txt-Dateien: $($txtFiles.Count)" -ForegroundColor Cyan

foreach ($file in $txtFiles) {
    Write-Host "`nBearbeite: $($file.Name)" -ForegroundColor Yellow
    
    # Dateiinhalt einlesen
    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
    $originalContent = $content
    
    # Pruefen ob TPW_ vorhanden ist
    if ($content -match '\["TPW_[^"]+"\s*,\s*\[') {
        Write-Host "  Uniform-Array gefunden" -ForegroundColor Green
        
        # Array aktualisieren
        $newContent = Update-UniformArray -content $content
        
        # Nur schreiben wenn sich etwas geaendert hat
        if ($newContent -ne $originalContent) {
            Set-Content -Path $file.FullName -Value $newContent -Encoding UTF8 -NoNewline
            Write-Host "  Datei aktualisiert" -ForegroundColor Green
        } else {
            Write-Host "  Keine Aenderungen notwendig" -ForegroundColor Gray
        }
    } else {
        Write-Host "  Kein TPW_ Uniform-Array gefunden" -ForegroundColor DarkGray
    }
}

Write-Host "`n=== Fertig ===" -ForegroundColor Cyan
Read-Host "Druecke Enter zum Beenden"