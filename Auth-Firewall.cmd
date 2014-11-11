@ECHO OFF

SET BaseUrl=http://172.20.6.254/
SET UserName=wub
SET Password=YOUR_PASSWORD_HERE

powershell -NoProfile -ExecutionPolicy Unrestricted .\%~n0.ps1 -BaseUrl %BaseUrl% -UserName %UserName% -Password %Password%