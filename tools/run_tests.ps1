$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$godot = $env:GODOT_BIN
if (-not $godot) {
	$godot = Join-Path $PSScriptRoot "godot\Godot_v4.6-stable_win64_console.exe"
}
if (-not (Test-Path $godot)) {
	throw "Godot 4.6 console binary not found. Set GODOT_BIN or place it at tools/godot/Godot_v4.6-stable_win64_console.exe"
}
& $godot --headless --path $root --import
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $godot --headless --path $root --script res://tests/rules_test.gd
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $godot --headless --path $root --script res://tests/smoke.gd
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $godot --headless --path $root --script res://tests/match_test.gd
exit $LASTEXITCODE
