#Total Rules from Files:

# SAFEQ6 INTERSERVER RULES (INBOUND)
New-NetFirewallRule -DisplayName "YSoft_SAFEQ_MGMT_MGMT" -Protocol TCP -Direction Inbound -LocalPort 6020,4001,4099 -RemoteAddress Any -Action allow
# New-NetFirewallRule -DisplayName "YSoft_SAFEQ_MGMT_ETCD" -Protocol TCP -Direction Inbound -LocalPort 2379,2380 -RemoteAddress Any -Action allow
New-NetFirewallRule -DisplayName "YSoft_SAFEQ_SPOC_MGMT" -Protocol TCP -Direction Inbound -LocalPort 6010 -RemoteAddress Any -Action allow
New-NetFirewallRule -DisplayName "YSoft_SAFEQ_SPOC_MGMT" -Protocol TCP -Direction Inbound -LocalPort 6010,8000 -RemoteAddress Any -Action allow
New-NetFirewallRule -DisplayName "YSoft_SAFEQ_TS_TS" -Protocol TCP -Direction Inbound -LocalPort 2377,2378 -RemoteAddress Any -Action allow
New-NetFirewallRule -DisplayName "YSoft_SAFEQ_SPOC_SPOC" -Protocol TCP -Direction Inbound -LocalPort 5555,81,446,7800 -RemoteAddress Any -Action allow


# SAFEQ6 CLIENT TO SERVER (SERVER INBOUND)
New-NetFirewallRule -DisplayName "YSoft_SAFEQ_Client_MGMT" -Protocol TCP -Direction Inbound -LocalPort 80,443 -Action allow
New-NetFirewallRule -DisplayName "YSoft_SAFEQ_Client_FSP" -Protocol TCP -Direction Inbound -LocalPort 515,5559,9100 -Action allow
New-NetFirewallRule -DisplayName "YSoft_SAFEQ_Client_EUI" -Protocol TCP -Direction Inbound -LocalPort 9090,9443 -Action allow

# SAFEQ6 CLIENT V3 TO SERVER (SERVER INBOUND)
New-NetFirewallRule -DisplayName "YSoft_SAFEQ_Client_JS" -Protocol TCP -Direction Inbound -LocalPort 5000,5002 -Action allow
### Windows workstations
New-NetFirewallRule -DisplayName "YSoft_SAFEQ_Client_WIN" -Protocol TCP -Direction Inbound -LocalPort 515,631,632 -Action allow
### MAC workstations
New-NetFirewallRule -DisplayName "YSoft_SAFEQ_Client_MAC" -Protocol TCP -Direction Inbound -LocalPort 5515,5631,5632 -Action allow
New-NetFirewallRule -DisplayName "YSoft_SAFEQ_Client_EUI" -Protocol TCP -Direction Inbound -LocalPort 9090,9443 -Action allow

# SAFEQ6 DEVICE TO SERVER (SERVER INBOUND)
### Must have
New-NetFirewallRule -DisplayName "YSoft_SAFEQ_Device_TS_ET" -Protocol TCP -Direction Inbound -LocalPort 5011,5012,5021,5022 -Action allow

### Device Dependent 
New-NetFirewallRule -DisplayName "YSoft_SAFEQ_Device_TS_KM" -Protocol TCP -Direction Inbound -LocalPort 5014-5019 -Action allow
New-NetFirewallRule -DisplayName "YSoft_SAFEQ_Device_TS_Xerox_XCP" -Protocol TCP -Direction Inbound -LocalPort 5013,5029 -Action allow
New-NetFirewallRule -DisplayName "YSoft_SAFEQ_Device_TS_FujiFilm" -Protocol TCP -Direction Inbound -LocalPort 5013,5029 -Action allow
New-NetFirewallRule -DisplayName "YSoft_SAFEQ_Device_TS_HardwareTerminal" -Protocol TCP -Direction Inbound -LocalPort 4096 -Action allow
New-NetFirewallRule -DisplayName "YSoft_SAFEQ_Device_TS_HP" -Protocol TCP -Direction Inbound -LocalPort 5025 -Action allow
New-NetFirewallRule -DisplayName "YSoft_SAFEQ_Device_TS_Epson" -Protocol TCP -Direction Inbound -LocalPort 5023,5024 -Action allow
New-NetFirewallRule -DisplayName "YSoft_SAFEQ_Device_TS_Scanning" -Protocol TCP -Direction Inbound -LocalPort 21,5610 -Action allow

#SAFEQ6 INTERSERVER RULES (OUTBOUND RULES)
New-NetFirewallRule -DisplayName "YSoft_SAFEQ_MGMT_MGMT" -Protocol TCP -Direction Outbound -LocalPort 6020,4001,4099 -RemoteAddress Any -Action allow
New-NetFirewallRule -DisplayName "YSoft_SAFEQ_TS_IMS" -Protocol TCP -Direction Outbound -LocalPort 7347,7348 -RemoteAddress Any -Action allow
New-NetFirewallRule -DisplayName "YSoft_SAFEQ_MSSQL" -Protocol TCP -Direction Outbound -LocalPort 1433 -RemoteAddress Any -Action allow
New-NetFirewallRule -DisplayName "YSoft_SAFEQ_PGSQL" -Protocol TCP -Direction Outbound -LocalPort 5432 -RemoteAddress Any -Action allow
New-NetFirewallRule -DisplayName "YSoft_SAFEQ_SPOC_SPOC" -Protocol TCP -Direction Outbound -LocalPort 5555,81,446,7800 -RemoteAddress Any -Action allow

# YSOFT PAYMENT SYSTEM RULES 
New-NetFirewallRule -DisplayName "SMB_UDP_In" -Protocol UDP -Direction Inbound -LocalPort 8443 -RemoteAddress Any -Action allow

# SMB RULES (INBOUND)
New-NetFirewallRule -DisplayName "SMB_TCP_In" -Protocol TCP -Direction Inbound -LocalPort 445 -RemoteAddress Any -Action allow
New-NetFirewallRule -DisplayName "SMB_UDP_In" -Protocol UDP -Direction Inbound -LocalPort 137,138,139 -RemoteAddress Any -Action allow

# SMB RULES (OUTBOUND)
New-NetFirewallRule -DisplayName "SMB_TCP_Out" -Protocol TCP -Direction Outbound -LocalPort 445 -RemoteAddress Any -Action allow
New-NetFirewallRule -DisplayName "SMB_UDP_Out" -Protocol UDP -Direction Outbound -LocalPort 137,138,139 -RemoteAddress Any -Action allow

# Device Dependent (OUTBOUND RULES)
#New-NetFirewallRule -DisplayName "YSoft_SAFEQ_Epson_Install" -Protocol TCP -Direction Outbound -LocalPort 80,443 -RemoteAddress Any -Action allow
#New-NetFirewallRule -DisplayName "YSoft_SAFEQ_Ricoh_Install" -Protocol TCP -Direction Outbound -LocalPort 80,8080,443,50443,64098 -RemoteAddress Any -Action allow
#New-NetFirewallRule -DisplayName "YSoft_SAFEQ_KM_Install" -Protocol TCP -Direction Outbound -LocalPort 50001.50003 -RemoteAddress Any -Action allow
#New-NetFirewallRule -DisplayName "YSoft_SAFEQ_FujiFilm_Install" -Protocol TCP -Direction Outbound -LocalPort 58070 -RemoteAddress Any -Action allow
#New-NetFirewallRule -DisplayName "YSoft_SAFEQ_HP_Install" -Protocol TCP -Direction Outbound -LocalPort 57627 -RemoteAddress Any -Action allow
#New-NetFirewallRule -DisplayName "YSoft_SAFEQ_Toshiba_Install" -Protocol TCP -Direction Outbound -LocalPort 49629,49630,50083 -RemoteAddress Any -Action allow
#New-NetFirewallRule -DisplayName "YSoft_SAFEQ_HP_Install" -Protocol TCP -Direction Outbound -LocalPort 57627 -RemoteAddress Any -Action allow
#New-NetFirewallRule -DisplayName "YSoft_SAFEQ_Xerox_Install" -Protocol TCP -Direction Outbound -LocalPort 80,443 -RemoteAddress Any -Action allow
