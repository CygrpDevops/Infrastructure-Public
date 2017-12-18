configuration Install-ScomServers
{
 param(
        
        [Parameter(Mandatory)]
		[System.Management.Automation.PSCredential]$SystemCenter2016OperationsManagerActionAccount,

        [Parameter(Mandatory)]
		[System.Management.Automation.PSCredential]$SystemCenter2016OperationsManagerDASAccount,

         [Parameter(Mandatory)]
		[System.Management.Automation.PSCredential]$SystemCenter2016OperationsManagerDataReader,

        [Parameter(Mandatory)]
		[System.Management.Automation.PSCredential]$SystemCenter2016OperationsManagerDataWriter,

        [Parameter(Mandatory)]
		[System.Management.Automation.PSCredential]$InstallerServiceAccount,

        [Parameter(Mandatory)]
		[string]$SystemCenter2016ProductKey,

        [Parameter(Mandatory)]
		[string]$SystemCenter2016OperationsManagerDatabaseServer,

        [Parameter(Mandatory)]
		[string]$SystemCenter2016OperationsManagerDatabaseInstance,

        [Parameter(Mandatory)]
		[string]$SystemCenter2016OperationsManagerDatabaseName,
        
        [Parameter(Mandatory)]
		[string]$SystemCenter2016OperationsManagerDatawarehouseDatabaseName,

        [Parameter(Mandatory)]
        [string]$MachineName,

        [Parameter(Mandatory)]
        [string]$ManagementGroupName,
        
        [Parameter(Mandatory)]
        [string]$PackagePath,

        [Parameter(Mandatory)]
        [string]$SQLServer2016SystemCLRTypesPath,

        [Parameter(Mandatory)]
        [string]$ReportViewer2016RedistributablePath
 
       )

    Import-DscResource -Module xCredSSP
    Import-DscResource -Module xSQLServer
    Import-DscResource -Module xSCOM


    # One can evaluate expressions to get the node list
    node localhost
    {
        
         # Set LCM to reboot if needed and debug mode  
           LocalConfigurationManager
            {
            RebootNodeIfNeeded = $true
            }

         # Install .NET Framework 3.5 on SQL and Web Console nodes    
            WindowsFeature "NET-Framework-Core"
            {
                Ensure = "Present"
                Name = "NET-Framework-Core"
            }

          # Install IIS on Web Console Servers

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


        # Add service accounts to admins on Management Servers
           Group "Administrators"
            {
                GroupName = "Administrators"
                MembersToInclude = @(
                    $SystemCenter2016OperationsManagerActionAccount.UserName,
                    $SystemCenter2016OperationsManagerDASAccount.UserName
                )
                Credential = $InstallerServiceAccount
            
             }

        # Install first Management Server
           
            # Enable CredSSP - required for ProductKey PS cmdlet
            xCredSSP "Server"
            {
                Ensure = "Present"
                Role = "Server"
            }

            xCredSSP "Client"
            {
                Ensure = "Present"
                Role = "Client"
                DelegateComputers = $MachineName
            }

            Package "SQLServer2014SystemCLRTypes"
            {
                Ensure = "Present"
                Name = "Microsoft System CLR Types for SQL Server 2014"
                ProductId = "68BA34E8-9B9D-4A74-83F0-7D366B532D75"
                Path = $SQLServer2016SystemCLRTypesPath
                Arguments = "ALLUSERS=2"
                Credential = $InstallerServiceAccount
            }


            Package "ReportViewer2015Redistributable"
            {
                DependsOn = "[Package]SQLServer2014SystemCLRTypes"
                Ensure = "Present"
                Name = "Microsoft Report Viewer 2015 Runtime"
                ProductID = "3ECE8FC7-7020-4756-A71C-C345D4725B77"
                Path = $ReportViewer2016RedistributablePath
                Arguments = "ALLUSERS=2"
                Credential = $InstallerServiceAccount
            }

            # Create DependsOn for first Management Server
            $DependsOn = @(
                "[xCredSSP]Server",
                "[xCredSSP]Client",
                "[Group]Administrators",
                "[Package]SQLServer2014SystemCLRTypes",
                "[Package]ReportViewer2015Redistributable"
            )

          
          
            # Install first Management Server
            xSCOMManagementServerSetup "OMMS"
            {
                DependsOn = $DependsOn
                Ensure = "Present"
                SourcePath = $PackagePath
                SourceFolder = ""
                SetupCredential = $InstallerServiceAccount
                ProductKey = $SystemCenter2016ProductKey
                ManagementGroupName = $ManagementGroupName
                FirstManagementServer = $true
                ActionAccount = $SystemCenter2016OperationsManagerActionAccount
                DASAccount = $SystemCenter2016OperationsManagerDASAccount
                DataReader = $SystemCenter2016OperationsManagerDataReader
                DataWriter = $SystemCenter2016OperationsManagerDataWriter
                SqlServerInstance = ($SystemCenter2016OperationsManagerDatabaseServer + "\" + $SystemCenter2016OperationsManagerDatabaseInstance)
                DatabaseName = $SystemCenter2016OperationsManagerDatabaseName
                DwSqlServerInstance = ($SystemCenter2016OperationsManagerDatabaseServer + "\" + $SystemCenter2016OperationsManagerDatabaseInstance)
                DwDatabaseName = $SystemCenter2016OperationsManagerDatawarehouseDatabaseName
            }


            # Install Report Viewer 2012 on Web Console Servers and Consoles

            

            
<#
             # Install Reporting Server
            xSCOMReportingServerSetup "OMRS"
            {
                DependsOn = "[xSCOMManagementServerSetup]OMMS"
                Ensure = "Present"
                SourcePath = $PackagePath
                SourceFolder = ""
                SetupCredential = $InstallerServiceAccount
                ManagementServer = $MachineName
                SRSInstance = ($SystemCenter2016OperationsManagerDatabaseServer + "\" + $SystemCenter2016OperationsManagerDatabaseInstance)
                DataReader = $SystemCenter2016OperationsManagerDataReader
            }
#>

            # Install Web Console Servers
            $DependsOn += @(
                "[WindowsFeature]NET-Framework-Core",
                "[WindowsFeature]Web-WebServer",
                "[WindowsFeature]Web-Request-Monitor",
                "[WindowsFeature]Web-Windows-Auth",
                "[WindowsFeature]Web-Asp-Net",
                "[WindowsFeature]Web-Asp-Net45",
                "[WindowsFeature]NET-WCF-HTTP-Activation45",
                "[WindowsFeature]Web-Mgmt-Console",
                "[WindowsFeature]Web-Metabase",
                "[Package]SQLServer2014SystemCLRTypes",
                "[Package]ReportViewer2015Redistributable",
                "[xSCOMManagementServerSetup]OMMS"
               # "[xSCOMReportingServerSetup]OMRS"
            )
           
            xSCOMWebConsoleServerSetup "OMWC"
            {
                DependsOn = $DependsOn
                Ensure = "Present"
                SourcePath = $PackagePath
                SourceFolder = ""
                SetupCredential = $InstallerServiceAccount
                ManagementServer = $MachineName
            }

            # Install Consoles
            xSCOMConsoleSetup "OMC"
            {
                DependsOn = @(
                    "[Package]SQLServer2014SystemCLRTypes",
                    "[Package]ReportViewer2015Redistributable",
                    "[xSCOMWebConsoleServerSetup]OMWC"
                )
                Ensure = "Present"
                SourcePath = $PackagePath
                SourceFolder = ""
                SetupCredential = $InstallerServiceAccount
            }

  
    }
}


