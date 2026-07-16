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
        "assets/scripts/visual/battle_world_3d.gdc",
        "assets/scripts/visual/unit_view_3d.gdc",
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
        "arena-v2.png",
        "card-art-v2.png",
        "card-art-v4.png",
        "icon.png",
        "tower-sprites-v3.png",
        "unit-sprites-v3.png",
        "unit-sprites-v4.png"
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
    if ($Variant -eq "arm64" -and $entries.ContainsKey("lib/armeabi-v7a/libgodot_android.so")) {
        throw "L'APK ARM64 contient par erreur la bibliothèque ARMv7."
    }

    Write-Host "APK vérifié : $resolved"
    Write-Host "Scripts d'exécution : 8/8 | Textures : 7/7 | Variante : $Variant"
}
finally {
    $archive.Dispose()
}
