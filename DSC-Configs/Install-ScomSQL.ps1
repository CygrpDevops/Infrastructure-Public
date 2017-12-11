Configuration Install-SQLBox
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$PackagePath,

        [Parameter(Mandatory)]
		[System.Management.Automation.PSCredential]$AdminCreds,
		
		[Parameter(Mandatory)]
		[System.Management.Automation.PSCredential]$FileShareCreds,
		
		[Parameter(Mandatory)]
		[System.Management.Automation.PSCredential]$SQLAgentCreds,
		
		[Parameter(Mandatory)]
		[System.Management.Automation.PSCredential]$SQLServiceCreds,
		
		[Parameter(Mandatory)]
		[System.Management.Automation.PSCredential]$SQLSAAccountCreds,
		
		[Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$Features,
		
		[Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$UpdateSource,
		
		[Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$UpdateEnabled,
		
		[Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$InstallSharedDir,
		
		[Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$InstallSharedWOWDir,
		
		[Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$SQLInstanceName,
		
		[Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$SQLInstanceDir,
		
		[Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$SecurityMode,
		
		[Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$SQLSysAdminAccounts
		

    )
	Import-DscResource -ModuleName xSQLServer,xWebAdministration
			
    Node localhost
    {
        

        #
        # Ensure that .NET framework features are installed (pre-reqs for SQL)
        #
       WindowsFeature "Web-WebServer"
            {
                Ensure = "Present"
                Name = "Web-WebServer"
            }

            WindowsFeature "Web-Request-Monitor"
            {
                Ensure = "Present"
                Name = "Web-Request-Monitor"
            }

            WindowsFeature "Web-Windows-Auth"
            {
                Ensure = "Present"
                Name = "Web-Windows-Auth"
            }

            WindowsFeature "Web-Asp-Net"
            {
                Ensure = "Present"
                Name = "Web-Asp-Net"
            }

            WindowsFeature "Web-Asp-Net45"
            {
                Ensure = "Present"
                Name = "Web-Asp-Net45"
            }

            WindowsFeature "NET-WCF-HTTP-Activation45"
            {
                Ensure = "Present"
                Name = "NET-WCF-HTTP-Activation45"
            }

            WindowsFeature "Web-Mgmt-Console"
            {
                Ensure = "Present"
                Name = "Web-Mgmt-Console"
            }

            WindowsFeature "Web-Metabase"
            {
                Ensure = "Present"
                Name = "Web-Metabase"
            }
         
	    Log ParamLog
        {
            Message = "Running SQLInstall. PackagePath = $PackagePath"
        }

		
		xSQLServerSetup SQLServerSetup

		{           
            SourcePath = $PackagePath
            SourceCredential = $FileShareCreds           
            PsDscRunAsCredential  = $AdminCreds
			SQLSvcAccount = $SQLServiceCreds
            AgtSvcAccount = $SQLAgentCreds
			SAPWd = $SQLSAAccountCreds		
			InstanceName =  $SQLInstanceName  
			InstanceDir = $SQLInstanceDir  
            SecurityMode =  $SecurityMode 
            SQLSysAdminAccounts =  @($SQLSysAdminAccounts)
			UpdateSource = $UpdateSource 
     		InstallSharedDir = $InstallSharedDir
            InstallSharedWOWDir = $InstallSharedWOWDir
			Features = $Features 
			UpdateEnabled =  $UpdateEnabled 
        }

        #adding sql server feature firewall rules.
        xSqlServerFirewall SqlFirewallRules
        {
                        DependsOn = '[xSQLServerSetup]SQLServerSetup'
                        Ensure = "Present"
                        SourcePath = $PackagePath
                        InstanceName = $SQLInstanceName
                        Features = $Features
        }                       
   
		LocalConfigurationManager 
        {
            RebootNodeIfNeeded = $True
        }

    }
}
