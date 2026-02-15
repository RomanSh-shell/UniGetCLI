function uniget {
    <#
    .SYNOPSIS
    Unified package manager for Windows - умный автоматический выбор менеджера
    
    .DESCRIPTION
    Автоматически определяет, в каком менеджере находится пакет и работает с ним.
    НЕ ТРЕБУЕТ указания менеджера вручную - всё делается автоматически!
    
    .PARAMETER command
    Команда: status, search, install, uninstall, update
    
    .PARAMETER packages
    Имена пакетов
    
    .EXAMPLE
    uniget status
    uniget search git
    uniget install nodejs python
    uniget update
    uniget update git
    uniget uninstall nodejs
    #>
    
    param(
        [Parameter(Position=0)]
        [ValidateSet("status", "search", "install", "uninstall", "update", "list", "download", "setup", "config")]
        [string]$command,
        
        [Parameter(Position=1, ValueFromRemainingArguments=$true)]
        [string[]]$packages
    )
    
    # Define available package managers
    $managers = @{
        "winget" = @{ 
            Name = "Windows Package Manager"
            Icon = "🟢"
            Check = { Get-Command winget -ErrorAction SilentlyContinue }
        }
        "choco" = @{ 
            Name = "Chocolatey"
            Icon = "🟤"
            Check = { Get-Command choco -ErrorAction SilentlyContinue }
        }
        "scoop" = @{ 
            Name = "Scoop"
            Icon = "🔵"
            Check = { Get-Command scoop -ErrorAction SilentlyContinue }
        }
        "npm" = @{ 
            Name = "Node Package Manager"
            Icon = "🟥"
            Check = { Get-Command npm -ErrorAction SilentlyContinue }
        }
        "pip" = @{ 
            Name = "Python Package Installer"
            Icon = "🐍"
            Check = { Get-Command pip -ErrorAction SilentlyContinue }
        }
        "cargo" = @{ 
            Name = "Rust Package Manager"
            Icon = "🦀"
            Check = { Get-Command cargo -ErrorAction SilentlyContinue }
        }
        "dotnet" = @{ 
            Name = ".NET Tool Manager"
            Icon = "🔷"
            Check = { Get-Command dotnet -ErrorAction SilentlyContinue }
        }
        "vcpkg" = @{ 
            Name = "C++ Package Manager"
            Icon = "⚙️"
            Check = { Get-Command vcpkg -ErrorAction SilentlyContinue }
        }
        "pwsh" = @{ 
            Name = "PowerShell Gallery"
            Icon = "💠"
            Check = { Get-Command Find-Module -ErrorAction SilentlyContinue }
        }
    }
    
    # Check availability менеджеров
    $available = @{}
    foreach($key in $managers.Keys) {
        $available[$key] = [bool](& $managers[$key].Check)
    }
    
    # Show help if no command specified
    if(-not $command) {
        Write-Host @"

UniGet - Unified Package Manager for Windows

Usage:
  uniget status                    Show all available package managers
  uniget list                      List all installed packages
  uniget search <package>          Search for package in all managers
  uniget install <package>...      Install package(s)
  uniget uninstall <package>...    Uninstall package(s)
  uniget update                    Show updates and choose what to update
  uniget update <package>...       Update specific package(s)
  uniget download <url> [output]   Download file from URL
  uniget setup                     Install missing package managers
  uniget config                    Configure package manager priorities

Examples:
  uniget config
  uniget setup
  uniget list
  uniget update
  uniget search git
  uniget install nodejs python rust
  uniget update git nodejs
  uniget uninstall nodejs
  uniget download https://example.com/file.zip
  uniget download https://example.com/app.exe MyApp.exe

UniGet automatically detects the right package manager!
No need to specify winget/choco/npm/pip manually.

"@ -ForegroundColor White
        return
    }
    
    # Interactive selection (Aptitude-style)
    function Show-InteractiveSelection {
        param(
            [Parameter(Mandatory=$true)]
            [array]$Items,
            
            [Parameter(Mandatory=$true)]
            [string]$Title,
            
            [Parameter(Mandatory=$false)]
            [bool]$AllSelectedByDefault = $true,
            
            [Parameter(Mandatory=$true)]
            [scriptblock]$DisplayItem
        )
        
        $selected = 0
        $marked = @{}
        
        # Инициализация
        for($i = 0; $i -lt $Items.Count; $i++) {
            $marked[$i] = $AllSelectedByDefault
        }
        
        $running = $true
        
        while($running) {
            Clear-Host
            Write-Host ""
            Write-Host $Title -ForegroundColor Cyan
            Write-Host ""
            
            for($i = 0; $i -lt $Items.Count; $i++) {
                # Cursor
                if($i -eq $selected) {
                    Write-Host "  ► " -NoNewline -ForegroundColor Cyan
                } else {
                    Write-Host "    " -NoNewline
                }
                
                # Marker
                if($marked[$i]) {
                    Write-Host "[+] " -NoNewline -ForegroundColor Green
                } else {
                    Write-Host "[ ] " -NoNewline -ForegroundColor DarkGray
                }
                
                # Отображение элемента через переданный scriptblock
                & $DisplayItem $Items[$i]
            }
            
            Write-Host ""
            $markedCount = ($marked.Values | Where-Object { $_ }).Count
            Write-Host "Selected: $markedCount of $($Items.Count)" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "Controls: " -NoNewline -ForegroundColor DarkGray
            Write-Host "↑/↓" -NoNewline -ForegroundColor Yellow
            Write-Host " navigate, " -NoNewline -ForegroundColor DarkGray
            Write-Host "+/-/Space" -NoNewline -ForegroundColor Yellow
            Write-Host " toggle, " -NoNewline -ForegroundColor DarkGray
            Write-Host "Enter" -NoNewline -ForegroundColor Yellow
            Write-Host " proceed, " -NoNewline -ForegroundColor DarkGray
            Write-Host "Q" -NoNewline -ForegroundColor Yellow
            Write-Host " quit" -ForegroundColor DarkGray
            
            # Wait for key press
            $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            
            switch($key.VirtualKeyCode) {
                38 { if($selected -gt 0) { $selected-- } }                    # Up
                40 { if($selected -lt $Items.Count - 1) { $selected++ } }     # Down
                32 { $marked[$selected] = -not $marked[$selected] }           # Space
                187 { $marked[$selected] = $true }                            # + (Shift)
                189 { $marked[$selected] = $false }                           # - (Shift)
                107 { $marked[$selected] = $true }                            # + (numpad)
                109 { $marked[$selected] = $false }                           # - (numpad)
                13 { Clear-Host; $running = $false }                          # Enter
                81 { Clear-Host; return $null }                               # Q
                27 { Clear-Host; return $null }                               # Escape
            }
        }
        
        # Return selected items
        $result = @()
        for($i = 0; $i -lt $Items.Count; $i++) {
            if($marked[$i]) {
                $result += $Items[$i]
            }
        }
        
        return $result
    }
    
    switch($command) {
        "status" {
            Write-Host "`nPackage Managers Status:" -ForegroundColor Cyan
            Write-Host ("=" * 60) -ForegroundColor DarkGray
            
            foreach($key in $managers.Keys | Sort-Object) {
                $m = $managers[$key]
                $isAvailable = $available[$key]
                
                if($isAvailable) {
                    $status = "Available"
                    $statusColor = "White"
                } else {
                    $status = "Not installed"
                    $statusColor = "Red"
                }
                
                Write-Host "$($m.Icon) " -NoNewline
                Write-Host ("{0,-25}" -f $m.Name) -NoNewline
                Write-Host " $status" -ForegroundColor $statusColor
                
                # Показываем версию если доступен
                if($isAvailable) {
                    $version = switch($key) {
                        "winget" { (winget --version 2>$null) -replace 'v' }
                        "choco"  { (choco --version 2>$null) }
                        "scoop"  { 
                            # Scoop выводит многострочный мусор, просто показываем что установлен
                            $null
                        }
                        "npm"    { (npm --version 2>$null) }
                        "pip"    { (pip --version 2>$null) -replace 'pip ([\d.]+).*','$1' }
                        "cargo"  { (cargo --version 2>$null) -replace 'cargo ' }
                        "dotnet" { (dotnet --version 2>$null) }
                        "vcpkg"  { (vcpkg version 2>$null) }
                        "pwsh"   { $PSVersionTable.PSVersion.ToString() }
                    }
                    if($version) {
                        Write-Host "   Version: $version" -ForegroundColor DarkGray
                    }
                }
            }
            
            Write-Host "`nSummary:" -ForegroundColor Cyan
            $availableCount = ($available.Values | Where-Object { $_ }).Count
            $totalCount = $managers.Count
            
            if($availableCount -eq $totalCount) {
                Write-Host "   All package managers installed! ($availableCount/$totalCount)" -ForegroundColor Green
            } else {
                $missingCount = $totalCount - $availableCount
                Write-Host "   Installed: $availableCount of $totalCount" -ForegroundColor Yellow
                Write-Host ""
                Write-Host "   Run " -NoNewline -ForegroundColor DarkGray
                Write-Host "uniget setup" -NoNewline -ForegroundColor Cyan
                Write-Host " to install $missingCount missing manager(s)" -ForegroundColor DarkGray
            }
        }
        
        "search" {
            if(-not $packages) {
                Write-Host "Specify package to search: uniget search <package>" -ForegroundColor Yellow
                return
            }
            
            foreach($pkg in $packages) {
                $searchStart = Get-Date
                Write-Host "`nSearching '$pkg'..." -ForegroundColor Cyan
                
                $searchJobs = @{}
                
                # Запускаем поиск параллельно для каждого менеджера
                if($available["winget"]) {
                    $searchJobs["winget"] = Start-Job -ScriptBlock {
                        param($pkg)
                        $result = winget search $pkg 2>$null | Out-String
                        if($LASTEXITCODE -eq 0 -and $result) {
                            $packages = @()
                            $lines = $result -split "`n"
                            $inResults = $false
                            
                            foreach($line in $lines) {
                                if($line -match '^Name\s+Id\s+Version') { 
                                    $inResults = $true
                                    continue 
                                }
                                if($inResults -and $line -match '\S') {
                                    # Parse: Name  Id  Version  Match  Source
                                    # Winget может показывать Match колонку (Command:, Tag:, Moniker:)
                                    if($line -match '^(.+?)\s{2,}(.+?)\s{2,}([\d\.]+)\s+(.+?)\s+(\w+)\s*$') {
                                        $packages += @{
                                            name = $matches[1].Trim()
                                            id = $matches[2].Trim()
                                            version = $matches[3].Trim()
                                            match = $matches[4].Trim()
                                        }
                                    }
                                    elseif($line -match '^(.+?)\s{2,}(.+?)\s{2,}([\d\.]+)') {
                                        $packages += @{
                                            name = $matches[1].Trim()
                                            id = $matches[2].Trim()
                                            version = $matches[3].Trim()
                                            match = $null
                                        }
                                    }
                                }
                            }
                            return @{found=$packages.Count -gt 0; packages=$packages}
                        }
                        return @{found=$false; packages=@()}
                    } -ArgumentList $pkg
                }
                
                if($available["choco"]) {
                    $searchJobs["choco"] = Start-Job -ScriptBlock {
                        param($pkg)
                        $result = choco search $pkg --limit-output 2>$null
                        if($result) {
                            $packages = @()
                            $lines = $result -split "`n" | Where-Object { $_ }
                            foreach($line in $lines) {
                                $parts = $line -split '\|'
                                if($parts.Length -ge 2) {
                                    $packages += @{
                                        name = $parts[0]
                                        version = $parts[1]
                                    }
                                }
                            }
                            return @{found=$packages.Count -gt 0; packages=$packages}
                        }
                        return @{found=$false; packages=@()}
                    } -ArgumentList $pkg
                }
                
                if($available["scoop"]) {
                    $searchJobs["scoop"] = Start-Job -ScriptBlock {
                        param($pkg)
                        $result = scoop search $pkg 2>$null | Out-String
                        if($LASTEXITCODE -eq 0 -and $result) {
                            $packages = @()
                            $lines = $result -split "`n"
                            foreach($line in $lines) {
                                # Format: 'bucket/package' (version)
                                if($line -match "'(\w+)/(.+?)'\s*\(([\d\.]+)\)") {
                                    $packages += @{
                                        name = $matches[2]
                                        bucket = $matches[1]
                                        version = $matches[3]
                                    }
                                }
                            }
                            return @{found=$packages.Count -gt 0; packages=$packages}
                        }
                        return @{found=$false; packages=@()}
                    } -ArgumentList $pkg
                }
                
                if($available["npm"]) {
                    $searchJobs["npm"] = Start-Job -ScriptBlock {
                        param($pkg)
                        try {
                            $result = npm search $pkg --json --no-description 2>$null | ConvertFrom-Json
                            if($result -and $result.Count -gt 0) {
                                $packages = @()
                                foreach($item in $result | Select-Object -First 20) {
                                    $packages += @{
                                        name = $item.name
                                        version = $item.version
                                    }
                                }
                                return @{found=$true; packages=$packages}
                            }
                        } catch {}
                        return @{found=$false; packages=@()}
                    } -ArgumentList $pkg
                }
                
                if($available["pip"]) {
                    $searchJobs["pip"] = Start-Job -ScriptBlock {
                        param($pkg)
                        try {
                            # PyPI search API
                            $response = Invoke-RestMethod "https://pypi.org/search/?q=$pkg&format=json" -ErrorAction Stop -TimeoutSec 10
                            if($response.results) {
                                $packages = @()
                                foreach($item in $response.results | Select-Object -First 20) {
                                    $packages += @{
                                        name = $item.name
                                        version = $item.version
                                    }
                                }
                                return @{found=$true; packages=$packages}
                            }
                        } catch {}
                        return @{found=$false; packages=@()}
                    } -ArgumentList $pkg
                }
                
                if($available["cargo"]) {
                    $searchJobs["cargo"] = Start-Job -ScriptBlock {
                        param($pkg)
                        $result = cargo search $pkg --limit 20 2>$null | Out-String
                        if($LASTEXITCODE -eq 0 -and $result) {
                            $packages = @()
                            $lines = $result -split "`n"
                            foreach($line in $lines) {
                                # Format: package = "version"
                                if($line -match '^(\S+)\s*=\s*"([\d\.]+)"') {
                                    $packages += @{
                                        name = $matches[1]
                                        version = $matches[2]
                                    }
                                }
                            }
                            return @{found=$packages.Count -gt 0; packages=$packages}
                        }
                        return @{found=$false; packages=@()}
                    } -ArgumentList $pkg
                }
                
                if($available["dotnet"]) {
                    $searchJobs["dotnet"] = Start-Job -ScriptBlock {
                        param($pkg)
                        $result = dotnet tool search $pkg --take 20 2>$null | Out-String
                        if($LASTEXITCODE -eq 0 -and $result) {
                            $packages = @()
                            $lines = $result -split "`n"
                            foreach($line in $lines) {
                                # Parse table output
                                if($line -match '^(\S+)\s+([\d\.]+)') {
                                    $packages += @{
                                        name = $matches[1]
                                        version = $matches[2]
                                    }
                                }
                            }
                            return @{found=$packages.Count -gt 0; packages=$packages}
                        }
                        return @{found=$false; packages=@()}
                    } -ArgumentList $pkg
                }
                
                if($available["pwsh"]) {
                    $searchJobs["pwsh"] = Start-Job -ScriptBlock {
                        param($pkg)
                        try {
                            $result = Find-Module "*$pkg*" -ErrorAction Stop | Select-Object -First 20
                            if($result) {
                                $packages = @()
                                foreach($item in $result) {
                                    $packages += @{
                                        name = $item.Name
                                        version = $item.Version.ToString()
                                    }
                                }
                                return @{found=$true; packages=$packages}
                            }
                        } catch {}
                        return @{found=$false; packages=@()}
                    } -ArgumentList $pkg
                }
                
                # Ждём завершения с постепенным выводом
                $jobArray = @($searchJobs.Values)
                if($jobArray.Count -gt 0) {
                    Write-Host ""
                    
                    $allPackages = @()
                    $startTime = Get-Date
                    $timeout = 15
                    $completedManagers = @()
                    $searchStatus = ""
                    
                    # Собираем все результаты
                    while ($jobArray.Count -gt 0) {
                        $elapsed = ((Get-Date) - $startTime).TotalSeconds
                        if($elapsed -gt $timeout) {
                            $jobArray | Stop-Job
                            break
                        }
                        
                        $completedJobs = $jobArray | Where-Object { $_.State -eq "Completed" }
                        
                        foreach($job in $completedJobs) {
                            $mgr = $searchJobs.Keys | Where-Object { $searchJobs[$_].Id -eq $job.Id } | Select-Object -First 1
                            
                            if($mgr) {
                                # Добавляем в список завершённых
                                if(-not $completedManagers.Contains($mgr)) {
                                    $completedManagers += $mgr
                                }
                                
                                $jobResult = Receive-Job -Job $job
                                if($jobResult.found -and $jobResult.packages.Count -gt 0) {
                                    foreach($p in $jobResult.packages) {
                                        $pkgId = if($p.id) { $p.id } else { $p.name }
                                        
                                        $match = ""
                                        if($p.match) {
                                            $match = $p.match
                                        } elseif($pkgId -eq $pkg -or $p.name -eq $pkg) {
                                            $match = ""
                                        } else {
                                            $match = "Name"
                                        }
                                        
                                        $allPackages += [PSCustomObject]@{
                                            Package = $pkgId
                                            Version = $p.version
                                            Match = $match
                                            Source = $mgr
                                        }
                                    }
                                }
                                Remove-Job -Job $job -Force
                            }
                            
                            $jobArray = $jobArray | Where-Object { $_.Id -ne $job.Id }
                        }
                        
                        # Обновляем статус поиска
                        $statusParts = @()
                        foreach($mgr in $completedManagers) {
                            $statusParts += $mgr
                        }
                        
                        # Показываем активные
                        $active = $searchJobs.Keys | Where-Object { -not $completedManagers.Contains($_) -and $jobArray.Id -contains $searchJobs[$_].Id }
                        foreach($mgr in $active) {
                            $statusParts += "$mgr..."
                        }
                        
                        if($statusParts.Count -gt 0) {
                            $percent = [Math]::Min(($completedManagers.Count / $searchJobs.Count) * 100, 99)
                            Write-Progress -Activity "Searching '$pkg'" -Status ($statusParts -join ", ") -PercentComplete $percent
                        }
                        
                        if($jobArray.Count -gt 0) {
                            Start-Sleep -Milliseconds 200
                        }
                    }
                    
                    # Завершаем прогресс
                    Write-Progress -Activity "Searching '$pkg'" -Completed
                    
                    # Показываем итоговый статус
                    Write-Host "Searched in: " -NoNewline -ForegroundColor Cyan
                    foreach($mgr in $searchJobs.Keys | Sort-Object) {
                        $m = $managers[$mgr]
                        $nbsp = [char]0x00A0
                        if($completedManagers.Contains($mgr)) {
                            Write-Host "$($m.Icon)$nbsp$mgr " -NoNewline
                        } else {
                            Write-Host "$($m.Icon)$nbsp$mgr(timeout) " -NoNewline -ForegroundColor Yellow
                        }
                    }
                    Write-Host ""
                    
                    $jobArray | Stop-Job -PassThru | Remove-Job -Force
                    Write-Host ""
                    
                    # Вычисляем оптимальную ширину колонок
                    if($allPackages.Count -gt 0) {
                        $maxPkgLen = ($allPackages | ForEach-Object { $_.Package.Length } | Measure-Object -Maximum).Maximum
                        $maxVerLen = ($allPackages | ForEach-Object { $_.Version.Length } | Measure-Object -Maximum).Maximum
                        $maxMatchLen = ($allPackages | ForEach-Object { $_.Match.Length } | Measure-Object -Maximum).Maximum
                        
                        # НЕ обрезаем Package - пусть разъезжается
                        $pkgWidth = [Math]::Max($maxPkgLen, 7)
                        $verWidth = [Math]::Max($maxVerLen, 7)
                        $matchWidth = [Math]::Max($maxMatchLen, 5)
                        
                        # Заголовок
                        Write-Host "Package".PadRight($pkgWidth) -NoNewline -ForegroundColor Cyan
                        Write-Host " " -NoNewline
                        Write-Host "Version".PadRight($verWidth) -NoNewline -ForegroundColor Cyan
                        Write-Host " " -NoNewline
                        Write-Host "Match".PadRight($matchWidth) -NoNewline -ForegroundColor Cyan
                        Write-Host " Source" -ForegroundColor Cyan
                        
                        Write-Host ("-" * $pkgWidth) -NoNewline -ForegroundColor DarkGray
                        Write-Host " " -NoNewline
                        Write-Host ("-" * $verWidth) -NoNewline -ForegroundColor DarkGray
                        Write-Host " " -NoNewline
                        Write-Host ("-" * $matchWidth) -NoNewline -ForegroundColor DarkGray
                        Write-Host " ------" -ForegroundColor DarkGray
                        
                        # Строки - БЕЗ обрезки
                        foreach($p in $allPackages) {
                            Write-Host $p.Package.PadRight($pkgWidth) -NoNewline -ForegroundColor White
                            Write-Host " " -NoNewline
                            Write-Host $p.Version.PadRight($verWidth) -NoNewline -ForegroundColor White
                            Write-Host " " -NoNewline
                            Write-Host $p.Match.PadRight($matchWidth) -NoNewline -ForegroundColor $(if($p.Match){"DarkGray"}else{"White"})
                            Write-Host " " -NoNewline
                            Write-Host $p.Source -ForegroundColor White
                        }
                    }
                    
                    Write-Host ""
                    
                    # Показываем предупреждение если нет точных совпадений
                    $exactMatches = $allPackages | Where-Object { -not $_.Match }
                    if($exactMatches.Count -eq 0 -and $allPackages.Count -gt 0) {
                        Write-Host "WARN  No exact matches found. Showing similar packages." -ForegroundColor Yellow
                    }
                    
                    # Итоговая статистика
                    $searchTime = ((Get-Date) - $searchStart).TotalSeconds
                    if($allPackages.Count -eq 0) {
                        Write-Host "No packages found (${searchTime}s)" -ForegroundColor Red
                    } else {
                        Write-Host "Found $($allPackages.Count) package(s) in $([Math]::Round($searchTime, 1))s" -ForegroundColor Green
                    }
                }
            }
        }
        
        "install" {
            if(-not $packages) {
                Write-Host "Specify package to install: uniget install <package>" -ForegroundColor Yellow
                return
            }
            
            foreach($pkg in $packages) {
                Write-Host "`nInstalling '$pkg'..." -ForegroundColor Cyan
                $installed = $false
                
                # Приоритет: winget > choco > scoop > остальные
                $priority = @("winget", "choco", "scoop", "npm", "pip", "cargo", "dotnet", "vcpkg", "pwsh")
                
                foreach($mgr in $priority) {
                    if(-not $available[$mgr]) { continue }
                    
                    $canInstall = $false
                    
                    # Проверяем наличие пакета
                    switch($mgr) {
                        "winget" { 
                            $result = winget search $pkg --exact 2>$null
                            $canInstall = ($LASTEXITCODE -eq 0 -and $result)
                        }
                        "choco" { 
                            $result = choco search $pkg --exact --limit-output 2>$null
                            $canInstall = ($result -match $pkg)
                        }
                        "scoop" { 
                            $result = scoop search $pkg 2>$null
                            $canInstall = ($LASTEXITCODE -eq 0 -and $result)
                        }
                        "npm" { 
                            $result = npm view $pkg version 2>$null
                            $canInstall = ($LASTEXITCODE -eq 0)
                        }
                        "pip" { 
                            try {
                                $response = Invoke-RestMethod "https://pypi.org/pypi/$pkg/json" -ErrorAction Stop
                                $canInstall = $true
                            } catch { $canInstall = $false }
                        }
                        "cargo" { 
                            $result = cargo search $pkg --limit 1 2>$null
                            $canInstall = ($LASTEXITCODE -eq 0 -and $result)
                        }
                        "dotnet" { 
                            $result = dotnet tool search $pkg --take 1 2>$null
                            $canInstall = ($LASTEXITCODE -eq 0 -and $result -match $pkg)
                        }
                        "vcpkg" { 
                            $result = vcpkg search $pkg 2>$null
                            $canInstall = ($LASTEXITCODE -eq 0 -and $result -match $pkg)
                        }
                        "pwsh" { 
                            $result = Find-Module $pkg -ErrorAction SilentlyContinue
                            $canInstall = ($null -ne $result)
                        }
                    }
                    
                    if($canInstall) {
                        Write-Host "  Found in $mgr, installing..." -ForegroundColor Yellow
                        
                        switch($mgr) {
                            "winget" { winget install $pkg --exact --silent --accept-package-agreements --accept-source-agreements }
                            "choco"  { choco install $pkg -y }
                            "scoop"  { scoop install $pkg }
                            "npm"    { npm install -g $pkg }
                            "pip"    { pip install $pkg }
                            "cargo"  { cargo install $pkg }
                            "dotnet" { dotnet tool install --global $pkg }
                            "vcpkg"  { vcpkg install $pkg }
                            "pwsh"   { Install-Module $pkg -Scope CurrentUser -Force }
                        }
                        
                        if($LASTEXITCODE -eq 0 -or $?) {
                            Write-Host "  Successfully installed via $mgr" -ForegroundColor Green
                            $installed = $true
                            break
                        } else {
                            Write-Host "  Failed via $mgr, trying next..." -ForegroundColor Yellow
                        }
                    }
                }
                
                if(-not $installed) {
                    Write-Host "  Failed to install '$pkg' via any manager" -ForegroundColor Red
                }
            }
        }
        
        "list" {
            Write-Host "`nListing installed packages..." -ForegroundColor Cyan
            
            $allInstalled = @()
            $managers = @("winget", "choco", "scoop", "npm", "pip", "cargo", "dotnet", "pwsh")
            $completed = 0
            
            # winget
            if($available["winget"]) {
                Write-Progress -Activity "Listing packages" -Status "winget..." -PercentComplete (($completed / $managers.Count) * 100)
                $result = winget list 2>$null | Out-String
                if($result) {
                    $lines = $result -split "`n"
                    $inList = $false
                    foreach($line in $lines) {
                        if($line -match '^Name\s+Id\s+Version') {
                            $inList = $true
                            continue
                        }
                        if($inList -and $line -match '\S') {
                            # Winget format: Name  Id  Version  Available  Source
                            # Берём ID как Package (потому что Name часто пустое)
                            if($line -match '^\s*(.+?)\s{2,}(.+?)\s{2,}([\S]+)') {
                                $pkgId = $matches[2].Trim()
                                $version = $matches[3].Trim()
                                
                                # Пропускаем если ID пустой или это мусор
                                if($pkgId -and $pkgId.Length -gt 0) {
                                    $allInstalled += [PSCustomObject]@{
                                        Package = $pkgId
                                        Version = $version
                                        Source = "winget"
                                    }
                                }
                            }
                        }
                    }
                }
                $completed++
            }
            
            # choco
            if($available["choco"]) {
                Write-Progress -Activity "Listing packages" -Status "choco..." -PercentComplete (($completed / $managers.Count) * 100)
                $result = choco list --local-only --limit-output 2>$null
                if($result) {
                    foreach($line in $result -split "`n") {
                        if($line -match '^(.+?)\|(.+)$') {
                            $allInstalled += [PSCustomObject]@{
                                Package = $matches[1]
                                Version = $matches[2]
                                Source = "choco"
                            }
                        }
                    }
                }
                $completed++
            }
            
            # scoop
            if($available["scoop"]) {
                Write-Progress -Activity "Listing packages" -Status "scoop..." -PercentComplete (($completed / $managers.Count) * 100)
                $result = scoop list 2>$null | Out-String
                if($result) {
                    $lines = $result -split "`n"
                    foreach($line in $lines) {
                        if($line -match '^\s*(\S+)\s+([\d\.]+)') {
                            $allInstalled += [PSCustomObject]@{
                                Package = $matches[1]
                                Version = $matches[2]
                                Source = "scoop"
                            }
                        }
                    }
                }
                $completed++
            }
            
            # npm
            if($available["npm"]) {
                Write-Progress -Activity "Listing packages" -Status "npm..." -PercentComplete (($completed / $managers.Count) * 100)
                $result = npm list -g --depth=0 --json 2>$null | ConvertFrom-Json
                if($result.dependencies) {
                    foreach($pkg in $result.dependencies.PSObject.Properties) {
                        $allInstalled += [PSCustomObject]@{
                            Package = $pkg.Name
                            Version = $pkg.Value.version
                            Source = "npm"
                        }
                    }
                }
                $completed++
            }
            
            # pip
            if($available["pip"]) {
                Write-Progress -Activity "Listing packages" -Status "pip..." -PercentComplete (($completed / $managers.Count) * 100)
                $result = pip list --format=freeze 2>$null
                if($result) {
                    foreach($line in $result -split "`n") {
                        if($line -match '^(.+)==(.+)$') {
                            $allInstalled += [PSCustomObject]@{
                                Package = $matches[1]
                                Version = $matches[2]
                                Source = "pip"
                            }
                        }
                    }
                }
                $completed++
            }
            
            # cargo
            if($available["cargo"]) {
                Write-Progress -Activity "Listing packages" -Status "cargo..." -PercentComplete (($completed / $managers.Count) * 100)
                $result = cargo install --list 2>$null | Out-String
                if($result) {
                    $lines = $result -split "`n"
                    foreach($line in $lines) {
                        if($line -match '^(\S+) v([\d\.]+)') {
                            $allInstalled += [PSCustomObject]@{
                                Package = $matches[1]
                                Version = $matches[2]
                                Source = "cargo"
                            }
                        }
                    }
                }
                $completed++
            }
            
            # dotnet
            if($available["dotnet"]) {
                Write-Progress -Activity "Listing packages" -Status "dotnet..." -PercentComplete (($completed / $managers.Count) * 100)
                $result = dotnet tool list -g 2>$null | Out-String
                if($result) {
                    $lines = $result -split "`n"
                    foreach($line in $lines) {
                        if($line -match '^(\S+)\s+([\d\.]+)') {
                            $allInstalled += [PSCustomObject]@{
                                Package = $matches[1]
                                Version = $matches[2]
                                Source = "dotnet"
                            }
                        }
                    }
                }
                $completed++
            }
            
            # pwsh
            if($available["pwsh"]) {
                Write-Progress -Activity "Listing packages" -Status "pwsh..." -PercentComplete (($completed / $managers.Count) * 100)
                $modules = Get-InstalledModule -ErrorAction SilentlyContinue
                if($modules) {
                    foreach($mod in $modules) {
                        $allInstalled += [PSCustomObject]@{
                            Package = $mod.Name
                            Version = $mod.Version.ToString()
                            Source = "pwsh"
                        }
                    }
                }
                $completed++
            }
            
            Write-Progress -Activity "Listing packages" -Completed
            Write-Host ""
            
            if($allInstalled.Count -eq 0) {
                Write-Host "No packages found" -ForegroundColor Red
            } else {
                # Вычисляем ширину колонок
                $maxPkgLen = ($allInstalled | ForEach-Object { $_.Package.Length } | Measure-Object -Maximum).Maximum
                $maxVerLen = ($allInstalled | ForEach-Object { $_.Version.Length } | Measure-Object -Maximum).Maximum
                $pkgWidth = [Math]::Max($maxPkgLen, 7)
                $verWidth = [Math]::Max($maxVerLen, 7)
                
                # Заголовок
                Write-Host "Package".PadRight($pkgWidth) -NoNewline -ForegroundColor Cyan
                Write-Host " " -NoNewline
                Write-Host "Version".PadRight($verWidth) -NoNewline -ForegroundColor Cyan
                Write-Host " Source" -ForegroundColor Cyan
                
                Write-Host ("-" * $pkgWidth) -NoNewline -ForegroundColor DarkGray
                Write-Host " " -NoNewline
                Write-Host ("-" * $verWidth) -NoNewline -ForegroundColor DarkGray
                Write-Host " ------" -ForegroundColor DarkGray
                
                # Строки
                foreach($p in $allInstalled | Sort-Object Source, Package) {
                    Write-Host $p.Package.PadRight($pkgWidth) -NoNewline
                    Write-Host " " -NoNewline
                    Write-Host $p.Version.PadRight($verWidth) -NoNewline
                    Write-Host " $($p.Source)"
                }
                
                Write-Host ""
                Write-Host "Total: $($allInstalled.Count) package(s)" -ForegroundColor Green
            }
        }
        
        "update" {
    if($packages -and $packages.Count -gt 0) {
        foreach($pkg in $packages) {
            Write-Host "`nUpdating '$pkg'..." -ForegroundColor Cyan
            $updated = $false
            
            if($available["winget"]) {
                $result = winget list --exact $pkg 2>$null
                if($result -match $pkg) {
                    Write-Host "  Updating in winget..." -ForegroundColor Yellow
                    winget upgrade $pkg --exact --silent --accept-package-agreements --accept-source-agreements
                    if($LASTEXITCODE -eq 0) { 
                        Write-Host "  Updated" -ForegroundColor Green
                        $updated = $true
                    }
                }
            }
            
            if($available["choco"]) {
                $result = choco list --local-only --exact $pkg 2>$null
                if($result -match $pkg) {
                    Write-Host "  Updating in choco..." -ForegroundColor Yellow
                    choco upgrade $pkg -y
                    if($LASTEXITCODE -eq 0) { 
                        Write-Host "  Updated" -ForegroundColor Green
                        $updated = $true
                    }
                }
            }
            
            if($available["scoop"]) {
                $result = scoop list $pkg 2>$null
                if($result -match $pkg) {
                    Write-Host "  Updating in scoop..." -ForegroundColor Yellow
                    scoop update $pkg
                    if($LASTEXITCODE -eq 0) { 
                        Write-Host "  Updated" -ForegroundColor Green
                        $updated = $true
                    }
                }
            }
            
            if($available["npm"]) {
                $result = npm list -g $pkg --depth=0 2>$null
                if($result -match $pkg) {
                    Write-Host "  Updating in npm..." -ForegroundColor Yellow
                    npm update -g $pkg
                    if($LASTEXITCODE -eq 0) { 
                        Write-Host "  Updated" -ForegroundColor Green
                        $updated = $true
                    }
                }
            }
            
            if($available["pip"]) {
                $result = pip show $pkg 2>$null
                if($result) {
                    Write-Host "  Updating in pip..." -ForegroundColor Yellow
                    pip install --upgrade $pkg
                    if($LASTEXITCODE -eq 0) { 
                        Write-Host "  Updated" -ForegroundColor Green
                        $updated = $true
                    }
                }
            }
            
            if($available["cargo"]) {
                $result = cargo install --list 2>$null | Select-String $pkg
                if($result) {
                    Write-Host "  Updating in cargo..." -ForegroundColor Yellow
                    cargo install $pkg --force
                    if($LASTEXITCODE -eq 0) { 
                        Write-Host "  Updated" -ForegroundColor Green
                        $updated = $true
                    }
                }
            }
            
            if($available["dotnet"]) {
                $result = dotnet tool list -g 2>$null | Select-String $pkg
                if($result) {
                    Write-Host "  Updating in dotnet..." -ForegroundColor Yellow
                    dotnet tool update --global $pkg
                    if($LASTEXITCODE -eq 0) { 
                        Write-Host "  Updated" -ForegroundColor Green
                        $updated = $true
                    }
                }
            }
            
            if(-not $updated) {
                Write-Host "  Package not found" -ForegroundColor Red
            }
        }
    } else {
        # Интерактивное обновление (AUR-style)
        Write-Host "`nChecking for updates..." -ForegroundColor Cyan
        
        $allOutdated = @()
        $managers = @("winget", "choco", "scoop", "npm", "pip")
        $completed = 0
        
        # Collect updates из всех менеджеров
        if($available["winget"]) {
            Write-Progress -Activity "Checking for updates" -Status "winget..." -PercentComplete (($completed / $managers.Count) * 100)
            $result = winget upgrade 2>$null | Out-String
            if($result) {
                $lines = $result -split "`n"
                $inList = $false
                foreach($line in $lines) {
                    if($line -match '^Name\s+Id\s+Version\s+Available') {
                        $inList = $true
                        continue
                    }
                    if($inList -and $line -match '\S' -and $line -notmatch 'upgrades available') {
                        if($line -match '^(.+?)\s{2,}(.+?)\s{2,}([\S]+)\s{2,}([\S]+)') {
                            $allOutdated += [PSCustomObject]@{
                                Package = $matches[2].Trim()
                                Current = $matches[3].Trim()
                                Available = $matches[4].Trim()
                                Source = "winget"
                            }
                        }
                    }
                }
            }
            $completed++
        }
        
        if($available["choco"]) {
            Write-Progress -Activity "Checking for updates" -Status "choco..." -PercentComplete (($completed / $managers.Count) * 100)
            $result = choco outdated --limit-output 2>$null
            if($result) {
                foreach($line in $result -split "`n") {
                    if($line -match '^(.+?)\|(.+?)\|(.+?)\|') {
                        $allOutdated += [PSCustomObject]@{
                            Package = $matches[1]
                            Current = $matches[2]
                            Available = $matches[3]
                            Source = "choco"
                        }
                    }
                }
            }
            $completed++
        }
        
        if($available["scoop"]) {
            Write-Progress -Activity "Checking for updates" -Status "scoop..." -PercentComplete (($completed / $managers.Count) * 100)
            $result = scoop status 2>$null | Out-String
            if($result -match 'Updates are available') {
                $lines = $result -split "`n"
                foreach($line in $lines) {
                    if($line -match '^\s*(\S+):\s*([\d\.]+)\s*->\s*([\d\.]+)') {
                        $allOutdated += [PSCustomObject]@{
                            Package = $matches[1]
                            Current = $matches[2]
                            Available = $matches[3]
                            Source = "scoop"
                        }
                    }
                }
            }
            $completed++
        }
        
        if($available["npm"]) {
            Write-Progress -Activity "Checking for updates" -Status "npm..." -PercentComplete (($completed / $managers.Count) * 100)
            $result = npm outdated -g --json 2>$null | ConvertFrom-Json
            if($result) {
                foreach($pkg in $result.PSObject.Properties) {
                    $allOutdated += [PSCustomObject]@{
                        Package = $pkg.Name
                        Current = $pkg.Value.current
                        Available = $pkg.Value.latest
                        Source = "npm"
                    }
                }
            }
            $completed++
        }
        
        if($available["pip"]) {
            Write-Progress -Activity "Checking for updates" -Status "pip..." -PercentComplete (($completed / $managers.Count) * 100)
            $result = pip list --outdated --format=freeze 2>$null
            if($result) {
                foreach($line in $result -split "`n") {
                    if($line -match '^(.+)==(.+)') {
                        $allOutdated += [PSCustomObject]@{
                            Package = $matches[1]
                            Current = $matches[2]
                            Available = "newer"
                            Source = "pip"
                        }
                    }
                }
            }
        }
        
        Write-Progress -Activity "Checking for updates" -Completed
        Write-Host ""
        
        if($allOutdated.Count -eq 0) {
            Write-Host "All packages are up to date" -ForegroundColor Green
            return
        }
        
        # Показываем список обновлений
        Write-Host "Packages to update:" -ForegroundColor Cyan
        Write-Host ""
        
        foreach($p in $allOutdated) {
            Write-Host "  $($p.Package) " -NoNewline -ForegroundColor White
            Write-Host "$($p.Current) " -NoNewline -ForegroundColor DarkGray
            Write-Host "-> " -NoNewline -ForegroundColor Yellow
            Write-Host "$($p.Available) " -NoNewline -ForegroundColor Yellow
            Write-Host "[$($p.Source)]" -ForegroundColor DarkGray
        }
        
        Write-Host ""
        
        # Интерактивный выбор пакетов
        $toUpdate = Show-InteractiveSelection `
            -Items $allOutdated `
            -Title "Packages to update (use +/- to select, Enter to proceed):" `
            -AllSelectedByDefault $true `
            -DisplayItem {
                param($p)
                Write-Host "$($p.Package) " -NoNewline -ForegroundColor White
                Write-Host "$($p.Current) " -NoNewline -ForegroundColor DarkGray
                Write-Host "-> " -NoNewline -ForegroundColor Yellow
                Write-Host "$($p.Available) " -NoNewline -ForegroundColor Yellow
                Write-Host "[$($p.Source)]" -ForegroundColor DarkGray
            }
        
        if(-not $toUpdate -or $toUpdate.Count -eq 0) {
            Write-Host ""
            Write-Host "No packages selected" -ForegroundColor Yellow
            Write-Host ""
            return
        }
        
        Write-Host ""
        Write-Host ":: " -NoNewline -ForegroundColor Cyan
        Write-Host "Updating $($toUpdate.Count) package(s)..." -ForegroundColor White
        Write-Host ""
        
        foreach($p in $toUpdate) {
            Write-Host ":: " -NoNewline -ForegroundColor Cyan
            Write-Host "Updating $($p.Package) [$($p.Source)]..." -ForegroundColor White
            
            switch($p.Source) {
                "winget" { 
                    winget upgrade $p.Package --exact --silent --accept-package-agreements --accept-source-agreements 2>&1 | Out-Null
                    if($LASTEXITCODE -eq 0) { Write-Host "   Done" -ForegroundColor Green }
                }
                "choco" { 
                    choco upgrade $p.Package -y 2>&1 | Out-Null
                    if($LASTEXITCODE -eq 0) { Write-Host "   Done" -ForegroundColor Green }
                }
                "scoop" { 
                    scoop update $p.Package 2>&1 | Out-Null
                    if($LASTEXITCODE -eq 0) { Write-Host "   Done" -ForegroundColor Green }
                }
                "npm" { 
                    npm update -g $p.Package 2>&1 | Out-Null
                    if($LASTEXITCODE -eq 0) { Write-Host "   Done" -ForegroundColor Green }
                }
                "pip" { 
                    pip install --upgrade $p.Package 2>&1 | Out-Null
                    if($LASTEXITCODE -eq 0) { Write-Host "   Done" -ForegroundColor Green }
                }
                "cargo" { 
                    cargo install $p.Package --force 2>&1 | Out-Null
                    if($LASTEXITCODE -eq 0) { Write-Host "   Done" -ForegroundColor Green }
                }
                "dotnet" { 
                    dotnet tool update --global $p.Package 2>&1 | Out-Null
                    if($LASTEXITCODE -eq 0) { Write-Host "   Done" -ForegroundColor Green }
                }
            }
        }
        
        Write-Host ""
        Write-Host ":: " -NoNewline -ForegroundColor Cyan
        Write-Host "Update complete" -ForegroundColor Green
    }
}
        "uninstall" {
            if(-not $packages) {
                Write-Host "Specify package to uninstall: uniget uninstall <package>" -ForegroundColor Yellow
                return
            }
            
            foreach($pkg in $packages) {
                Write-Host "`nUninstalling '$pkg'..." -ForegroundColor Cyan
                $removed = $false
                
                # Пробуем удалить из всех менеджеров
                if($available["winget"]) {
                    $result = winget list --exact $pkg 2>$null
                    if($result -match $pkg) {
                        Write-Host "  Removing from winget..." -ForegroundColor Yellow
                        winget uninstall $pkg --silent
                        if($LASTEXITCODE -eq 0) { 
                            Write-Host "  Removed from winget" -ForegroundColor Green
                            $removed = $true
                        }
                    }
                }
                
                if($available["choco"]) {
                    $result = choco list --local-only --exact $pkg 2>$null
                    if($result -match $pkg) {
                        Write-Host "  Removing from choco..." -ForegroundColor Yellow
                        choco uninstall $pkg -y
                        if($LASTEXITCODE -eq 0) { 
                            Write-Host "  Removed from choco" -ForegroundColor Green
                            $removed = $true
                        }
                    }
                }
                
                if($available["scoop"]) {
                    $result = scoop list $pkg 2>$null
                    if($result -match $pkg) {
                        Write-Host "  Removing from scoop..." -ForegroundColor Yellow
                        scoop uninstall $pkg
                        if($LASTEXITCODE -eq 0) { 
                            Write-Host "  Removed from scoop" -ForegroundColor Green
                            $removed = $true
                        }
                    }
                }
                
                if($available["npm"]) {
                    $result = npm list -g $pkg --depth=0 2>$null
                    if($result -match $pkg) {
                        Write-Host "  Removing from npm..." -ForegroundColor Yellow
                        npm uninstall -g $pkg
                        if($LASTEXITCODE -eq 0) { 
                            Write-Host "  Removed from npm" -ForegroundColor Green
                            $removed = $true
                        }
                    }
                }
                
                if($available["pip"]) {
                    $result = pip show $pkg 2>$null
                    if($result) {
                        Write-Host "  Removing from pip..." -ForegroundColor Yellow
                        pip uninstall $pkg -y
                        if($LASTEXITCODE -eq 0) { 
                            Write-Host "  Removed from pip" -ForegroundColor Green
                            $removed = $true
                        }
                    }
                }
                
                if($available["cargo"]) {
                    $result = cargo install --list 2>$null | Select-String $pkg
                    if($result) {
                        Write-Host "  Removing from cargo..." -ForegroundColor Yellow
                        cargo uninstall $pkg
                        if($LASTEXITCODE -eq 0) { 
                            Write-Host "  Removed from cargo" -ForegroundColor Green
                            $removed = $true
                        }
                    }
                }
                
                if($available["dotnet"]) {
                    $result = dotnet tool list -g 2>$null | Select-String $pkg
                    if($result) {
                        Write-Host "  Removing from dotnet..." -ForegroundColor Yellow
                        dotnet tool uninstall --global $pkg
                        if($LASTEXITCODE -eq 0) { 
                            Write-Host "  Removed from dotnet" -ForegroundColor Green
                            $removed = $true
                        }
                    }
                }
                
                if($available["pwsh"]) {
                    $result = Get-Module -ListAvailable $pkg -ErrorAction SilentlyContinue
                    if($result) {
                        Write-Host "  Removing from pwsh..." -ForegroundColor Yellow
                        Uninstall-Module $pkg -Force -ErrorAction SilentlyContinue
                        if($?) { 
                            Write-Host "  Removed from pwsh" -ForegroundColor Green
                            $removed = $true
                        }
                    }
                }
                
                if(-not $removed) {
                    Write-Host "  Package '$pkg' not found in any manager" -ForegroundColor Red
                }
            }
        }
        
        "config" {
            Write-Host "`nPackage Manager Configuration" -ForegroundColor Cyan
            Write-Host ""
            
            # Создаём изменяемый массив менеджеров с их приоритетами
            $managerList = @()
            foreach($key in $managers.Keys) {
                $managerList += [PSCustomObject]@{
                    Key = $key
                    Name = $managers[$key].Name
                    Icon = $managers[$key].Icon
                    Available = $available[$key]
                }
            }
            
            # Сортируем по приоритету (winget=1, choco=2, ...)
            $priorityOrder = @("winget", "choco", "scoop", "npm", "pip", "cargo", "dotnet", "vcpkg", "pwsh")
            $managerList = $managerList | Sort-Object { $priorityOrder.IndexOf($_.Key) }
            
            $selected = 0
            $running = $true
            
            while($running) {
                Clear-Host
                Write-Host "`nPackage Manager Priority Configuration" -ForegroundColor Cyan
                Write-Host ""
                Write-Host "Use " -NoNewline
                Write-Host "↑/↓" -NoNewline -ForegroundColor Yellow
                Write-Host " to select, " -NoNewline
                Write-Host "PgUp/PgDn" -NoNewline -ForegroundColor Yellow
                Write-Host " to move, " -NoNewline
                Write-Host "Enter" -NoNewline -ForegroundColor Yellow
                Write-Host " to save, " -NoNewline
                Write-Host "Q" -NoNewline -ForegroundColor Yellow
                Write-Host " to quit"
                Write-Host ""
                Write-Host "Priority (higher = preferred for install):" -ForegroundColor DarkGray
                Write-Host ""
                
                for($i = 0; $i -lt $managerList.Count; $i++) {
                    $m = $managerList[$i]
                    $priority = $i + 1  # 1 = highest priority
                    
                    if($i -eq $selected) {
                        Write-Host "  ► " -NoNewline -ForegroundColor Cyan
                    } else {
                        Write-Host "    " -NoNewline
                    }
                    
                    Write-Host "$priority. " -NoNewline -ForegroundColor Yellow
                    Write-Host "$($m.Icon) " -NoNewline
                    Write-Host ("{0,-30}" -f $m.Name) -NoNewline
                    
                    if($m.Available) {
                        Write-Host " [Installed]" -ForegroundColor Green
                    } else {
                        Write-Host " [Not installed]" -ForegroundColor DarkGray
                    }
                }
                
                Write-Host ""
                Write-Host "Lower number = checked first" -ForegroundColor DarkGray
                
                # Wait for key press
                $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                
                switch($key.VirtualKeyCode) {
                    38 { # Up arrow
                        if($selected -gt 0) { $selected-- }
                    }
                    40 { # Down arrow
                        if($selected -lt $managerList.Count - 1) { $selected++ }
                    }
                    33 { # Page Up - move selected item up
                        if($selected -gt 0) {
                            $temp = $managerList[$selected]
                            $managerList[$selected] = $managerList[$selected - 1]
                            $managerList[$selected - 1] = $temp
                            $selected--
                        }
                    }
                    34 { # Page Down - move selected item down
                        if($selected -lt $managerList.Count - 1) {
                            $temp = $managerList[$selected]
                            $managerList[$selected] = $managerList[$selected + 1]
                            $managerList[$selected + 1] = $temp
                            $selected++
                        }
                    }
                    13 { # Enter - save and exit
                        Clear-Host
                        Write-Host ""
                        Write-Host "Saving configuration..." -ForegroundColor Cyan
                        
                        # Обновляем приоритеты в хардкоде (в идеале - сохранить в файл)
                        Write-Host ""
                        Write-Host "New priority order:" -ForegroundColor Green
                        for($i = 0; $i -lt $managerList.Count; $i++) {
                            $m = $managerList[$i]
                            $priority = $i + 1  # 1 = highest priority
                            Write-Host "  $priority. $($m.Icon) $($m.Name)"
                        }
                        
                        Write-Host ""
                        Write-Host "NOTE: Priority changes are temporary for this session." -ForegroundColor Yellow
                        Write-Host "To make permanent: edit the priority order in uniget.ps1" -ForegroundColor Yellow
                        Write-Host ""
                        
                        $running = $false
                    }
                    81 { # Q - quit without saving
                        Clear-Host
                        Write-Host ""
                        Write-Host "Cancelled - no changes made" -ForegroundColor Yellow
                        Write-Host ""
                        $running = $false
                    }
                    27 { # Escape - quit without saving
                        Clear-Host
                        Write-Host ""
                        Write-Host "Cancelled - no changes made" -ForegroundColor Yellow
                        Write-Host ""
                        $running = $false
                    }
                }
            }
        }
        
        "setup" {
            Write-Host "`nChecking package managers..." -ForegroundColor Cyan
            Write-Host ""
            
            # Список менеджеров для установки
            $toInstallList = @{
                "choco" = @{
                    Name = "Chocolatey"
                    Icon = "🟤"
                    Command = 'Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString(''https://community.chocolatey.org/install.ps1''))'
                }
                "scoop" = @{
                    Name = "Scoop"
                    Icon = "🔵"
                    Command = 'Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force; Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression'
                }
                "winget" = @{
                    Name = "Windows Package Manager"
                    Icon = "🟢"
                    Command = $null  # Pre-installed
                    Instructions = "WinGet comes with Windows 10 1809+. Update via Microsoft Store or download from: https://aka.ms/getwinget"
                }
                "npm" = @{
                    Name = "Node.js"
                    Icon = "🟥"
                    Command = "winget install OpenJS.NodeJS --silent --accept-package-agreements --accept-source-agreements"
                }
                "pip" = @{
                    Name = "Python"
                    Icon = "🐍"
                    Command = "winget install Python.Python.3.13 --silent --accept-package-agreements --accept-source-agreements"
                }
                "cargo" = @{
                    Name = "Rust"
                    Icon = "🦀"
                    Command = "winget install Rustlang.Rustup --silent --accept-package-agreements --accept-source-agreements"
                }
                "dotnet" = @{
                    Name = ".NET SDK"
                    Icon = "🔷"
                    Command = "winget install Microsoft.DotNet.SDK.8 --silent --accept-package-agreements --accept-source-agreements"
                }
            }
            
            # Собираем список недостающих
            $missing = @()
            
            foreach($key in @("choco", "scoop", "winget", "npm", "pip", "cargo", "dotnet")) {
                if(-not $available[$key]) {
                    $missing += [PSCustomObject]@{
                        Key = $key
                        Name = $toInstallList[$key].Name
                        Icon = $toInstallList[$key].Icon
                        Command = $toInstallList[$key].Command
                        Instructions = $toInstallList[$key].Instructions
                    }
                }
            }
            
            if($missing.Count -eq 0) {
                Write-Host "All package managers are already installed!" -ForegroundColor Green
                return
            }
            
            # Показываем список
            Write-Host "Missing package managers:" -ForegroundColor Cyan
            Write-Host ""
            
            foreach($m in $missing) {
                Write-Host "  $($m.Icon) $($m.Name)" -NoNewline
                if($m.Type -eq "manual") {
                    Write-Host " (manual)" -ForegroundColor DarkGray
                } else {
                    Write-Host ""
                }
            }
            
            Write-Host ""
            
            
            # Интерактивный выбор менеджеров
            $toInstall = Show-InteractiveSelection `
                -Items $missing `
                -Title "Package managers to install (use +/- to select, Enter to proceed):" `
                -AllSelectedByDefault $true `
                -DisplayItem {
                    param($m)
                    Write-Host "$($m.Icon) $($m.Name)" -ForegroundColor White
                }
            
            if(-not $toInstall -or $toInstall.Count -eq 0) {
                Write-Host ""
                Write-Host "No package managers selected" -ForegroundColor Yellow
                Write-Host ""
                return
            }
            
            # Install selected параллельно
            Write-Host ""
            Write-Host ":: " -NoNewline -ForegroundColor Cyan
            Write-Host "Installing $($toInstall.Count) package manager(s)..." -ForegroundColor White
            Write-Host ""
            
            # Run installations in parallel
            $installJobs = @{}
            
            foreach($m in $toInstall) {
                if($m.Command) {
                    Write-Host "Starting installation: $($m.Icon) $($m.Name)..." -ForegroundColor DarkGray
                    
                    $installJobs[$m.Key] = Start-Job -ScriptBlock {
                        param($cmd)
                        try {
                            Invoke-Expression $cmd 2>&1 | Out-Null
                            return @{ Success = $true }
                        } catch {
                            return @{ Success = $false; Error = $_.Exception.Message }
                        }
                    } -ArgumentList $m.Command
                } elseif($m.Instructions) {
                    # WinGet - только инструкция
                    Write-Host ":: " -NoNewline -ForegroundColor Cyan
                    Write-Host "$($m.Icon) $($m.Name)" -ForegroundColor White
                    Write-Host "   $($m.Instructions)" -ForegroundColor Yellow
                    Write-Host ""
                }
            }
            
            # Ждём завершения всех установок
            if($installJobs.Count -gt 0) {
                Write-Host ""
                Write-Progress -Activity "Installing package managers" -Status "Please wait..." -PercentComplete 0
                
                $jobArray = @($installJobs.Values)
                Wait-Job -Job $jobArray -Timeout 300 | Out-Null
                Write-Progress -Activity "Installing package managers" -Completed
                
                Write-Host ""
                
                # Check results
                foreach($key in $installJobs.Keys) {
                    $m = $toInstall | Where-Object { $_.Key -eq $key } | Select-Object -First 1
                    $job = $installJobs[$key]
                    
                    Write-Host ":: " -NoNewline -ForegroundColor Cyan
                    Write-Host "$($m.Icon) $($m.Name)" -ForegroundColor White
                    
                    if($job.State -eq "Completed") {
                        $result = Receive-Job -Job $job
                        if($result.Success) {
                            # Проверяем установку
                            Start-Sleep -Seconds 2
                            $check = & $managers[$key].Check
                            if($check) {
                                Write-Host "   Done" -ForegroundColor Green
                            } else {
                                Write-Host "   Installed but not detected - restart terminal" -ForegroundColor Yellow
                            }
                        } else {
                            Write-Host "   Failed: $($result.Error)" -ForegroundColor Red
                        }
                    } else {
                        Write-Host "   Timeout or failed" -ForegroundColor Red
                    }
                    
                    Remove-Job -Job $job -Force
                    Write-Host ""
                }
            }
            
            Write-Host ":: " -NoNewline -ForegroundColor Cyan
            Write-Host "Setup complete. Run 'uniget status' to verify." -ForegroundColor Green
        }
        
        "download" {
            if(-not $packages -or $packages.Count -eq 0) {
                Write-Host "Specify URL to download: uniget download <url> [output_name]" -ForegroundColor Yellow
                return
            }
            
            $url = $packages[0]
            $output = if($packages.Count -gt 1) { $packages[1] } else { $null }
            
            # Определяем имя файла
            if(-not $output) {
                try {
                    $uri = [System.Uri]$url
                    $output = [System.IO.Path]::GetFileName($uri.LocalPath)
                    if(-not $output) {
                        $output = "downloaded_file"
                    }
                } catch {
                    $output = "downloaded_file"
                }
            }
            
            # Проверяем что файл не существует
            if(Test-Path $output) {
                Write-Host "File '$output' already exists. Overwrite? [Y/n]: " -NoNewline
                $answer = Read-Host
                if($answer -eq 'n' -or $answer -eq 'N') {
                    Write-Host "Cancelled" -ForegroundColor Yellow
                    return
                }
            }
            
            Write-Host ""
            Write-Host "Downloading from: " -NoNewline -ForegroundColor Cyan
            Write-Host $url
            Write-Host "Saving to:        " -NoNewline -ForegroundColor Cyan
            Write-Host $output
            Write-Host ""
            
            try {
                # Используем Invoke-WebRequest с прогресс-баром
                $ProgressPreference = 'SilentlyContinue'
                
                # Для больших файлов используем WebClient с событиями
                $webClient = New-Object System.Net.WebClient
                
                # Обработчик прогресса
                $progressHandler = {
                    param($sender, $e)
                    $percent = $e.ProgressPercentage
                    $received = [Math]::Round($e.BytesReceived / 1MB, 2)
                    $total = [Math]::Round($e.TotalBytesToReceive / 1MB, 2)
                    
                    Write-Progress -Activity "Downloading $output" `
                                   -Status "$received MB / $total MB" `
                                   -PercentComplete $percent
                }
                
                Register-ObjectEvent -InputObject $webClient -EventName DownloadProgressChanged `
                                     -SourceIdentifier WebClient.DownloadProgressChanged `
                                     -Action $progressHandler | Out-Null
                
                # Скачиваем
                $downloadTask = $webClient.DownloadFileTaskAsync($url, $output)
                $downloadTask.Wait()
                
                # Очищаем
                Unregister-Event -SourceIdentifier WebClient.DownloadProgressChanged -ErrorAction SilentlyContinue
                $webClient.Dispose()
                Write-Progress -Activity "Downloading" -Completed
                
                if(Test-Path $output) {
                    $size = (Get-Item $output).Length
                    $sizeMB = [Math]::Round($size / 1MB, 2)
                    
                    Write-Host ""
                    Write-Host ":: " -NoNewline -ForegroundColor Cyan
                    Write-Host "Downloaded successfully: " -NoNewline -ForegroundColor Green
                    Write-Host "$output ($sizeMB MB)"
                } else {
                    Write-Host "Download failed" -ForegroundColor Red
                }
                
            } catch {
                Write-Progress -Activity "Downloading" -Completed
                Write-Host ""
                Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
            } finally {
                $ProgressPreference = 'Continue'
            }
        }
    }
}
