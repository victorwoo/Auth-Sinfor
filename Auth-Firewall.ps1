# requires -version 3

[CmdletBinding(DefaultParameterSetName = 'URI',
			   SupportsShouldProcess = $true,
			   ConfirmImpact = 'Medium')]
Param(
    [string]
    $BaseUrl = 'http://1.1.1.2',
    
    [bool]
    $ForceLogout = $true
)

function Convert-Encoding([string]$iso5589_1Str) {
    $utf8 = [System.Text.Encoding]::GetEncoding(65001) 
    $iso88591 = [System.Text.Encoding]::GetEncoding(28591) #ISO 8859-1 ,Latin-1

    $wrong_bytes = $utf8.GetBytes($iso5589_1Str)

    $right_bytes = [System.Text.Encoding]::Convert($utf8,$iso88591,$wrong_bytes) #仔细看这里 
    $right_string = $utf8.GetString($right_bytes)  #仔细看这里
    return $right_string
}

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
    # http://1.1.1.2/ajaxlogout?_t=1501033712947
    Write-Debug $logoutUrl
    $response = Invoke-RestMethod $logoutUrl -Proxy $null -DisableKeepAlive
    $msg = Convert-Encoding $response.msg
    Write-Debug "注销请求返回内容：$msg"
    return $content.success
}

# 登录
function Process-Login
{
    if (Test-Path 'credential.xml') {
        $credential = Import-Clixml -Path "credential.xml"
    } else {
        $credential = Get-Credential
        $credential | Export-Clixml -Path "credential.xml"
    }
    #$loginUrl = $BaseUrl + '/webAuth/'
    $portal = "$BaseUrl/ac_portal/default/pc.html?template=default&tabs=pwd&vlanid=0&url=http://news.baidu.com/"
    Write-Debug $portal
    $response = Invoke-WebRequest $portal -SessionVariable 'session' -Proxy $null -DisableKeepAlive

    # opr=pwdLogin&userName=wub&pwd=asdfasdf.04&rememberPwd=0
    $body = @{
        opr = 'pwdLogin';
        userName = $credential.UserName;
        pwd = $credential.GetNetworkCredential().Password;
        rememberPwd = 0
    }
    $loginUrl = "$BaseUrl/ac_portal/login.php"
    $response = Invoke-RestMethod $loginUrl `
        -Method Post `
        -Body $body `
        -ContentType 'application/x-www-form-urlencoded;charset=utf-8' `
        -SessionVariable 'session' `
        -Proxy $null `
        -DisableKeepAlive
    $msg = Convert-Encoding $response.msg
    Write-Debug "登录请求返回内容：$msg"

    return $response.success -or $msg -eq '用户已在线，不需要再次认证'
}

function Get-LoginStatus
{
    $response = Invoke-WebRequest news.baidu.com -UseBasicParsing -Proxy $null -DisableKeepAlive
    Write-Debug $response
    return -not $response.Content.Contains($BaseUrl)
}


#$DebugPreference="Continue"
$DebugPreference="SilentlyContinue"

$logName = 'Application'
$source = 'AuthFirewall'
$time = Get-Date
echo --------- >> log.txt
echo $time >> log.txt

$log = '检测登录状态'
Write-Output $log
echo $log >> log.txt
$needLogin = $false

if (Get-LoginStatus)
{
    $log = '已登录'
    Write-Output $log
    echo $log >> log.txt

    if (!$ForceLogout) {
        return
    }
    
    $log = '重新登录'
    Write-Output $log
    echo $log >> log.txt
    Process-Logout | Out-Null
    $needLogin = $true
} else {
    $needLogin = $true
}

if (!$needLogin) {
    return
}

$log = '尝试登录'
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