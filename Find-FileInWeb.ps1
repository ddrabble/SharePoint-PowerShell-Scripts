function Run-SQLQueryO ($SqlServer, $SqlDatabase, $SqlQuery)
{
    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
    $SqlConnection.ConnectionString = "Server =" + $SqlServer + "; Database =" + $SqlDatabase + "; Integrated Security = True"
    $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
    $SqlCmd.CommandText = $SqlQuery
    $SqlCmd.Connection = $SqlConnection
    $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
    $SqlAdapter.SelectCommand = $SqlCmd
    $DataSet = New-Object System.Data.DataSet
    $SqlAdapter.Fill($DataSet)
    $SqlConnection.Close()
    $DataSet.Tables[0]
}

function Run-SQLQuery ($SqlDatabase, $File)
{
    $SqlServer = "VNETSHPSQL"
    $SqlQuery = "SELECT * from AllDocs where SetupPath = '$($File)'"

    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
    $SqlConnection.ConnectionString = "Server =" + $SqlServer + "; Database =" + $SqlDatabase + "; Integrated Security = True"
    $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
    $SqlCmd.CommandText = $SqlQuery
    $SqlCmd.Connection = $SqlConnection
    $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
    $SqlAdapter.SelectCommand = $SqlCmd
    $DataSet = New-Object System.Data.DataSet
    $SqlAdapter.Fill($DataSet)
    $SqlConnection.Close()
    $DataSet.Tables[0]
}


$q = Run-SQLQuery -SqlDatabase "SPS_Content_VNet" -File "Features\RioLinx.SharePoint.Responsive.Foundation.MasterPages\ResponsiveMasterPages\bootstrap-2.master" |
    select Id, SiteId, DirName, LeafName, WebId, ListId

foreach ($item in $q)
{
    write-host "Item: " $item.Id
    if ( !$item.Id ) {continue;}
    
    $site = Get-SPSite -Limit all | where { $_.Id -eq $item.SiteId }
    $site
    $web = $site | Get-SPWeb -Limit all | where { $_.Id -eq $item.WebId }
    $web.Url
    $file = $web.GetFile([Guid]$item.Id)
    $file.UniqueId
    $file.ServerRelativeUrl
}