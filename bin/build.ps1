# This file is used by a bot to 
# automatically update Open-Scoop application.
# Please do not edit this file.

# Variables
$USER = $env:USERNAME
$SCOOP = scoop which scoop
if ( !$env:SCOOP_HOME ) { 
  $env:SCOOP_HOME = resolve-path (split-path (split-path (scoop which scoop))) 
}
$checkver = "C:\\Users\\$USER\\scoop\\apps\\scoop\\current\\bin\\checkver.ps1"
$dir = "C:\\Users\\$USER\\scoop\\proj\\open-scoop" 

#Start
Set-Location $HOME
Set-Location scoop/proj/open-scoop/bin

git pull > log.txt

$files = Get-ChildItem ../.\*.json
$i = 1;
Get-ChildItem ../.\*.json | Foreach-Object {
  $basename = $_.BaseName
  Write-Progress -Activity "Updating application manifests" -status "Scanning $basename.json" -percentComplete ($i / $files.count * 100)
  $out = ../../../apps/scoop/current/bin/checkver.ps1 -dir $dir -App $basename -u | Out-String
  git commit -q -a -m "Auto-updated $basename" > log.txt
  $i++
}

Set-Location ..

$major = Get-Content versdat/major.txt
$minor = Get-Content versdat/minor.txt
$build = Get-Content versdat/build.txt

if ($build -gt 255 -and $minor -lt 255) {
	$minor++
	$build = 0
}
else if ($build -gt 255 -and $minor -gt 255) {
	$build = 0
	$minor = 0
	$major++
}
else {
	$build++
}

Set-Content -Path versdat/major.txt -Value $major
Set-Content -Path versdat/minor.txt -Value $minor
Set-Content -Path versdat/build.txt -Value $build

$accesstoken = Get-Content versdat/acctok.txt

Write-Output "Finished updating app manifests"
Write-Output "Creating GitHub release ${major}.${minor}.${build}"

$version = "${major}.${minor}.${build}"

$DATA = '{"tag_name": "v$version","target_commitish": "master","name": "v$version","body": "Automatic release of v$version. Please see the README for installation information.","draft": false,"prerelease": false}'

curl --data "$DATA" https://api.github.com/repos/kiedtl/open-scoop/releases?access_token=$accesstoken


del log.txt