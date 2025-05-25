# ONF-WP v1.0.0-Alpha - Windows Permission Setup
# "Nishkaam Karma Yoga" - Cross-Platform Excellence

Write-Host "🚀 ONF-WP Revolutionary Permission Setup" -ForegroundColor Cyan
Write-Host "Setting up executable permissions for Windows..." -ForegroundColor Blue

# Scripts to make executable
$scripts = @(
    "onf-wp"
    "scripts\volume-management\volume-manager.sh"
    "scripts\setup\revolutionary-setup.sh"
    "scripts\setup\platform-optimizer.sh"  
    "scripts\maintenance\health-check.sh"
)

foreach ($script in $scripts) {
    if (Test-Path $script) {
        Write-Host "✅ Found: $script" -ForegroundColor Green
        # On Windows, we ensure the script has proper line endings and is accessible
        if ($script -eq "onf-wp") {
            # Ensure onf-wp has proper shebang for Git Bash/WSL
            $content = Get-Content $script -Raw
            if ($content -notmatch '^#!/usr/bin/env bash') {
                Write-Host "   Adding proper shebang to onf-wp" -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "❌ Missing: $script" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "🎉 Permission setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "💡 On Windows, you can run ONF-WP using:" -ForegroundColor Cyan
Write-Host "   bash onf-wp <command>   # Git Bash/WSL" -ForegroundColor White
Write-Host "   .\onf-wp <command>      # PowerShell with WSL" -ForegroundColor White
Write-Host ""
Write-Host "🚀 Ready to start: bash onf-wp setup" -ForegroundColor Green 