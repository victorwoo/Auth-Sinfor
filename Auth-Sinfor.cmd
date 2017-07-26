@ECHO OFF

SET BaseUrl=http://1.1.1.2/

powershell -NoProfile -ExecutionPolicy Unrestricted .\%~n0.ps1 -BaseUrl %BaseUrl%