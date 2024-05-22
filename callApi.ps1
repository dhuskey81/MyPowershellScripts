param (
    $env,
    $UrlFileName,
    $Path,
    $EnvFilePath,
    $Prod_PreProd
)
# Initialization
$Path = Split-Path -Parent $MyInvocation.MyCommand.Path
$env = $env
$UrlFileName = $UrlFileName
$EnvFilePath = $EnvFilePath
$Prod_PreProd = $Prod_PreProd

function Set-EnvFilePath {    
    if ($null -eq $EnvFilePath ) {
        $EnvFilePath = Join-Path -Path $Path "Enviorments.txt"
        return $EnvFilePath
    }
    else {
        $EnvFilePath = Join-Path -Path $PathToFile $FileName
    }
}
# Swaps out dummy varaible for the variable on hand. 
function Import-EnvToUrl {
    param (
        $urlList
    )   
    $env_project
    $env_api

    # There are two forms of URL lists projects and API
    # I need to lists, because each handles env values differently
    $ToTestUrlList = New-Object System.Collections.Generic.List[string]
    
    $content = Get-Content $urlList
    [string[]]$env_split_val_num = $env.Split('_')
    $num = $env_split_val_num.Count
    ## Test if user enter legacy or new schema
    if($env_split_val_num.Count -eq 2){
        #$env_project = $env_split_val_num[1]
        #$env_api = $env_split_val_num[0].ToString() + "-" + $env_split_val_num[1].ToString() 
        $env_api = $env_split_val_num[1].ToString()
    }
    else{
        $env_api = $env_split_val_num[0].ToString() #+ "-" + $env_split_val_num[1].ToString() 
    }

    ## Runs through and replaces the <env> With the env given by user. 
    foreach ($EnvSingle in $content) {
        $ToTestUrlList.Add(($EnvSingle.Replace("environment",$env_api)))
        #if($EnvSingle.Contains(".test.studentaid.gov")){
        #    $ToTestUrlList.Add($EnvSingle.Replace("<env>", $env_project))
        #} 
        #elseif ($EnvSingle.Contains(".<env>.something.com")) {
        #    $ToTestUrlList.Add($EnvSingle.Replace("<env>", $env_api))
        #}
        #else{
        #    $ToTestUrlList.Add($EnvSingle.Replace("<env>",$env_api))
        #}
    }
    return $ToTestUrlList
}
##$qpath = Join-Path -Path $Path "ProdUrlEndPoints.txt"
# Select Url File input
function Process-UrlEndpoint {
    #Set-Path
    Set-EnvFilePath 
    $url_list = New-Object System.Collections.Generic.List[string]
    if ($null -eq $UrlFileName){
        if($Prod_PreProd -eq "prod"){
            $UrlFileName = Join-Path -Path $Path "ProdUrlEndPoints.txt"
            $url_list = Get-Content $UrlFileName
            $urlComplete = Import-EnvToUrl -urlList $url_list
            Invoke-List -UrlList $urlComplete
        }
        elseif ($env -eq $diffList) {
            Write-Host "Not Yet implemented"
            #$urlComplete = Import-EnvToUrl -urlList $url_list
        }
        else {
            $UrlFileName = Join-Path -Path $Path "TestUrlEndpoints.txt"
            $urlComplete = Import-EnvToUrl -urlList $UrlFileName
            Invoke-List -UrlList $urlComplete
        }
        
    }
}
# This is the function that makes the calls to the env
function Invoke-List {
    param (
        $UrlList
    )
    $count = 0
    foreach ($item in $UrlList) {  
        try {
            $Response = Invoke-WebRequest -Uri $item -SkipCertificateCheck
            $StatusCode = $Response.StatusCode      
        }
        catch {
            $StatusCode = $_.Exception.Response.StatusCode.value__
        }
        finally {
            if($null -ne $item){
            Write-host "$count    $statusCode   $item"  | Format-Table number,status, url
            $count++
            }
        }
    }
}
Write-Host $env
Process-UrlEndpoint
