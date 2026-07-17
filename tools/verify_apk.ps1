param(
    [Parameter(Mandatory = $true)]
    [string]$ApkPath,

    [ValidateSet("universal", "arm64")]
    [string]$Variant = "universal"
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression.FileSystem

$resolved = (Resolve-Path -LiteralPath $ApkPath).Path
$archive = [System.IO.Compression.ZipFile]::OpenRead($resolved)
try {
    $entries = @{}
    foreach ($entry in $archive.Entries) {
        $entries[$entry.FullName] = $entry.Length
    }

    $required = @(
        "assets/project.binary",
        "assets/.godot/global_script_class_cache.cfg",
        "assets/scenes/main.tscn.remap",
        "assets/scripts/game.gdc",
        "assets/scripts/profile_store.gdc",
        "assets/scripts/progression.gdc",
        "assets/scripts/tutorial_flow.gdc",
        "assets/scripts/sim/ai_controller.gdc",
        "assets/scripts/sim/battle_sim.gdc",
        "assets/scripts/ui/arena_theme.gdc",
        "assets/scripts/ui/battle_announcement.gdc",
        "assets/scripts/ui/card_art_control.gdc",
        "assets/scripts/ui/difficulty_sheet.gdc",
        "assets/scripts/ui/energy_segments.gdc",
        "assets/scripts/ui/lobby_diorama.gdc",
        "assets/scripts/ui/royal_backdrop.gdc",
        "assets/scripts/visual/battle_world_2d.gdc",
        "assets/scripts/visual/unit_rig_definition.gdc",
        "assets/scripts/visual/unit_view_2d.gdc",
        "lib/arm64-v8a/libgodot_android.so"
    )
    if ($Variant -eq "universal") {
        $required += "lib/armeabi-v7a/libgodot_android.so"
    }

    $missing = @($required | Where-Object { -not $entries.ContainsKey($_) -or $entries[$_] -le 0 })
    if ($missing.Count -gt 0) {
        throw "APK incomplet. Entrées absentes : $($missing -join ', ')"
    }
    if ($entries["assets/.godot/global_script_class_cache.cfg"] -lt 100) {
        throw "Le cache des classes globales est vide ou tronqué."
    }

    $textureNames = @(
        "arena-royale-v040.png",
        "tower-parts-v040.png",
        "spell-art-v040.png",
        "ui-icons-v040.png",
        "guardian-kaykit-v050.png",
        "ranger-kaykit-v050.png",
        "colossus-kaykit-v050.png",
        "duelist-kaykit-v050.png",
        "alchemist-kaykit-v050.png",
        "bulwark-kaykit-v050.png",
        "app-icon-v050.png",
        "button-long-blue.png",
        "button-long-gold.png",
        "border-ornate.png",
        "icon-home.png",
        "icon-cards.png",
        "icon-training.png",
        "icon-battle.png",
        "icon-crown.png",
        "icon-time.png",
        "icon-award.png"
    )
    $missingTextures = @()
    foreach ($textureName in $textureNames) {
        $pattern = "assets/.godot/imported/$textureName-*.ctex"
        $matches = @($entries.Keys | Where-Object { $_ -like $pattern -and $entries[$_] -gt 0 })
        if ($matches.Count -eq 0) {
            $missingTextures += $textureName
        }
    }
    if ($missingTextures.Count -gt 0) {
        throw "Textures compilées absentes : $($missingTextures -join ', ')"
    }

    $fontNames = @("Baloo2-Variable.ttf", "Nunito-Variable.ttf")
    $missingFonts = @()
    foreach ($fontName in $fontNames) {
        $pattern = "assets/.godot/imported/$fontName-*.fontdata"
        $matches = @($entries.Keys | Where-Object { $_ -like $pattern -and $entries[$_] -gt 0 })
        if ($matches.Count -eq 0) {
            $missingFonts += $fontName
        }
    }
    if ($missingFonts.Count -gt 0) {
        throw "Polices compilées absentes : $($missingFonts -join ', ')"
    }
    if ($Variant -eq "arm64" -and $entries.ContainsKey("lib/armeabi-v7a/libgodot_android.so")) {
        throw "L'APK ARM64 contient par erreur la bibliothèque ARMv7."
    }
    $apkSize = (Get-Item -LiteralPath $resolved).Length
    if ($apkSize -gt 95MB) {
        throw "APK trop volumineux : $([Math]::Round($apkSize / 1MB, 1)) Mo (budget : 95 Mo)."
    }

    Write-Host "APK vérifié : $resolved"
    Write-Host "Scripts d'exécution : 16/16 | Textures : $($textureNames.Count)/$($textureNames.Count) | Polices : 2/2 | Variante : $Variant | Taille : $([Math]::Round($apkSize / 1MB, 1)) Mo"
}
finally {
    $archive.Dispose()
}
