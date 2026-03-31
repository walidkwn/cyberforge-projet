@echo off
REM ================================================================
REM  CyberForge - Active Response: IP Block Script
REM  Author: KAOUANE WALID
REM
REM  Triggered by Wazuh when Rule 60204 fires (RDP brute force).
REM  Blocks the attacker IP via Windows Firewall for 600 seconds,
REM  then automatically removes the rule.
REM
REM  Wazuh passes the attacker IP as the first argument (%1).
REM  Deploy at: C:\Program Files (x86)\ossec-agent\active-response\bin\
REM ================================================================

SET ACTION=%1
SET USER=%2
SET IP=%3

IF "%ACTION%" == "add" (
    ECHO [%DATE% %TIME%] BLOCKING IP: %IP% >> C:\ossec-ar.log
    netsh advfirewall firewall add rule ^
        name="WAZUH_BLOCK_%IP%" ^
        protocol=any ^
        dir=in ^
        action=block ^
        remoteip=%IP%
    ECHO [%DATE% %TIME%] Rule added for %IP% >> C:\ossec-ar.log
)

IF "%ACTION%" == "delete" (
    ECHO [%DATE% %TIME%] UNBLOCKING IP: %IP% >> C:\ossec-ar.log
    netsh advfirewall firewall delete rule name="WAZUH_BLOCK_%IP%"
    ECHO [%DATE% %TIME%] Rule removed for %IP% >> C:\ossec-ar.log
)

EXIT 0
