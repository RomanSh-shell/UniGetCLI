# UniGet Package Managers Configuration
# Добавляйте новые менеджеры сюда!

# Формат:
# @{
#     name = "Имя менеджера"
#     icon = "Эмодзи"
#     check = { команда проверки наличия }
#     list = "команда для списка установленных"
#     search = "команда для поиска"
#     install = "команда установки {PKG}"
#     update = "команда обновления {PKG}"
#     update_all = "команда обновления всех"
#     uninstall = "команда удаления {PKG}"
#     outdated = "команда для списка обновлений"
# }

$script:ManagerConfigs = @{
    "winget" = @{
        Name = "Windows Package Manager"
        Icon = "🟢"
        Priority = 1
        Check = { Get-Command winget -ErrorAction SilentlyContinue }
        InstallManager = "# WinGet comes with Windows 10 1809+ / Windows 11. Update via Microsoft Store or download from: https://aka.ms/getwinget"
        List = "winget list"
        Search = "winget search {PKG}"
        Install = "winget install {PKG} --exact --silent --accept-package-agreements --accept-source-agreements"
        Update = "winget upgrade {PKG} --exact --silent --accept-package-agreements --accept-source-agreements"
        UpdateAll = "winget upgrade --all --silent --accept-package-agreements --accept-source-agreements"
        Uninstall = "winget uninstall {PKG} --silent"
        Outdated = "winget upgrade"
    }
    
    "choco" = @{
        Name = "Chocolatey"
        Icon = "🟤"
        Priority = 2
        Check = { Get-Command choco -ErrorAction SilentlyContinue }
        InstallManager = "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
        List = "choco list --local-only --limit-output"
        Search = "choco search {PKG} --limit-output"
        Install = "choco install {PKG} -y"
        Update = "choco upgrade {PKG} -y"
        UpdateAll = "choco upgrade all -y"
        Uninstall = "choco uninstall {PKG} -y"
        Outdated = "choco outdated --limit-output"
    }
    
    "scoop" = @{
        Name = "Scoop"
        Icon = "🔵"
        Priority = 3
        Check = { Get-Command scoop -ErrorAction SilentlyContinue }
        InstallManager = "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser; Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression"
        List = "scoop list"
        Search = "scoop search {PKG}"
        Install = "scoop install {PKG}"
        Update = "scoop update {PKG}"
        UpdateAll = "scoop update *"
        Uninstall = "scoop uninstall {PKG}"
        Outdated = "scoop status"
    }
    
    "npm" = @{
        Name = "Node Package Manager"
        Icon = "🟥"
        Priority = 4
        Check = { Get-Command npm -ErrorAction SilentlyContinue }
        InstallManager = "# Install Node.js from: https://nodejs.org OR via winget: winget install OpenJS.NodeJS"
        List = "npm list -g --depth=0 --json"
        Search = "npm search {PKG} --json --no-description"
        Install = "npm install -g {PKG}"
        Update = "npm update -g {PKG}"
        UpdateAll = "npm update -g"
        Uninstall = "npm uninstall -g {PKG}"
        Outdated = "npm outdated -g --json"
    }
    
    "pip" = @{
        Name = "Python Package Installer"
        Icon = "🐍"
        Priority = 5
        Check = { Get-Command pip -ErrorAction SilentlyContinue }
        InstallManager = "# Install Python from: https://python.org OR via winget: winget install Python.Python.3.13"
        List = "pip list --format=freeze"
        Search = "https://pypi.org/pypi/{PKG}/json"  # API endpoint
        Install = "pip install {PKG}"
        Update = "pip install --upgrade {PKG}"
        UpdateAll = "pip list --outdated --format=freeze | ForEach-Object { pip install --upgrade ($_ -split '==')[0] }"
        Uninstall = "pip uninstall {PKG} -y"
        Outdated = "pip list --outdated --format=freeze"
    }
    
    "cargo" = @{
        Name = "Rust Package Manager"
        Icon = "🦀"
        Priority = 6
        Check = { Get-Command cargo -ErrorAction SilentlyContinue }
        InstallManager = "# Install Rust from: https://rustup.rs OR via winget: winget install Rustlang.Rustup"
        List = "cargo install --list"
        Search = "cargo search {PKG} --limit 20"
        Install = "cargo install {PKG}"
        Update = "cargo install {PKG} --force"
        UpdateAll = "cargo install-update -a"  # Requires cargo-update
        Uninstall = "cargo uninstall {PKG}"
        Outdated = "cargo install-update --list"  # Requires cargo-update
    }
    
    "dotnet" = @{
        Name = ".NET Tool Manager"
        Icon = "🔷"
        Priority = 7
        Check = { Get-Command dotnet -ErrorAction SilentlyContinue }
        InstallManager = "# Install .NET SDK from: https://dot.net OR via winget: winget install Microsoft.DotNet.SDK.8"
        List = "dotnet tool list -g"
        Search = "dotnet tool search {PKG} --take 20"
        Install = "dotnet tool install --global {PKG}"
        Update = "dotnet tool update --global {PKG}"
        UpdateAll = "dotnet tool update --global --all"
        Uninstall = "dotnet tool uninstall --global {PKG}"
        Outdated = $null  # No native command
    }
    
    "vcpkg" = @{
        Name = "C++ Package Manager"
        Icon = "⚙️"
        Priority = 8
        Check = { Get-Command vcpkg -ErrorAction SilentlyContinue }
        InstallManager = "git clone https://github.com/microsoft/vcpkg.git C:\vcpkg; C:\vcpkg\bootstrap-vcpkg.bat; [System.Environment]::SetEnvironmentVariable('PATH', `$env:PATH + ';C:\vcpkg', 'User')"
        List = "vcpkg list"
        Search = "vcpkg search {PKG}"
        Install = "vcpkg install {PKG}"
        Update = "vcpkg upgrade {PKG}"
        UpdateAll = "vcpkg upgrade --no-dry-run"
        Uninstall = "vcpkg remove {PKG}"
        Outdated = $null  # No native command
    }
    
    "pwsh" = @{
        Name = "PowerShell Gallery"
        Icon = "💠"
        Priority = 9
        Check = { Get-Command Find-Module -ErrorAction SilentlyContinue }
        InstallManager = "# PowerShell Gallery is built into PowerShell 5.0+. Update PowerShell: winget install Microsoft.PowerShell"
        List = "Get-InstalledModule"
        Search = "Find-Module *{PKG}*"
        Install = "Install-Module {PKG} -Scope CurrentUser -Force"
        Update = "Update-Module {PKG} -Force"
        UpdateAll = "Update-Module -Force"
        Uninstall = "Uninstall-Module {PKG} -Force"
        Outdated = $null  # Custom logic needed
    }
}

# Примеры добавления новых менеджеров:

<#
"steam" = @{
    Name = "Steam"
    Icon = "🎮"
    Priority = 10
    Check = { Test-Path "C:\Program Files (x86)\Steam\steam.exe" }
    List = "steamcmd +login anonymous +app_update list +quit"
    Search = $null
    Install = "steamcmd +login anonymous +app_update {PKG} validate +quit"
    Update = "steamcmd +login anonymous +app_update {PKG} validate +quit"
    UpdateAll = $null
    Uninstall = "steamcmd +login anonymous +app_uninstall {PKG} +quit"
    Outdated = $null
}

"git" = @{
    Name = "Git Repositories"
    Icon = "📦"
    Priority = 11
    Check = { Get-Command git -ErrorAction SilentlyContinue }
    List = $null  # Custom logic
    Search = $null
    Install = "git clone {PKG}"
    Update = "git pull"
    UpdateAll = $null  # Custom logic needed
    Uninstall = $null
    Outdated = "git fetch; git status"
}
#>

Export-ModuleMember -Variable ManagerConfigs
