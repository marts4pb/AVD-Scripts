# Set page file settings on D: drive

# Disable automatic management of the page file
$system = Get-WmiObject -Class Win32_ComputerSystem -EnableAllPrivileges
$system.AutomaticManagedPagefile = $false
$system.Put() | Out-Null

# Remove any existing page file settings for the D: drive
$existingPageFile = Get-WmiObject -Class Win32_PageFileSetting -Filter "Name='D:\\pagefile.sys'"
if ($existingPageFile) {
    $existingPageFile.Delete() | Out-Null
}

# Set the new page file size for the D: drive in the registry
$regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
Set-ItemProperty -Path $regPath -Name "PagingFiles" -Value "D:\\pagefile.sys 98304 98304"

# Output the current page file settings to confirm changes
$pageFileSetting = Get-ItemProperty -Path $regPath -Name "PagingFiles"
Write-Output "Page file size on D: drive set to: $($pageFileSetting.PagingFiles)"
Write-Output "Automatic Managed Pagefile: $($system.AutomaticManagedPagefile)"
