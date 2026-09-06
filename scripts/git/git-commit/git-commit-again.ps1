# Requires -Version 5.1
# encoding: UTF-8
$ErrorActionPreference = 'Stop'

# --- Đường dẫn file commit message cạnh script ---
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$CommitMsgFile = Join-Path $ScriptDir '.last-commit-msg'

# --- Kiểm tra tồn tại ---
if (-not (Test-Path -Path $CommitMsgFile -PathType Leaf)) {
  Write-Host "❌ Không tìm thấy file commit message: $CommitMsgFile"
  Write-Host "👉 Bạn cần chạy script tạo commit trước (git-commit.ps1 hoặc script tương đương)."
  exit 1
}

Write-Host "📦 Đang commit lại với message từ:"
Write-Host $CommitMsgFile
Write-Host ""

# --- Thực hiện commit ---
try {
  & git commit -F $CommitMsgFile
} catch {
  Write-Error "Commit thất bại: $($_.Exception.Message)"
  exit 1
}

