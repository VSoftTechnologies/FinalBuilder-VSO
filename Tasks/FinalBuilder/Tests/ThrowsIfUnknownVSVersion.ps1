[CmdletBinding()]
param()

# Arrange.
. $PSScriptRoot\..\..\..\Tests\lib\Initialize-Test.ps1
Register-Mock Get-SolutionFiles
Register-Mock Get-VstsInput { 'Some input projectfile' } -- -Name projectfile
Register-Mock Get-VstsInput { 'Some input cwd' } -- -Name cwd
Register-Mock Get-VstsInput { 'Some input dropfolder' } -- -Name dropfolder
Register-Mock Get-VstsInput { 'Some input targets' } -- -Name targets
Register-Mock Get-VstsInput { 'Some input solutionfile' } -- -Name solutionfile
Register-Mock Get-VstsInput { 'Some input platform' } -- -Name platform
Register-Mock Get-VstsInput { 'Some input flavor' } -- -Name flavor
Register-Mock Get-VstsInput { 'Some input customArgs' } -- -Name customArgs
Register-Mock Select-VSVersion { 'nosuchversion' } -- -PreferredVersion '14.0'
Register-Mock Select-MSBuildPath
Register-Mock Format-MSBuildArguments
Register-Mock Invoke-BuildTools

# Act.
Assert-Throws { $null = & $PSScriptRoot\..\finalbuilder.ps1 } -MessagePattern "*nosuchversion*"
