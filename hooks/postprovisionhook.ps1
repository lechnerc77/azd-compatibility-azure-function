#!/usr/bin/env pwsh

Write-Host "Here are the env variables after provisioning"

Get-ChildItem Env: | Sort-Object Name | Format-Table -Wrap
