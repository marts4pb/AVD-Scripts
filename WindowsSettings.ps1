# Define the log directory and file
$LogDirectory = "C:\Windows\Temp"
$LogFileName = "Windows_Settings_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$LogFilePath = Join-Path -Path $LogDirectory -ChildPath $LogFileName

# Log function
function Write-Log {
    param (
        [string]$Message,
        [string]$Type = "INFO"
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] [$Type] $Message"
    Add-Content -Path $LogFilePath -Value $LogEntry
}

# Delete old log files older than 7 days
$OldLogFiles = Get-ChildItem -Path $LogDirectory -Filter "Windows_Settings_Log_*.log" |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) }

foreach ($File in $OldLogFiles) {
    try {
        Remove-Item -Path $File.FullName -Force
        Write-Log "Deleted old log file: $($File.FullName)" "INFO"
    } catch {
        Write-Log "Failed to delete old log file: $($File.FullName). Error: $_" "ERROR"
    }
}

# Create Registry Paths at the beginning
$RegistryPaths = @(
    "HKLM:\Software\Policies\Microsoft\Windows NT\Terminal Services",
    "HKLM:\Software\Policies\Microsoft\Windows\System",
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System",
    "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations",
    "HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation",
    "HKLM:\SYSTEM\CurrentControlSet\Control\Nls\Language",
    "HKLM:\SYSTEM\CurrentControlSet\Control\Nls\Locale",
    "HKLM:\SYSTEM\Keyboard Layout\Preload",
    "registry::HKEY_USERS\.DEFAULT\Control Panel\International",
	"registry::HKEY_USERS\.DEFAULT\Control Panel\International\Geo",
	"registry::HKEY_USERS\.DEFAULT\Control Panel\International\User Profile",
	"registry::HKEY_USERS\.DEFAULT\Control Panel\International\User Profile\en-GB",
	"registry::HKEY_USERS\.DEFAULT\Control Panel\International\User Profile System Backup",
	"registry::HKEY_USERS\.DEFAULT\Control Panel\International\User Profile System Backup\en-GB",
    "registry::HKEY_USERS\.DEFAULT\Keyboard Layout\Preload",
    "registry::HKEY_USERS\.DEFAULT\Control Panel\Desktop\MuiCached"
)

foreach ($path in $RegistryPaths) {
    if (-not (Test-Path -Path $path)) {
        try {
            New-Item -Path $path -Force | Out-Null
            Write-Log "Created registry path: $path"
        } catch {
            Write-Log "Failed to create registry path: $path. Error: $_" "ERROR"
        }
    }
}

# Function to set registry values
function Set-RegistryValue {
    param (
        [string]$Path,
        [string]$Name,
        [string]$Type,
        [object]$Value
    )
    try {
        # Check if the registry value exists
        $CurrentValue = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue

        # If the value doesn't exist or is different, update it
        if ($null -eq $CurrentValue -or $CurrentValue.$Name -ne $Value) {
            Set-ItemProperty -Path $Path -Name $Name -Value $Value -Force
            Write-Log "Updated registry value: $Path\$Name to $Value"
        } else {
            Write-Log "Skipped updating registry value: $Path\$Name. Current value is already set to $Value"
        }
    } catch {
        Write-Log "Failed to set registry value: $Path\$Name. Error: $_" "ERROR"
    } finally {
    if ($ErrorOccurred) {
        # Perform additional reporting or actions for failed updates
        Write-Log "Error occurred during registry update for: $Path\$Name" "ERROR"
    }
    Write-Log "Registry update check completed for: $Path\$Name"
	}

}

# Apply all registry settings
Write-Log "Starting registry settings application."

# Terminal Services Policies
Set-RegistryValue -Path "HKLM:\Software\Policies\Microsoft\Windows NT\Terminal Services" -Name "MaxIdleTime" -Type "DWord" -Value "3600000"
Set-RegistryValue -Path "HKLM:\Software\Policies\Microsoft\Windows NT\Terminal Services" -Name "MaxDisconnectionTime" -Type "DWord" -Value "7200000"

# System Policies
Set-RegistryValue -Path "HKLM:\Software\Policies\Microsoft\Windows\System" -Name "WaitForNetwork" -Type "DWord" -Value "0"

# Windows CurrentVersion Policies
Set-RegistryValue -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name "InactivityTimeoutSecs" -Type "DWord" -Value "900"
Set-RegistryValue -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\NonEnum" -Name "{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}" -Type "DWord" -Value "1"

# Terminal Server WinStations
Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations" -Name "ICEControl" -Type "DWord" -Value "2"

# Time Zone Information
Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" -Name "DaylightBias" -Type "DWord" -Value "4294967236"
Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" -Name "DaylightName" -Type "String" -Value "@tzres.dll,-261"
Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" -Name "StandardName" -Type "String" -Value "@tzres.dll,-262"
Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" -Name "TimeZoneKeyName" -Type "String" -Value "GMT Standard Time"

# NLS Language Settings
Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Nls\Language" -Name "Default" -Type "String" -Value "0809"
Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Nls\Language" -Name "InstallLanguage" -Type "String" -Value "0809"
Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Nls\Locale" -Name "(Default)" -Type "String" -Value "00000809"

# Keyboard Layout
Set-RegistryValue -Path "HKLM:\SYSTEM\Keyboard Layout\Preload" -Name "1" -Type "String" -Value "00000809"

# Default User International Settings
$IntlPath = "registry::HKEY_USERS\.DEFAULT\Control Panel\International"
Set-RegistryValue -Path $IntlPath -Name "iCountry" -Type "String" -Value "44"
Set-RegistryValue -Path $IntlPath -Name "iDate" -Type "String" -Value "1"
Set-RegistryValue -Path $IntlPath -Name "iFirstDayOfWeek" -Type "String" -Value "0"
Set-RegistryValue -Path $IntlPath -Name "iFirstWeekOfYear" -Type "String" -Value "2"
Set-RegistryValue -Path $IntlPath -Name "iMeasure" -Type "String" -Value "0"
Set-RegistryValue -Path $IntlPath -Name "iNegCurr" -Type "String" -Value "1"
Set-RegistryValue -Path $IntlPath -Name "iPaperSize" -Type "String" -Value "9"
Set-RegistryValue -Path $IntlPath -Name "iTime" -Type "String" -Value "1"
Set-RegistryValue -Path $IntlPath -Name "iTLZero" -Type "String" -Value "1"
Set-RegistryValue -Path $IntlPath -Name "Locale" -Type "String" -Value "00000809"
Set-RegistryValue -Path $IntlPath -Name "LocaleName" -Type "String" -Value "en-GB"
Set-RegistryValue -Path $IntlPath -Name "sCurrency" -Type "String" -Value "£"
Set-RegistryValue -Path $IntlPath -Name "sLanguage" -Type "String" -Value "ENG"
Set-RegistryValue -Path $IntlPath -Name "sLongDate" -Type "String" -Value "dd MMMM yyyy"
Set-RegistryValue -Path $IntlPath -Name "sShortDate" -Type "String" -Value "dd/MM/yyyy"
Set-RegistryValue -Path $IntlPath -Name "sShortTime" -Type "String" -Value "HH:mm"
Set-RegistryValue -Path $IntlPath -Name "sTimeFormat" -Type "String" -Value "HH:mm:ss"
Set-RegistryValue -Path "$IntlPath\Geo" -Name "Name" -Type "String" -Value "GB"
Set-RegistryValue -Path "$IntlPath\Geo" -Name "Nation" -Type "String" -Value "242"
Set-RegistryValue -Path "$IntlPath\User Profile" -Name "Languages" -Type "MultiString" -Value "en-GB"
Set-RegistryValue -Path "$IntlPath\User Profile\en-GB" -Name "0809:00000809" -Type "DWord" -Value "1"
Set-RegistryValue -Path "$IntlPath\User Profile\en-GB" -Name "CachedLanguageName" -Type "String" -Value "@Winlangdb.dll,-1110"
Set-RegistryValue -Path "$IntlPath\User Profile\en-GB" -Name "FeaturesToInstall" -Type "DWord" -Value "255"

# Defualt User Keyboard Layout
Set-RegistryValue -Path "registry::HKEY_USERS\.DEFAULT\Keyboard Layout\Preload" -Name "1" -Type "String" -Value "00000809"

# Default User Keyboard Preload
Set-RegistryValue -Path "registry::HKEY_USERS\.DEFAULT\Control Panel\Desktop\MuiCached" -Name "MachinePreferredUILanguages" -Type "MultiString" -Value "en-GB"

# Default User International User Profile System Backup
Set-RegistryValue -Path "registry::HKEY_USERS\.DEFAULT\Control Panel\International\User Profile System Backup" -Name "Languages" -Type "MultiString" -Value "en-GB"
Set-RegistryValue -Path "registry::HKEY_USERS\.DEFAULT\Control Panel\International\User Profile System Backup" -Name "WindowsOverride" -Type "String" -Value "en-GB"
Set-RegistryValue -Path "registry::HKEY_USERS\.DEFAULT\Control Panel\International\User Profile System Backup" -Name "UserLocaleFromLanguageProfileOptOut" -Type "DWord" -Value "1"
Set-RegistryValue -Path "registry::HKEY_USERS\.DEFAULT\Control Panel\International\User Profile System Backup\en-GB" -Name "0809:00000809" -Type "DWord" -Value "1"
Set-RegistryValue -Path "registry::HKEY_USERS\.DEFAULT\Control Panel\International\User Profile System Backup\en-GB" -Name "CachedLanguageName" -Type "String" -Value "@Winlangdb.dll,-1110"

# Apply all registry settings
Write-Log "Registry settings application completed."

Write-Log "Starting registry settings removal application."

# Remove the en-US profile and backup if they exist
$USPath = 'registry::HKEY_USERS\.DEFAULT\Control Panel\International\User Profile\en-US'
try {
    Get-Item -Path $USPath -ErrorAction Stop
    Remove-Item -Path $USPath -ErrorAction Stop
}
catch {
    Write-Warning "$_.Exception.Message" -WarningAction SilentlyContinue
}

$USbackupPath = 'registry::HKEY_USERS\.DEFAULT\Control Panel\International\User Profile System Backup\en-US'
try {
    Get-Item -Path $USbackupPath -ErrorAction Stop
    Remove-Item -Path $USbackupPath -ErrorAction Stop
}
catch {
    Write-Warning "$_.Exception.Message" -WarningAction SilentlyContinue
}

Write-Log "Completed registry settings removal application."

# Re-register time zone
try {
    $TimeZone = Get-TimeZone -ListAvailable | Where-Object { $_.Id -like "GMT*" }
    if ($null -ne $TimeZone) {
        Set-TimeZone -Id $TimeZone.Id
        Write-Log "Time zone set to: $($TimeZone.Id)"
    } else {
        Write-Log "Time zone matching 'GMT*' not found." "WARNING"
    }
} catch {
    Write-Log "Failed to set time zone. Error: $_" "ERROR"
}

Write-Log "Script execution completed."
