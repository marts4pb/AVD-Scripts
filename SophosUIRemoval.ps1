# Define the path to the registry key and the value name
$registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
$valueName = "Sophos UI.exe"

# Remove the registry value if it exists
try {
    Remove-ItemProperty -Path $registryPath -Name $valueName -ErrorAction SilentlyContinue
    Write-Host "Registry value '$valueName' has been deleted from '$registryPath'."
    exit 0  # Indicates success
} catch {
    Write-Host "An error occurred during remediation: $_"
    exit 2  # Indicates an error occurred
}
