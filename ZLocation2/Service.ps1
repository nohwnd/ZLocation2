Set-StrictMode -Version Latest

class Service {

    Service () {}

    [Collections.Generic.IEnumerable[Location]] Get() {
        return (Invoke-DBOperation {
            # Return an enumerator of all location entries
            try {
                [Location[]]$arr = DBFind $collection ([LiteDB.Query]::All()) ([Location])
                , $arr
            }
            catch [System.InvalidCastException] {
                Write-Warning "Caught InvalidCastException when reading db, probably [LiteDB.ObjectId] entry present."
                $oidquery = [LiteDB.Query]::Where('_id', {$args -like '{"$oid":"*"}'})
                $problementries = (,$collection.Find($oidquery))
                if ($problementries.Count -gt 0) {
                    Write-Warning "Found $($problementries.Count) problem entries, attempting to remove..."
                    $problementries | Write-Debug
                    try {
                        DBDelete $collection $oidquery | Out-Null
                        Write-Warning 'Problem entries successfully removed, please repeat your command.'
                    } catch {
                        Write-Error 'Problem entries could not be removed.'
                    }
                } else {
                        Write-Error 'No problem entries found, please open an issue on https://github.com/vors/ZLocation'
                }
            }
        })
    }
    [void] Add([string]$path, [double]$weight) {
        Invoke-DBOperation {
            $l = DBGetById $collection $path ([Location])
            if($l) {
                $l.weight += $weight
                DBUpdate $collection $l
            } else {
                $l = [Location]::new()
                $l.path = $path
                $l.weight = $weight
                try {
                    DBInsert $collection $l
                } catch [LiteDB.LiteException] { 
                    throw $_;
                }
            }
        }
    }
    [void] Remove([string]$path) {
        Invoke-DBOperation {
            # Use DB's internal column name, not mapped name
            DBDelete $collection ([LiteDB.Query]::EQ('_id', [LiteDB.BSONValue]::new($path)))
        }
    }
}

class Location {
    Location() {}

    [LiteDB.BsonId()]
    [string] $path;

    [double] $weight;
}

function Get-ZLocationDatabaseFilePath
{
    if ($env:ZLOCATION_TEST -eq 1) {
        return "$PSScriptRoot\..\testdb.db"
    }
    
    if ($env:ZLOCATION_DATABASE_PATH) {
        return $env:ZLOCATION_DATABASE_PATH
    }
    
    return (Join-Path $HOME 'z-location2.db')
}

<#
 Open database, invoke a database operation, and close the database afterwards.
 This is necessary for safe multi-process concurrency.
 See: https://github.com/mbdavid/LiteDB/wiki/Concurrency
 Exposes $db and $collection variables for use by the $scriptblock
#>
function Invoke-DBOperation {
    param (
        [Parameter(Mandatory=$true)] $private:scriptblock
    )
    $Private:Mode = if (Get-Variable IsMacOS -ErrorAction Ignore) { 'Exclusive' } else { 'Shared' }
    # $db and $collection will be in-scope within $scriptblock
    $db = DBOpen "Filename=$( Get-ZLocationDatabaseFilePath ); Mode=$Mode"
    $collection = Get-DBCollection $db 'location'
    try {
        # retry logic: on Mac we may not be able to execute the read concurrently
        for ($__i=0; $__i -lt 5; $__i++) {
            try {
                & $private:scriptblock
                return
            } catch [System.IO.IOException] {
                # The process cannot access the file '~\z-location.db' because it is being used by another process.
                if ($__i -lt 4 ) {
                    $rand = Get-Random 100
                    Start-Sleep -Milliseconds (($__i + 1) * 100 - $rand)
                } else {
                    throw [System.IO.IOException] 'Cannot execute database operation after 5 attempts, please open an issue on https://github.com/vors/ZLocation'
                }
            }
        }
    } finally {
        $db.dispose()
    }
}

# Create empty db, collection, and index if it doesn't exist
Invoke-DBOperation {
    $collection.EnsureIndex('path')
}

$service = [Service]::new()

function Get-ZService {
    ,$service
}
