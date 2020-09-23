function Retry-Command {
    [CmdletBinding()]
    Param(
        [Parameter(Position=0, Mandatory=$true)]
        [scriptblock]$ScriptBlock,

        [Parameter(Position=1, Mandatory=$false)]
        [int]$Maximum = 5,

        [Parameter(Position=2, Mandatory=$false)]
        [int]$Delay = 100
    )

    Begin {
        $cnt = 0
    }

    Process {
        do {
            $cnt++
            try {
                $ScriptBlock.Invoke()
                return
            } catch {
                Write-Error $_.Exception.InnerException.Message -ErrorAction Continue
                Start-Sleep -Milliseconds $Delay
            }
        } while ($cnt -lt $Maximum)

        # Throw an error after $Maximum unsuccessful invocations. Doesn't need
        # a condition, since the function returns upon successful invocation.
        throw 'Execution failed.'
    }
}

function test($label, $url, $match) {
    Write-Host $label
    $r = iwr $url -UseDefaultCredentials
    if (-Not ($r.RawContent -match $match)) {
        throw "Failed! Raw: ", $r.RawContent
    }
    Write-Host "OK!"
}

try {
	Retry-Command -ScriptBlock {
		test "Test debugKerberos - Home..." http://clientlinux.mshome.net:8001/debugKerberos/ "checkhostname.jsp"
	} -Maximum 10 -Delay 60000

	Retry-Command -ScriptBlock {
		test "Test debugKerberos - Secure..." http://clientlinux.mshome.net:8001/debugKerberos/secure/ "Remote user: vagrant"
	} -Maximum 10 -Delay 60000

} catch {
    $r = $_.Exception
    Write-Host $r
    exit 1
}

exit 0