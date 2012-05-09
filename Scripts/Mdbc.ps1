
<#
.Synopsis
	Connects to a database and adds interactive helpers.

.Description
	Use it only as the example and base for your own interactive helpers. This
	script reflects personal preferences, its features may not be suitable for
	all scenarios and they may change at any time.

	The script imports the Mdbc module, connects to the server and database,
	and installs helper aliases and variables designed for interactive use.

	Global aliases:
		amd - Add-MdbcData
		gmd - Get-MdbcData
		rmd - Remove-MdbcData
		umd - Update-MdbcData
		nmd - New-MdbcData
		nmq - New-MdbcQuery
		nmu - New-MdbcUpdate

	Global variables:
		$mserver   - the server
		$mdatabase - the database
		$m<name>   - collection <name> (for each collection)

	Global variables for collections are especially useful with the tab
	expansion tool. Conflicts with system variables are highly unlikely.

	With a large number of collections their names are not displayed. Command
	Get-Variable m*..* is useful for finding a collection by its name pattern.

	EXAMPLE
		# connect to the default server and the database 'test'
		mdbc

		# get documents from 'files' where Length > 1GB
		gmd $mfiles (nmq Length -gt 1gb)

.Parameter ConnectionString
		Connection string (see the C# driver manual for details).
		The default is "." which stands for "mongodb://localhost".

.Parameter Database
		The database name.
		The default is 'test'.
#>

param
(
	[Parameter()]
	$ConnectionString = '.',
	$Database = 'test'
)

Import-Module Mdbc

# Aliases
Set-Alias -Scope global -Name amd -Value Add-MdbcData
Set-Alias -Scope global -Name gmd -Value Get-MdbcData
Set-Alias -Scope global -Name rmd -Value Remove-MdbcData
Set-Alias -Scope global -Name umd -Value Update-MdbcData
Set-Alias -Scope global -Name nmd -Value New-MdbcData
Set-Alias -Scope global -Name nmq -Value New-MdbcQuery
Set-Alias -Scope global -Name nmu -Value New-MdbcUpdate

# Server variable
$global:mserver = Connect-Mdbc $ConnectionString
Write-Host "Server `$mserver $($mserver.Settings.Server)"

# Database variable
$global:mdatabase = $mServer.GetDatabase($Database)
Write-Host "Database `$mdatabase $Database"

# Collection variables
$collections = @($mDatabase.GetCollectionNames())
$global:MaximumVariableCount += $collections.Count
Write-Host "$($collections.Count) collections"
foreach($name in $collections) {
	if (!$name.StartsWith('system.')) {
		if ($collections.Count -lt 50) { Write-Host "Collection `$m$name" }
		New-Variable -Scope global -Name "m$name" -Value $mDatabase.GetCollection($name) -ErrorAction Continue -Force
	}
}
