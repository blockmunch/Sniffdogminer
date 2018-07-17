. .\Include.ps1

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName 
 
 
 $BlockMasters_Request = [PSCustomObject]@{} 
 
 
 try { 
     $BlockMasters_Request = Invoke-RestMethod "http://blockmasters.co/api/status" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop 
     #$BlockMastersCoins_Request = Invoke-RestMethod "http://blockmasters.co/api/status" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop 
 } 
 catch { 
     Write-Warning "Sniffdog howled at ($Name) for a failed API check. " 
     return 
 }
 
 if (($BlockMasters_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) { 
     Write-Warning "SniffDog sniffed near ($Name) but ($Name) Pool API had no scent. " 
     return 
 } 
  
$Location = 'US'
$BlockMasters_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select -ExpandProperty Name | foreach {
#$BlockMasters_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | Where-Object {$BlockMasters_Request.$_.hashrate -gt 0} | foreach {
    $BlockMasters_Host = "$_.blockmasters.co"
    $BlockMasters_Port = $BlockMasters_Request.$_.port
    $BlockMasters_Algorithm = Get-Algorithm $BlockMasters_Request.$_.name
    $BlockMasters_Coin = $BlockMasters_Request.$_.coins
    $BlockMasters_Fees = $BlockMasters_Request.$_.fees
    $BlockMasters_Workers = $BlockMasters_Request.$_.workers

    $Divisor = 1000000
	
    switch($BlockMasters_Algorithm)
    {
        "equihash"{$Divisor /= 1000}
        "blake2s"{$Divisor *= 1000}
	"sha256"{$Divisor *= 1000}
        "sha256t"{$Divisor *= 1000}
        "blakecoin"{$Divisor *= 1000}
        "decred"{$Divisor *= 1000}
        "keccak"{$Divisor *= 1000}
        "keccakc"{$Divisor *= 1000}
        "vanilla"{$Divisor *= 1000}
	"x11"{$Divisor *= 1000}
	"scrypt"{$Divisor *= 1000}
	"qubit"{$Divisor *= 1000}
	"yescrypt"{$Divisor /= 1000}
    "yescryptr16"{$Divisor /= 1000}
    }

			
    if((Get-Stat -Name "$($Name)_$($BlockMasters_Algorithm)_Profit") -eq $null){$Stat = Set-Stat -Name "$($Name)_$($BlockMasters_Algorithm)_Profit" -Value ([Double]$BlockMasters_Request.$_.estimate_last24h/$Divisor*(1-($BlockMasters_request.$_.fees/100)))}
    else{$Stat = Set-Stat -Name "$($Name)_$($BlockMasters_Algorithm)_Profit" -Value ([Double]$BlockMasters_Request.$_.estimate_current/$Divisor *(1-($BlockMasters_request.$_.fees/100)))}
	
    if($Wallet)
    {
        [PSCustomObject]@{
            Algorithm = $BlockMasters_Algorithm
            Info = "$BlockMasters_Coin - Coin(s)"
            Price = $Stat.Live
            Fees = $BlockMasters_Fees
            StablePrice = $Stat.Week
            Workers = $BlockMasters_Workers
            MarginOfError = $Stat.Fluctuation
            Protocol = "stratum+tcp"
            Host = $BlockMasters_Host
            Port = $BlockMasters_Port
            User = $Wallet
            Pass = "ID=$RigName,c=$Passwordcurrency"
            Location = $Location
            SSL = $false
        }
    }
}
