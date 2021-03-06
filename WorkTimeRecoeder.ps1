<# 作業時間記録ツール #>
<# グローバル定数 START #>
<# コマンド関連 START #>
[String]$commandSepalater = '/'
[String]$endCommand = 'end'
[String]$timeCommand = 't:'
<# コマンド関連 END #>
<# グローバル定数 END #>

<# グローバル変数 START #>
[string]$currendDataFileName = [String]::Empty
[string]$currendDataFileFullName = [String]::Empty
<# グローバル変数 END #>

<# 関数定義 START#>
function Build-DataFileName(){
    param(
        [Parameter(Mandatory=$True)]
        [DateTime]$currentDate
    )
    begin{
        #echo "begin called!" 
    }
    process{
        #echo "process called!"
        [string]$filenNameFormet = 'worktime_{0:yyyyMMdd}.csv'
        $global:currendDataFileName = [String]::Format($filenNameFormet,$currentDate)
        [string]$filePath = '.\Record'
        $global:currendDataFileFullName = Join-Path -Path $filePath -ChildPath $global:currendDataFileName
    }
    end{
        #echo "end called!" 
    }
}
function Create-DataFile(){
    begin{}
    process{
        Set-Content -Path $global:currendDataFileFullName -Value 'TaskName,StartAt' -Encoding UTF8
    }
    end{}
}
function Add-Record(){
    param(
        [Parameter(Mandatory=$True)]
        [string]$taskName,
        [Parameter(Mandatory=$True)]
        [DateTime]$startAt
    )
    begin{
        #echo "begin called!" 
    }
    process{
        #echo "process called!"
        [string]$recordFormat = '{0},{1:yyyyMMddHHmm}'
        $record = [String]::Format($recordFormat,$taskName,$startAt)
        Add-Content -Path $global:currendDataFileFullName -Value $record -Encoding UTF8
    }
    end{
        #echo "end called!" 
    }
}
<# 関数定義 END#>

<# Main START #>
#データファイル関連のグローバル変数を設定
Build-DataFileName -CurrentDate (Get-Date)
#ファイルがなければ作成
if (-not (Test-Path -Path $global:currendDataFileFullName)){
    Create-DataFile
}
#起動を記録
$startUpTime = Get-Date
Write-Host '作業時間記録を開始します。'
Write-Host $startUpTime.ToString('yyyy/MM/dd HH:mm')
Add-Record -TaskName 'start' -StartAt $startUpTime

#入力を受け付ける
while($true){
    [string]$inputCommand = Read-Host 'タスクを開始したらタスク名を入力してください。'
    $split = $inputCommand.Split($commandSepalater)
    [bool]$isEnd = $false
    [string]$taskName = [String]::Empty
    [DateTime]$startAt = [DateTime]::MinValue
    if ($inputCommand.Contains($commandSepalater + $endCommand)) {
        #終了コマンドの場合
        $isEnd = $true
        $taskName = 'end'
    } else {
        #通常
        $taskName = ($split | Select-Object -First 1).Trim()
    }
    #開始時刻を取得
    if ($inputCommand.Contains($commandSepalater + $timeCommand)) {
        #入力されている場合は入力値を使う
        #時刻部分の取得。同じオプションが複数あったら先頭1件をとる。後は無視。
        $timePart = $split | Where-Object {$_.StartsWith($timeCommand)} | Select-Object -First 1
        $strTime = $timePart.Substring($timeCommand.Length,4) #時刻部分の切りだし
        $dtTime = [DateTime]::ParseExact($strTime,'HHmm',$null)
        $startAt = $dtTime
    } else {
        #入力がない場合は現在時刻
        $startAt = Get-Date
    }
    Add-Record -TaskName $taskName -StartAt $startAt
    
    if($isEnd){
        #終了コマンドが入力されてたら終了
        break
    }
}
Write-Host '記録を終了します。'
<# Main END #>