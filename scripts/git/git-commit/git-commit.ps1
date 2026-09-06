# Requires -Version 5.1
# encoding: UTF-8
$ErrorActionPreference = 'Stop'

function Read-Choice([string]$Prompt, [int]$Min, [int]$Max) {
  while ($true) {
    $raw = Read-Host -Prompt $Prompt
    $num = 0
    if ([int]::TryParse($raw, [ref]$num) -and $num -ge $Min -and $num -le $Max) {
      return $num
    } else {
      Write-Host "❌ Lựa chọn không hợp lệ."
    }
  }
}

# --- 1) (ĐÃ BỎ) Ticket redmine ---
# Không còn prefix ticket.

# --- 2) Emoji mapping + types ---
$emojiMap = @{
  feat    = "✨"; fix    = "🐛"; docs   = "📝"; style  = "💄"
  refactor= "♻️"; test   = "✅"; chore  = "🔧"; build  = "🏗️"
  perf    = "⚡";  ci     = "👷"; revert = "⏪"
}
$types = @('feat','fix','docs','style','refactor','test','chore','build','perf','ci','revert')

# --- 3) Hiển thị menu chọn loại commit ---
Write-Host "-----------------------"
Write-Host "Chọn loại commit:"
for ($i = 0; $i -lt $types.Count; $i++) {
  $t = $types[$i]
  "{0,2}) {1,-10} {2}" -f ($i+1), $t, $emojiMap[$t] | Write-Host
}
Write-Host "-----------------------"

$typeIndex = Read-Choice -Prompt "Nhập số tương ứng với loại commit:" -Min 1 -Max $types.Count
$type   = $types[$typeIndex - 1]
$emoji  = $emojiMap[$type]

# --- 4) Scope ---
$scope = Read-Host -Prompt "Nhập tên module (ví dụ: login, product)... (Enter để bỏ qua):"
if (-not [string]::IsNullOrWhiteSpace($scope)) {
  $scope = "($scope)"
} else {
  $scope = ""
}

# --- 5) Summary ---
while ($true) {
  $message = Read-Host -Prompt "Nhập mô tả ngắn gọn (Summary, < 100 ký tự):"
  if ([string]::IsNullOrWhiteSpace($message)) {
    Write-Host "⚠️  Mô tả không được để trống."
    continue
  }
  if ($message.Length -ge 100) {
    Write-Host "⚠️  Mô tả quá dài. Vui lòng viết ngắn lại."
    continue
  }
  break
}

# --- 6) Description (luôn mở bằng Neovim) ---
$tmp = New-TemporaryFile
"# Nhập mô tả chi tiết bên dưới. Các dòng bắt đầu bằng # sẽ bị bỏ qua." | Set-Content -Path $tmp -Encoding UTF8

try {
  # Mở nvim và chờ người dùng đóng lại
  & nvim $tmp
} catch {
  Write-Error "❌ Không tìm thấy lệnh 'nvim'. Hãy cài Neovim hoặc thêm vào PATH."
  exit 1
}

# Lọc bỏ dòng comment bắt đầu bằng '#'
$detailLines = Get-Content -Path $tmp -Encoding UTF8 | Where-Object { $_ -notmatch '^\s*#' }
$detailedMessage = ($detailLines -join "`n").Trim()
Remove-Item -Path $tmp -Force -ErrorAction SilentlyContinue

# --- 7) Ghép commit message ---
$summary = "{0}{1}: {2} {3}" -f $type, $scope, $emoji, $message
if (-not [string]::IsNullOrWhiteSpace(($detailedMessage -replace '\s',''))) {
  $commitContent = $summary + "`n`n" + $detailedMessage
} else {
  $commitContent = $summary
}

# --- 8) Lưu & commit ---
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$commitMsgFile = Join-Path $scriptDir '.last-commit-msg'

# Ghi UTF-8 để không lỗi emoji/tiếng Việt
Set-Content -Path $commitMsgFile -Value $commitContent -Encoding UTF8

Write-Host ""
Write-Host "✅ Commit message được tạo:"
Write-Host "---------------------------"
Get-Content -Path $commitMsgFile -Encoding UTF8 | ForEach-Object { $_ }
Write-Host "---------------------------"

$confirm = Read-Host -Prompt "Bạn có muốn commit ngay không? [Y/n]"
if ([string]::IsNullOrWhiteSpace($confirm)) { $confirm = "y" }
if ($confirm -match '^[Yy]$') {
  & git commit -F $commitMsgFile
} else {
  Write-Host "📌 Bạn có thể commit lại bằng lệnh:"
  Write-Host "git commit -F `"$commitMsgFile`""
}

