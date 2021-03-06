<# 作業時間集計ツール #>
<# グローバル定数 START #>
$workFileDir = '.\Summary\Work'
$dailyFileDir = '.\Summary\Daily'
<# グローバル定数 END #>
<# グローバル変数 START #>
<# グローバル変数 END #>
<# 関数定義 START#>
<# 関数定義 END#>
<# Main START #>
$ym = Read-Host '集計する年月を入力してください。(yyyyMM)'
Write-Host "作業記録から、各タスクの所要時間を算出します。$(Get-Date -Format 'HH:mm:ss') 開始"
# 1レコードずつ、開始時刻と次のレコードの開始時刻から作業時間を算出
#ファイルを取得
$recordfiles = Get-ChildItem -Path .\Record -Filter "worktime_$($ym)*.csv"
#全てのファイルに対して処理
foreach ($recordFile in $recordfiles){
    #中間ファイル作成
    $workFileName = $recordFile.Name.Replace('worktime','summarywork')
    $workFileFullName = Join-Path  -Path $workFileDir -ChildPath $workFileName
    if (-not (Test-Path $workFileDir)){
        New-Item -Path $workFileDir -ItemType Directory
    }
    #中間ファイル作成&ヘッダ書き込み
    Set-Content -Path $workFileFullName -Value 'TaskName,StartAt,EndAt,WorkMinute' -Encoding UTF8
    #開始時刻が記録されているので、作業の所要時間を求める。
    $data = Import-Csv -Path $recordFile.FullName
    #計算：もっとスマートなやり方がありそうな気がする・・・。
    #前の行のタスク名と開始時刻
    $lastTaskName = [String]::Empty
    $lastStartTime = $null
    foreach ($work in $data){
        #今の行のタスク名と開始時刻
        $currentTaskName = $work.TaskName
        $currentStartTime = [System.DateTime]::ParseExact($work.StartAt,'yyyyMMddHHmm',$null)
        if($null -ne $lastStartTime){
            #所要時間を計算
            $lastWorkTimeSpan = $currentStartTime - $lastStartTime
            [String]$format = '{0},{1:yyyyMMddHHmm},{2:yyyyMMddHHmm},{3}'
            [String]$record = [String]::Format($format,$lastTaskName,$lastStartTime,$currentStartTime,$lastWorkTimeSpan.TotalMinutes)
            Add-Content -Path $workFileFullName -Value $record -Encoding UTF8
        }
        #「前の行のデータ」を退避
        $lastTaskName = $currentTaskName
        $lastStartTime = $currentStartTime
    }
    #ファイルが'end'以外で終了していた場合、一応出しておく。
    if ($lastTaskName -ne 'end') {
        [String]$format = '{0},{1:yyyyMMddHHmm},,0'
        [String]$record = [String]::Format($format,$lastTaskName,$lastStartTime)
        Add-Content -Path $workFileFullName -Value $record -Encoding UTF8
    }
}
# TODO:日計
Write-Host "各タスクの所要時間を合算してタスクごとの使用工数を算出します。$(Get-Date -Format 'HH:mm:ss') 開始"
#ファイルを取得
$workfiles = Get-ChildItem -Path $workFileDir -Filter "summarywork_$($ym)*.csv"
#全てのファイルに対して処理
foreach ($work in $workfiles){
    #Write-Host $work.FullName
    #中間ファイル作成
    $dailyFileName = $work.Name.Replace('summarywork','daily')
    $dailyFileFullName = Join-Path  -Path $dailyFileDir -ChildPath $dailyFileName
    if (-not (Test-Path $dailyFileDir)){
        New-Item -Path $dailyFileDir -ItemType Directory
    }
    #集計
    $data2 = Import-Csv -Path $work.FullName
    #タスク名でグループ化してworkMinuteを集計
    #https://qiita.com/arachan@github/items/0397065b405d601fcfa1
    $dailySummary = $data2 | Group-Object -Property TaskName | Select-Object -Property Name, @{Name = 'TotalMinute';Expression={($_.group | Measure-Object -Property WorkMinute -Sum).sum}}
    #出力
    $dailySummary | Export-Csv -Path $dailyFileFullName -Encoding UTF8 -NoTypeInformation
}
Write-Host "処理が完了しました。$(Get-Date -Format 'HH:mm:ss')"
<# Main END #>
