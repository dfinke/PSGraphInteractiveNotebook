using namespace "Microsoft.DotNet.Interactive"
function Show-InNotebook {
    param(
        $DestinationPath = ".\test.png",
        [Parameter(ValueFromPipeline)]
        $graph
    )

    Begin {
        $data = @()        
    }

    Process {
        $data += $graph
    }
   
    End {

        Remove-Item $destinationPath -ErrorAction SilentlyContinue
        $null = $data | Export-PSGraph -DestinationPath $DestinationPath

        $png = [System.IO.File]::ReadAllBytes($DestinationPath)
        $b64 = [System.Convert]::ToBase64String($png)
        
        $img = '<img src="data:image/png; base64, {0}"></img>' -f $b64

        $null = [Kernel]::display([Kernel]::HTML($img), 'text/html')
    }
}