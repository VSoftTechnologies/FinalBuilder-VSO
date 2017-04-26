param (
    [string]$projectfile, # Path to finalbuilder project. 
    [string]$cwd, # Path to current working directory.
	[string]$dropfolder, # Path to network location to drop built artifacts.
	[string]$targets, # List of targets to run with in the FinalBuilder project.
	[string]$solutionfile, # The solution file search string for the solution(s) to build.
	[string]$platform, # The platform to build the solutions under (x86,x64,Any CPU).
	[string]$flavor, # The flavor of build to perform on the solutions (Debug, Release, Etc).
	[string]$customArgs # A line seperated list of custom arguments for FinalBuilder. 
)

function Get-FB8Arguments([string]$fbProjectFile, [string]$triggerFilename, [boolean]$noBanner, [string]$targets, [string]$variables, [string]$packages) {
	# The FinalBuilder project name is the first argument to pass. 
	$argsOut =  "`"$fbProjectFile`""
	
	# If no banner has been requested add this as a parameter. 
	if ($noBanner) {
		$argsOut = $argsOut + " -nb"
	}

	# If there are any targets, add them to the arguments. 
	if (-not [System.String]::IsNullOrWhiteSpace($targets)) {
		$targets = $targets.Replace("`n", ";")
		$argsOut = $argsOut + " -t:`"$targets`""
	}
    
	# TODO Add custom variables passing from GUI	
	# If there are any FinalBuilder variables, add them to the arguments.
	if (-not [System.String]::IsNullOrWhiteSpace($variables)) {
		$variables = $variables.Replace("`n", ";")
		$argsOut = $argsOut + " -v:`"$variables`""
	}

	# TODO Add package selection passing from GUI	
	# If there are any FinalBuilder packages, add them to the arguments.
    if (-not [System.String]::IsNullOrWhiteSpace($packages)) {
		$packages = $packages.Replace("`n", ";")

		$argsOut = $argsOut + " -pk:`"$packages`""
	}
	
	# If there is a TFS trigger xml file, add it to the arguments. 
    if (-not [System.String]::IsNullOrEmpty($triggerFilename)) { 
		$argsOut = $argsOut + " -#:$triggerFilename"
	}

	# Make sure to turn off hierarchy logging. 
	$argsOut = $argsOut + " -h"
	
	return $argsOut
}

function Set-FB8EnvironmentVars([string]$buildPlatform, [string]$buildFlavor, [string]$dropFolder, [string]$solutionRoot, [string]$workingDirectory, [string]$solutionfile, $solutionfileList, [string]$customArgs) {
	
	# Set each environment variable referred to by the Get Team Foundation Build Parameters action		
	$env:_envTeamServer = $env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI
	$env:_envTeamProject = $env:SYSTEM_TEAMPROJECTID
	$env:_envTeamBuildId = $env:BUILD_BUILDNUMBER
	$env:_envBuildPlatform = $buildPlatform
	$env:_envBuildFlavor = $buildFlavor
	$env:_envDropFolder = $dropFolder
	$env:_envSolutionRoot = $solutionRoot
	$env:_envWorkingDirectory = $workingDirectory
	$env:_envSolutionFile = $solutionfile
	# Make sure the file list is line seperated. 
	$env:_envSolutionFileList = $solutionfileList -join "`r`n"
	    
	# Split the custom arguments by line
    if (![string]::IsNullOrEmpty($customArgs)) { 
		# Always return an array split on either \r or \n
	    $customArgsList = @($customArgs -split '[\r\n]' | where {$_})
				
 	    for ($i = 0; $i -lt $customArgsList.length; $i++) { 
			 [Environment]::SetEnvironmentVariable("_envCustomArg$i", $customArgsList[$i], "Process")
        }
    }
}

function Get-AssociatedChangesets($vssEndpoint) {
	$personalAccessToken = $vssEndpoint.Authorization.Parameters.AccessToken
	
	# REST request to get the list of changesets for the current build. 
	# TODO: Tests if pagination is an issue here
	$changesUri = "$($env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI)$($env:SYSTEM_TEAMPROJECTID)/_apis/build/builds/$($env:BUILD_BUILDID)/changes?api-version=2.0"
	$headers = @{Authorization = "Bearer $personalAccessToken"}
	$associatedChanges = (Invoke-WebRequest -Method Get -Uri $changesUri -Headers $headers -UseBasicParsing) | ConvertFrom-Json
				
	return $associatedChanges
}

function Get-BuildDefinition($vssEndpoint) {
	$personalAccessToken = $vssEndpoint.Authorization.Parameters.AccessToken
	
	# REST request to get the build definition for the current build.
	$buildDefUri = "$($env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI)$($env:SYSTEM_TEAMPROJECTID)/_apis/build/builds/$($env:BUILD_BUILDID)"
	$headers = @{Authorization = "Bearer $personalAccessToken"}
	$buildDef = (Invoke-WebRequest -Method Get -Uri $buildDefUri -Headers $headers -UseBasicParsing) | ConvertFrom-Json
		
	return $buildDef
}

function Get-LastFailedBuild($vssEndpoint, $buildDefID) {
	$personalAccessToken = $vssEndpoint.Authorization.Parameters.AccessToken
	
	# REST request to get one failed build for the passed in build definition id. The REST request returns results in date/time order. This then is then the last failed build. 
	$failedBuildUri = "$($env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI)$($env:SYSTEM_TEAMPROJECTID)/_apis/build/builds?definitions=$buildDefID&statusFilter=completed&resultFilter=failed&`$top=1&api-version=2.0"
	$headers = @{Authorization = "Bearer $personalAccessToken"}
	$lastFailedBuild = (Invoke-WebRequest -Method Get -Uri $failedBuildUri -Headers $headers -UseBasicParsing) | ConvertFrom-Json
	
	# Return null if we don't get one build record. 				
	if ($lastFailedBuild.count -ne 1) {
		return $null
	}
				
	return $lastFailedBuild.value[0]
}

function Get-LastSuccessfulBuild($vssEndpoint, $buildDefID) {
	$personalAccessToken = $vssEndpoint.Authorization.Parameters.AccessToken
	
	# REST request to get one succesful build for the passed in build definition id. The REST request returns results in date/time order. This then is then the last successful build. 
	$successfulBuildUri = "$($env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI)$($env:SYSTEM_TEAMPROJECTID)/_apis/build/builds?definitions=$buildDefID&statusFilter=completed&resultFilter=succeeded&`$top=1&api-version=2.0"
	$headers = @{Authorization = "Bearer $personalAccessToken"}
	$successfulBuild = (Invoke-WebRequest -Method Get -Uri $successfulBuildUri -Headers $headers -UseBasicParsing) | ConvertFrom-Json
					
	# Return null if we don't get one build record. 				
	if ($successfulBuild.count -ne 1) {
		return $null
	}
				
	return $successfulBuild.value[0]
}

function Get-ChangesetsSince-TFS($vssEndpoint, $projectPath, $fromDate) {
	$personalAccessToken = $vssEndpoint.Authorization.Parameters.AccessToken
	
	# Init our pagination variables.
	$top = $pageSize
	$skip = 0;

	# REST request to get TFS changesets from the passed in date, for a certain project path. 
	$buildsSinceUri = "$($env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI)_apis/tfvc/changesets?fromDate=$fromDate&itemPath=$/$projectPath&api-version=1.0&`$top=$top&`$skip=$skip"
	$headers = @{Authorization = "Bearer $personalAccessToken"}
	$buildsSince = (Invoke-WebRequest -Method Get -Uri $buildsSinceUri -Headers $headers -UseBasicParsing) | ConvertFrom-Json
	
	# Add the list of the current commits to the list of commits
	$commitsSince = $buildsSince.value
		
	# See if there are any more pages of changes for this changeset. 
	while ($buildsSince.value.count -ge $pageSize) {

		# Move the pagination forward one page. 
		$skip = $skip + $pageSize

		# REST request for the next page of files changed in the current changeset. 
		$buildsSinceUri = "$($env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI)_apis/tfvc/changesets?fromDate=$fromDate&itemPath=$/$projectPath&api-version=1.0&`$top=$top&`$skip=$skip"
		$headers = @{Authorization = "Bearer $personalAccessToken"}
		$buildsSince = (Invoke-WebRequest -Method Get -Uri $buildsSinceUri -Headers $headers -UseBasicParsing) | ConvertFrom-Json

		$commitsSince = $commitsSince + $buildsSince.value
	}
	
	return $commitsSince				
}

function Get-ChangesetsSince-Git($vssEndpoint, $repo, $fromDate) {
	$personalAccessToken = $vssEndpoint.Authorization.Parameters.AccessToken
	
	# Init our pagination variables.
	$top = $pageSize
	$skip = 0;
	
	# REST request to get Git commits from the passed in date, for a certain repo.
	$buildsSinceUri = "$($env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI)_apis/git/repositories/$repo/commits?fromDate=$fromDate&api-version=1.0&`$top=$top&`$skip=$skip"
	$headers = @{Authorization = "Bearer $personalAccessToken"}
	$buildsSince = (Invoke-WebRequest -Method Get -Uri $buildsSinceUri -Headers $headers -UseBasicParsing) | ConvertFrom-Json
		
	# Add the list of the current commits to the list of commits
	$commitsSince = $buildsSince.value

	# See if there are any more pages of changes for this changeset. 
	while ($buildsSince.value.count -ge $pageSize) {

		# Move the pagination forward one page. 
		$skip = $skip + $pageSize

		# REST request for the next page of files changed in the current changeset. 
		$buildsSinceUri = "$($env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI)_apis/git/repositories/$repo/commits?fromDate=$fromDate&api-version=1.0&`$top=$top&`$skip=$skip"
		$headers = @{Authorization = "Bearer $personalAccessToken"}
		$buildsSince = (Invoke-WebRequest -Method Get -Uri $buildsSinceUri -Headers $headers -UseBasicParsing) | ConvertFrom-Json

		$commitsSince = $commitsSince + $buildsSince.value
	}

	return $commitsSince				
}

function Get-ChangesetsSince($vssEndpoint, $buildDef, $fromDate) {

	# For the passed in build definition return the list of changes since the passed in date. 
	# Depending on the build definitions repository type return that repository types list of changes. 
	if ($buildDef.repository.type -eq "TfsVersionControl") {
		$projectName = $buildDef.project.name
		$buildsSince = Get-ChangesetsSince-TFS $vssEndpoint $projectName $fromDate
	} elseif ($buildDef.repository.type -eq "TfsGit") {
		$repo = $buildDef.repository.id
		$buildsSince = Get-ChangesetsSince-Git $vssEndpoint $repo $fromDate
	}

	# Note: This JSON Object properties depend on the repository type. TFS and Git have different properties for each change/commit. 
	return $buildsSince
}
	
function Write-AssociatedFiles-TFS([System.XML.XMLDocument]$xmlDoc, [System.XML.XMLElement]$arrayOfModifications, $changesets) {	
	
	# Build the headers early as we will need them for each iteration. 
	$personalAccessToken = $vssEndpoint.Authorization.Parameters.AccessToken
	$headers = @{Authorization = "Bearer $personalAccessToken"}
	
	# Based on each TFS changeset we want to get all the files in that changeset. 
	$changesets | ForEach-Object {
						
		$change = $_
		[System.String]$commitID = $_.id
		$commitID = $commitID.Substring(1)
		# REST request to get the list of file changes for the current changeset.  
		$commit = "$($env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI)_apis/tfvc/changesets/$($commitID)/changes?api-version=1.0&`$top=100"
		$files = (Invoke-WebRequest -Uri $commit -Headers $headers -UseBasicParsing) | ConvertFrom-Json
		
		# TODO: Pagination is an issue here. Need to handle it. 

		# For each of the files in the changeset we need to add them to the list of files associated with the build. 
		$files.value | ForEach-Object {
			
			# FileModificationItem node
			[System.XML.XMLElement]$modificationItem = $arrayOfModifications.AppendChild($xmlDoc.CreateElement("FileModificationItem"))
			$modificationItem.SetAttribute("name", $_.item.path) | Out-Null
			[System.XML.XMLElement]$values = $modificationItem.AppendChild($triggerXMLDoc.CreateElement("values"))
		    	
			# Value Version node
			[System.XML.XMLElement]$version = $values.AppendChild($triggerXMLDoc.CreateElement("value"))
			$version.SetAttribute("type", "Version") | Out-Null
			$version.InnerText = $_.item.version
			
			# Value User node
			[System.XML.XMLElement]$user = $values.AppendChild($triggerXMLDoc.CreateElement("value"))
			$user.SetAttribute("type", "User") | Out-Null
			$user.InnerText = $change.author.displayName
			
			# Value Comment node
			[System.XML.XMLElement]$comment = $values.AppendChild($triggerXMLDoc.CreateElement("value"))
			$comment.SetAttribute("type", "Comment") | Out-Null
			$comment.InnerText = $change.message
			
			# Value Action node
			[System.XML.XMLElement]$action = $values.AppendChild($triggerXMLDoc.CreateElement("value"))
			$action.SetAttribute("type", "Action") | Out-Null
			$action.InnerText = $_.changeType
		}
	}
}

function Write-TriggerFiles-TFS([System.XML.XMLDocument]$xmlDoc, [System.XML.XMLElement]$arrayOfModifications, $changesets) {	
	
	if ($changesets.count -eq 0) {
    	return
	}

	# Build the headers early as we will need them for each iteration. 
	$personalAccessToken = $vssEndpoint.Authorization.Parameters.AccessToken
	$headers = @{Authorization = "Bearer $personalAccessToken"}
	
	# From each changeset we need to get the list of files changed 
	$changesets | ForEach-Object {
		
		# Init our pagination variables.
		$top = $pageSize
		$skip = 0;
									
		$change = $_
		[System.String]$commitID = $_.changesetId
		# REST request for the first page of files changed in the current changeset. 
		$changes = "$($env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI)_apis/tfvc/changesets/$($commitID)/changes?api-version=1.0&`$top=$top&`$skip=$skip"
		$changesFiles = (Invoke-WebRequest -Uri $changes -Headers $headers -UseBasicParsing) | ConvertFrom-Json
		
		# Add the current changes list of files to the files we need to write out. 
		$files = $changesFiles.value
		
		# See if there are any more pages of changes for this changeset. 
		while ($changesFiles.value.count -ge $pageSize) {

			# Move the pagination forward one page. 
			$skip = $skip + $pageSize

			# REST request for the next page of files changed in the current changeset. 
			$changes = "$($env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI)_apis/tfvc/changesets/$($commitID)/changes?api-version=1.0&`$top=$top&`$skip=$skip"
			$changesFiles = (Invoke-WebRequest -Uri $changes -Headers $headers -UseBasicParsing) | ConvertFrom-Json
			$files = $files + $changesFiles.value
		}

		# For each of the files in the changeset we need to add them to the list of files triggering this build. 
		$files | ForEach-Object {

			# FileModificationItem node
			[System.XML.XMLElement]$modificationItem = $arrayOfModifications.AppendChild($xmlDoc.CreateElement("FileModificationItem"))
			$modificationItem.SetAttribute("name", $_.item.path) | Out-Null
			[System.XML.XMLElement]$values = $modificationItem.AppendChild($triggerXMLDoc.CreateElement("values"))
		    	
			# Value Version node
			[System.XML.XMLElement]$version = $values.AppendChild($triggerXMLDoc.CreateElement("value"))
			$version.SetAttribute("type", "Version") | Out-Null
			$version.InnerText = $_.item.version
			
			# Value User node
			[System.XML.XMLElement]$user = $values.AppendChild($triggerXMLDoc.CreateElement("value"))
			$user.SetAttribute("type", "User") | Out-Null
			$user.InnerText = $change.author.displayName
			
			# Value Comment node
			[System.XML.XMLElement]$comment = $values.AppendChild($triggerXMLDoc.CreateElement("value"))
			$comment.SetAttribute("type", "Comment") | Out-Null
			$comment.InnerText = $change.message
			
			# Value Action node
			[System.XML.XMLElement]$action = $values.AppendChild($triggerXMLDoc.CreateElement("value"))
			$action.SetAttribute("type", "Action") | Out-Null
			$action.InnerText = $_.changeType
		}
	}
}

function Write-TriggerFiles-Git([System.XML.XMLDocument]$xmlDoc, [System.XML.XMLElement]$arrayOfModifications,  $changesets) {
	
	if ($changesets.count -eq 0) {
		return
	}
	
	# Build the headers early as we will need them for each iteration. 
	$personalAccessToken = $vssEndpoint.Authorization.Parameters.AccessToken
	$headers = @{Authorization = "Bearer $personalAccessToken"}

	# From each changeset we need to get the list of files changed 
	$changesets | ForEach-Object {
				
		# Init our pagination variables.
		$top = $pageSize
		$skip = 0;
		
		$change = $_
		# REST request for the first page of files changed in the current commit. 
		$commit = "$($change.url)/changes?api-version=1.0&top=$top&skip=$skip"
		$commitFiles = (Invoke-WebRequest -Uri $commit -Headers $headers -UseBasicParsing) | ConvertFrom-Json
		
		# Add the current changes list of files to the files we need to write out. 
		$files = $commitFiles.changes

		# See if there are any more pages of changes for this commit.
		while ($commitFiles.changes.count -ge $pageSize) {
			# Move the pagination forward one page. 
			$skip = $skip + $pageSize

			# REST request for the next page of files changed in the current commit. 
			$commit = "$($change.url)/changes?api-version=1.0&top=$top&skip=$skip"
			$commitFiles = (Invoke-WebRequest -Uri $commit -Headers $headers -UseBasicParsing) | ConvertFrom-Json
			$files = $files + $commitFiles.changes
		}

		# For each of the files in the commit we need to add them to the list of files triggering this build. 
		$files | ForEach-Object {
			
			# FileModificationItem node
			[System.XML.XMLElement]$modificationItem = $arrayOfModifications.AppendChild($triggerXMLDoc.CreateElement("FileModificationItem"))
			$modificationItem.SetAttribute("name", $_.item.path) | Out-Null
			[System.XML.XMLElement]$values = $modificationItem.AppendChild($triggerXMLDoc.CreateElement("values"))
		    	
			# TODO: Find out how to get the version of the file. It is not in the JSON returned. 
			#[System.XML.XMLElement]$version = $values.AppendChild($triggerXMLDoc.CreateElement("value"))
			#$version.SetAttribute("type", "Version") | Out-Null
			#$version.InnerText = $_.item.version
			
			# Value User node
			[System.XML.XMLElement]$user = $values.AppendChild($triggerXMLDoc.CreateElement("value"))
			$user.SetAttribute("type", "User") | Out-Null
			$user.InnerText = $change.author.name
			
			# Value Comment node
			[System.XML.XMLElement]$comment = $values.AppendChild($triggerXMLDoc.CreateElement("value"))
			$comment.SetAttribute("type", "Comment") | Out-Null
			$comment.InnerText = $change.comment
			
			# Value Action node
			[System.XML.XMLElement]$action = $values.AppendChild($triggerXMLDoc.CreateElement("value"))
			$action.SetAttribute("type", "Action") | Out-Null
			$action.InnerText = $_.changeType
		}
	}
}

function Write-TriggerFiles($vssEndpoint, $changesets, $buildDef) {
	
	# Create a new XML File with config root node
	[System.XML.XMLDocument]$triggerXMLDoc = New-Object System.XML.XMLDocument
	
	# TriggerOutput Node
	[System.XML.XMLElement]$triggerRoot = $triggerXMLDoc.CreateElement("TriggerOutput")
	$triggerXMLDoc.appendChild($triggerRoot) | Out-Null
	$triggerRoot.SetAttribute("TriggerName", "TFS 2015") | Out-Null
	
	# ArrayOfModifications Node
	[System.XML.XMLElement]$arrayOfModifications = $triggerRoot.AppendChild($triggerXMLDoc.CreateElement("ArrayOfModifications"))
		
	# Based on the repository type we read the change files differently. The xml nodes are the same however. 
	if ($buildDef.repository.type -eq "TfsVersionControl") {
		Write-TriggerFiles-TFS $triggerXMLDoc $arrayOfModifications $changesets		
	} elseif ($buildDef.repository.type -eq "TfsGit") {
		Write-TriggerFiles-Git $triggerXMLDoc $arrayOfModifications $changesets		
	}

	# Generate a random temp file for the trigger xml to be saved to. This will be deleted by FinalBuilder once the process has finished. 	
	$triggerFilename = $env:temp + [System.IO.Path]::GetRandomFileName()
	$triggerXMLDoc.Save($triggerFilename)

	return $triggerFilename
}

function Get-FinalBuilder8-Location() {
	#Use the default location if none others are found. 
	$directory = "C:\\Program Files (x86)\\FinalBuilder 8\\"
	
	# The registry key that FinalBuilder stores its installation path to. 
	[System.String] $fbreg = "SOFTWARE\VSoft\FinalBuilder\8.0\"

	# Make sure to open the key as 32-bit as the installer will install to 32-bit
	$key = [Microsoft.Win32.RegistryKey]::OpenBaseKey(
		[Microsoft.Win32.RegistryHive]::LocalMachine, 
		[Microsoft.Win32.RegistryView]::Registry32) 

	$subKey = $key.OpenSubKey($fbreg) 
	
	# If we find the key then the directory value is the location of the installation.
	if ($subKey) {
		$directory = $subKey.GetValue("Directory")
	} else {
		# Otherwise there is something wrong with the installation.
		throw ("Unable to locate registry keys for installation of FinalBuilder 8. Please re-install FinalBuilder 8. If the problem persists contact support@finalbuilder.com.")
	}

	# Make sure that the path exists, if not tell the user. 
	if ( -not (Test-Path $directory -PathType Container)) {
		throw ("Current installed registry keys point to FinalBuilder 8 being installed at [$directory]. The directory does not exist. Please re-install FinalBuilder 8. If the problem persists contact support@finalbuilder.com.")
	}

	return $directory
}

Write-Verbose "Entering script FinalBuilder.ps1"

Write-Verbose "projectfile   = $projectfile"
Write-Verbose "cws           = $cwd"
Write-Verbose "dropfolder    = $dropfolder"
Write-Verbose "targets       = $targets"
Write-Verbose "solutionfile  = $solutionfile"
Write-Verbose "platform      = $platform"
Write-Verbose "flavor        = $flavor"
Write-Verbose "customArgs    = $customArgs"
Write-Verbose "respository   = $env:BUILD_REPOSITORY_PROVIDER"

# Import the Task.Common dll that has all the cmdlets we need for Build
import-module "Microsoft.TeamFoundation.DistributedTask.Task.Common"

Set-Variable pageSize -option Constant -value 50

# Find working directory. cwd is optional, we use directory of wrapper as working directory if not set.
if(!$cwd)
{
    $projectfilePath = Get-Item -Path $projectfile
    $cwd = $projectfilePath.Directory.FullName
}

# Work out of the solution file contains a search string
if ($solutionfile.Contains("*") -or $solutionfile.Contains("?"))
{
	# If the solution file contains a search string then look for the files the search matches
    Write-Verbose "Pattern found in solution parameter. Calling Find-Files."
    Write-Verbose "Calling Find-Files with pattern: $solutionfile"
    $sourcesDirectory = Get-TaskVariable -Context $distributedTaskContext -Name "Build.SourcesDirectory"
    $solutionfiles = Find-Files -SearchPattern $solutionfile -RootFolder $sourcesDirectory
    	
	if ($solutionfiles -isnot [system.array]) {
		$solutionfiles = ,$solutionfiles
	}
			
	Write-Verbose "Found files: $solutionfiles"
}
else
{
	# Otherwise simply use the solution file string as is. Make sure that the solution list however is an array.
    Write-Verbose "No Pattern found in solution parameter."
    $solutionfiles = ,$solutionfile
}

# The default solution file is always the first solution in the list of solutions found. 
$solutionfile = $solutionfiles[0]

# Get service end point for all our REST calls into TFS and TFS-Git
$vssEndPoint = Get-ServiceEndPoint -Name "SystemVssConnection" -Context $distributedTaskContext

# Work out when the last build was so that we can get the changes since that build. 
$buildDef = Get-BuildDefinition $vssEndPoint
$lastFailedBuild = Get-LastFailedBuild $vssEndPoint $buildDef.definition.id
$lastSuccessBuild = Get-LastSuccessfulBuild $vssEndPoint $buildDef.definition.id

$fromDate = ""

# The date to get changes from is either the last successful build, or the last failed build, or from the start of the repository. 
if ($lastSuccessBuild -ne $null) {
	$fromDate = $lastSuccessBuild.startTime
} elseif ($lastFailedBuild -ne $null) {
	$fromDate = $lastFailedBuild.startTime
}

# Get the change sets since the date worked out above
$changesetsSince = Get-ChangesetsSince -vssEndpoint $vssEndPoint -buildDef $buildDef -fromDate $fromDate

Write-Verbose "Changesets Since $changesetsSince"

# Build the trigger files xml file based on the changesets found above
$triggerFile = Write-TriggerFiles $vssEndPoint $changesetsSince $buildDef

Write-Verbose "Updating Environment Vars"

# Pass all the TFS build environment variables to the process so that FinalBuilder can pick them up. The Get Team Foundation Build Parameters action accesses these environment variables. 
Set-FB8EnvironmentVars -buildPlatform $platform -buildFlavor $flavor -dropFolder $dropfolder -solutionRoot $cwd -workingDirectory $cwd -solutionFile $solutionfile -solutionfileList $solutionfiles -customArgs $customArgs

# Details of available variables are at https://www.visualstudio.com/en-us/docs/build/define/variables
Write-Verbose "_envTeamServer        = $env:_envTeamServer"
Write-Verbose "_envTeamProject       = $env:_envTeamProject"
Write-Verbose "_envTeamBuildId       = $env:_envTeamBuildId"
Write-Verbose "_envBuildPlatform     = $env:_envBuildPlatform"
Write-Verbose "_envBuildFlavor       = $env:_envBuildFlavor"
Write-Verbose "_envDropFolder        = $env:_envDropFolder"
Write-Verbose "_envSolutionRoot      = $env:_envSolutionRoot"
Write-Verbose "_envWorkingDirectory  = $env:_envWorkingDirectory"
Write-Verbose "_envSolutionFile      = $env:_envSolutionFile"
Write-Verbose "_envSolutionFileList  = $env:_envSolutionFileList"

Write-Verbose "BUILD_BUILDNUMBER     = $env:BUILD_BUILDNUMBER"

# Make sure that we have a working directory set of the process 
Write-Verbose "Setting working directory to $cwd"
Set-Location $cwd

Write-Verbose "Generating Arguments"

# Build up the arguments for the FinalBuilder version that we are running. Currently that is only FinalBuilder 8. 
$fbArgs = Get-FB8Arguments -fbProjectFile $projectFile -noBanner $TRUE -triggerFilename $triggerFile -targets $targets
$fb8Path = Get-FinalBuilder8-Location 
$fb8Path = "$fb8Path\fbcmd.exe"

Write-Verbose "Args = $fbArgs" 
Write-Verbose "FB8 Path = $fb8Path"

Write-Output "******************************************************************************"
Write-Output "Invoking FinalBuilder 8"

# Run FinalBuilder 8 passing all the arguments we have gathered. The environment is where all other "variables" are passed. 
Invoke-Tool -Path $fb8Path -Arguments $fbArgs
Write-Output "******************************************************************************"

Write-Verbose "Leaving script FinalBuilder.ps1"