$InstallScomServersCd = @{

    AllNodes = @(
          @{
           NodeName = 'localhost'
           PSDscAllowPlainTextPassword = $true
           }

    )
}