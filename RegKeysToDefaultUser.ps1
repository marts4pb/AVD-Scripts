#########################################################
#                                                        #
# Script to set Windows & Application registry keys     #
# Including, mounting the default user registry hive    #
#                                                        #
#########################################################

# Set variables
$TempHKey= "HKU\TEMP"
$DefaultRegPath = "C:\Users\Default\NTUSER.DAT"
$LogDir = "C:\Windows\Temp"
$LogFile = "$LogDir\DefaultUserRegistryScriptLog_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

# Create a log file and function for logging
function Log {
    param (
        [string]$message
    )
    Add-Content -Path $LogFile -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): $message"
}

# Delete log files older than 7 days
Get-ChildItem -Path $LogDir -Filter "DefaultUserRegistryScriptLog_*.txt" | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) } | Remove-Item -Force

Log "Script started."

# Mount the default user registry hive
try {
    reg load $TempHKEY $DefaultRegPath
    Log "Mounted default user registry hive."
} catch {
    Log "Failed to mount default user registry hive: $_"
}

# Enable Windows Maintain Default Printer
try {
    Set-ItemProperty -Path "registry::HKU\Temp\Software\Microsoft\Windows NT\CurrentVersion\Windows" -Name 'MaintainDefaultPrinter' -Value 1 -Type DWord -Force
    Log "Enabled Windows Maintain Default Printer."
} catch {
    Log "Failed to enable Windows Maintain Default Printer: $_"
}

# Disable Office Insider and hide from File menu
$commonpath = 'registry::HKU\Temp\Software\Policies\Microsoft\Office\16.0\Common'
$commonkey = try {
    Get-Item -Path $commonpath -ErrorAction SilentlyContinue
} catch {
    New-Item -Path $commonpath -Force
}
try {
    Set-ItemProperty -Path $commonkey.PSPath -Name InsiderSlabBehavior -Type DWord -Value 2
    Log "Disabled Office Insider and hid from File menu."
} catch {
    Log "Failed to disable Office Insider and hide from File menu: $_"
}
$commonkey.Handle.Close()

# Set Outlook's Cached Exchange Mode behavior
$cachedpath = 'registry::HKU\Temp\Software\Policies\Microsoft\Office\16.0\Outlook\cached mode'
$cachedkey = try {
    Get-Item -Path $cachedpath -ErrorAction SilentlyContinue
} catch {
    New-Item -Path $cachedpath -Force
}
try {
    Set-ItemProperty -Path $cachedkey.PSPath -Name enable -Type DWord -Value 1
    Set-ItemProperty -Path $cachedkey.PSPath -Name syncwindowsetting -Type DWord -Value 3
    Set-ItemProperty -Path $cachedkey.PSPath -Name CalendarSyncWindowSetting -Type DWord -Value 1
    Set-ItemProperty -Path $cachedkey.PSPath -Name CalendarSyncWindowSettingMonths -Type DWord -Value 3
    Log "Set Outlook's Cached Exchange Mode behavior."
} catch {
    Log "Failed to set Outlook's Cached Exchange Mode behavior: $_"
}
$cachedkey.Handle.Close()

# Set Outlook's Shared Mailbox Email Deletion Behavior
$outlookgeneralpath = 'registry::HKU\Temp\Software\Microsoft\Office\16.0\Outlook\Options\General'
$outlookgeneralkey = try {
    Get-Item -Path $outlookgeneralpath -ErrorAction SilentlyContinue
} catch {
    New-Item -Path $outlookgeneralpath -Force
}
try {
    Set-ItemProperty -Path $outlookgeneralkey.PSPath -Name DelegateWastebasketStyle -Type DWord -Value 4
    Log "Set Outlook's Shared Mailbox Email Deletion Behavior."
} catch {
    Log "Failed to set Outlook's Shared Mailbox Email Deletion Behavior: $_"
}
$outlookgeneralkey.Handle.Close()

# Set MSTeams startup to enable
$teamspath = 'registry::HKU\Temp\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppModel\SystemAppData\MSTeams_8wekyb3d8bbwe\TeamsTfwStartupTask'
$teamskey = try {
    Get-Item -Path $teamspath -ErrorAction SilentlyContinue
} catch {
    New-Item -Path $teamspath -Force
}
try {
    Set-ItemProperty -Path $teamskey.PSPath -Name State -Type DWord -Value 2 -Force
    Set-ItemProperty -Path $teamskey.PSPath -Name UserEnabledStartupOnce -Type DWord -Value 1 -Force
    Log "Set MSTeams startup to enable."
} catch {
    Log "Failed to set MSTeams startup to enable: $_"
}
$teamskey.Handle.Close()

# Set OneDriveSetup Variable
try {
    $OneDriveSetup = Get-ItemProperty "registry::HKU\Temp\Software\Microsoft\Windows\CurrentVersion\Run" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty "OneDriveSetup" -ErrorAction SilentlyContinue
    If ($OneDriveSetup) {
        Remove-ItemProperty -Path "registry::HKU\Temp\Software\Microsoft\Windows\CurrentVersion\Run" -Name "OneDriveSetup"
        Log "Removed OneDriveSetup from Run registry."
    }
} catch {
    Log "Failed to remove OneDriveSetup from Run registry: $_"
}

# Clear garbage collection
[gc]::Collect()
Log "Cleared garbage collection."

# Unmount the default user registry hive
try {
    reg unload $TempHKEY
    Log "Unmounted default user registry hive."
} catch {
    Log "Failed to unmount default user registry hive: $_"
}

Log "Script completed."
