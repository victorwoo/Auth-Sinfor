[CmdletBinding(DefaultParameterSetName = 'URI',
			   SupportsShouldProcess = $true,
			   ConfirmImpact = 'Medium')]
Param(
    [string]
    $BaseUrl = 'http://172.20.6.254/',
    
    [string]
    $UserName = 'wub',
    
    [string]
    $Password = 'YOUR-PASSWORD-HERE'
)

function ConvertFrom-UnixTime {
  param(
      [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [Int32]
    $UnixTime
  )
  begin {
    $startdate = Get-Date –Date '01/01/1970' 
  }
  process {
    $timespan = New-Timespan -Seconds $UnixTime
    $startdate + $timespan
  }
}

# 模拟JS中的new Date().getTime()
function Get-JSTime
{
    $now = Get-Date
    $startDate = Get-Date -Date '01/01/1970'
    $timeSpan = $now - $startDate
    return [int64]$timeSpan.TotalMilliseconds
}

# 注销
function Process-Logout
{
    $logoutUrl = $BaseUrl + '/ajaxlogout?_t=' + (Get-JSTime)
    Write-Debug $logoutUrl
    $content = Invoke-RestMethod $logoutUrl
    Write-Debug "注销请求返回内容：$content"
    return $content.success
}

# 登录
function Process-Login
{
    #$loginUrl = $BaseUrl + 'webAuth/'
    $loginUrl = $BaseUrl + 'webAuth/index.htm?www.baidu.com/'
    Write-Debug $loginUrl
    $response = Invoke-WebRequest $loginUrl -SessionVariable $rb
    $form = $response.Forms[0]
    $form.Fields["username"] = $UserName
    $form.Fields["password"] = $Password
    $form.Fields["pwd"] = $Password
    $form.Fields["secret"] = 'true'

    $response = Invoke-WebRequest $loginUrl -Method Post -Body $form -WebSession $rb
    if ($response.Content -is [string])
    {
        $content = $response.Content
    } elseif ($response.Content -is [byte[]])
    {
        $content = [System.Text.Encoding]::UTF8.GetString($response.Content)
    }
 
    Write-Debug "登录请求返回内容：$content"
    if ($content.Contains('上网认证系统')) { return $false }
    return $true
}

function Get-LoginStatus
{
    $response = Invoke-WebRequest www.baidu.com -DisableKeepAlive
    return ($response.Content.Contains('百度'))
}


#$DebugPreference="Continue"
$DebugPreference="SilentlyContinue"
$logName = 'Application'
$source = 'AuthFirewall'

$time = Get-Date
echo $time >> log.txt

#return
$log = '检测登录状态'
Write-Output $log
echo $log >> log.txt

if (Get-LoginStatus)
{
    $log = '已登录'
    Write-Output $log
    echo $log >> log.txt
    return
}

$log = '未登录，尝试登录'
Write-Output $log
echo $log >> log.txt
if (Process-Login)
{
    $log = '登录成功'
    Write-Output $log
    echo $log >> log.txt
    return
}

$log = '尝试登录失败，尝试注销'
Write-Warning $log
echo $log >> log.txt
if (!(Process-Logout))
{
    $log = '注销失败'
    Write-Error $log
    echo $log >> log.txt
    return 1
}

$log = '注销成功，尝试登录'
Write-Output $log
echo $log >> log.txt
if (Process-Login)
{
    $log = '登录成功'
    Write-Output $log
    echo $log >> log.txt
    return
}

$log = '全部尝试失败'
Write-Error $log
echo $log >> log.txt
return 2

# -------- 以下用于开发 --------
return
{
    # 注销
    $result = Process-Logout
    Write-Output "注销结果：$result"
}

{
    # 登录
    $result = Process-Login
    Write-Output "登录结果：$result"
}

{
    # 获取登录状态
    $result = Get-LoginStatus
    Write-Output "判断登录状态：$result"
} 