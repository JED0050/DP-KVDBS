$dbs_name = Read-Host "Choose DBS [redis | aerospike | memcached | riak]"
$dbs_name = $dbs_name.ToString().ToLower()
if (-not (($dbs_name -eq "redis") -or ($dbs_name -eq "aerospike") -or ($dbs_name -eq "memcached") -or ($dbs_name -eq "riak"))) {
    "`tChosen DBS $dbs_name was not found, only [redis | aerospike | memcached | riak] are acceptable"
    exit 1
}
$workload = Read-Host "Choose Workload [a | b | c]"
$workload = $workload.ToString().ToLower()
if (-not (($workload -eq "a") -or ($workload -eq "b") -or ($workload -eq "c"))) {
    "`tChosen workload-$workload was not found, only a-f is acceptable"
    "`tDefault Workload-a was chosen"
    $workload = "a"
}
$insertonly = Read-Host "Do you want to test only inserting [0 = no | 1 = yes]"
$insertonly = $insertonly.ToString().ToLower()
if ($insertonly -eq "yes" -or $insertonly -eq "y") {
    $insertonly = "1"
} elseif ($insertonly -eq "no" -or $insertonly -eq "n") {
    $insertonly = "0"
} elseif (-not ($insertonly -eq "0" -or $insertonly -eq "1")) {
    "`tInsert only option must be set to 0 (no) or 1 (yes)"
    "`tDefault option 0 (no) was chosen"
    $insertonly = "0"
}
$recordcount = Read-Host "Choose number of records [1000-1000000]"
$recordcount = [int]$recordcount
if ((-not ($recordcount -is [int])) -or $recordcount -lt 10 -or $recordcount -gt 10000000) {
    "`tNumber of records is not int, too small or too large"
    "`tNumber of records was set to default value 10000"
    $recordcount = 10000
}
$operationcount = ""
if ($insertonly -eq "0"){
    $operationcount = Read-Host "Choose number of tests [1000-1000000]"
    $operationcount = [int]$operationcount
    if ((-not ($operationcount -is [int])) -or $operationcount -lt 100 -or $operationcount -gt 10000000) {
        "`tNumber of operations is not int, too small or too large"
        "`tNumber of operations was set to default value 10000"
        $operationcount = 10000
    }
}
$workload_info = ""
if ($workload -eq "a") {
    $workload_info = "(Update-heavy: 50% read, 50% update, distribution zipfian)"
} elseif ($workload -eq "b") {
    $workload_info = "(Read-mostly: 95% read, 5% update, distribution zipfian)"
} elseif ($workload -eq "c") {
    $workload_info = "(Read-only: 100% read, distribution zipfian)"
}
"`nDBS: $dbs_name`t`t`t`tWorkload: $workload $workload_info"
if ($insertonly -eq "1") {
    "Insertonly: yes`t`t`tRecord count: $recordcount"
} else {
    "Record count: $recordcount`t`tOperation count: $operationcount"
}
"`n`n"

if ($dbs_name -eq "redis") {
    $image_name = "redis:latest"
    $image_config = "--name my-redis -p 6379:6379"
    $ycsb_properties = "-p redis.host=127.0.0.1 -p redis.port=6379"
}elseif ($dbs_name -eq "aerospike"){
    $image_name = "aerospike:ee-7.0.0.3_1"
    $image_config = "--name my_aerospike -p 3000:3000"
    $ycsb_properties = "-p as.namespace=test"
}elseif ($dbs_name -eq "memcached"){
    $image_name = "memcached:latest"
    $image_config = "--name my-memcached -p 11211:11211"
    $ycsb_properties = "-p memcached.hosts=127.0.0.1 -p memcached.shutdownTimeoutMillis=99999999"
}elseif ($dbs_name -eq "riak"){
    $image_name = "basho/riak-kv:latest"
    $image_config = "--name my-riak -p 8087:8087 -p 8098:8098"
    $ycsb_properties = ""
}else{
    "`tChosen DBS $dbs_name was not found, only [redis | aerospike | memcached | riak] are acceptable"
    exit 1
}

$docker_token
"Pulling and starting latest docker image of " + $dbs_name
docker pull $image_name
$docker_token = Invoke-Expression -Command "docker run $image_config -d $image_name"
"Docker Container token: " + $docker_token

"`n`nWaiting for DBS to be fully prepared"
if ($dbs_name -eq "riak"){
    "`tWait 1 minute"
    Start-Sleep -Seconds 60
    docker exec my-riak riak-admin bucket-type create ycsb
    Start-Sleep -Seconds 10
    docker exec my-riak riak-admin bucket-type activate ycsb
    Start-Sleep -Seconds 10
} else {
    "`tWait 10 seconds"
    Start-Sleep -Seconds 10
}

"`n`nRunning YCSB tests of " + $dbs_name
"Inserting data"
cd C:\Users\jedlicka\Desktop\YCSB\ycsb-0.17.0\bin  # path to ycsb bin folder
$load = Invoke-Expression -Command ".\ycsb load $dbs_name -P ..\workloads\workload$workload $ycsb_properties -p recordcount=$recordcount -p threadcount=4"
$load
$load | Out-File -FilePath "output.txt"
if ($insertonly -eq "0"){
    "`n`nRunning tests"
    $run = Invoke-Expression -Command ".\ycsb run $dbs_name -P ..\workloads\workload$workload $ycsb_properties -p operationcount=$operationcount -p threadcount=4"
    $run
}

cd C:\Users\jedlicka\Desktop\SCRIPTS\Results  # path for test results files
"`n`nSaving test output files to results folder"
$currentDateTime = Get-Date -Format "yyyy_MM_dd_HH_mm_ss"
$load_file_name = ("load_" + $dbs_name + "_" + $currentDateTime + ".txt")
$load | Out-File -FilePath $load_file_name
if ($insertonly -eq "0"){
    $run_file_name = ("run_" + $dbs_name + "_" + $currentDateTime + ".txt")
    $run | Out-File -FilePath $run_file_name
}

"`n`nPausing and removing docker image of " + $dbs_name
docker stop $docker_token
docker rm $docker_token

"`n"
pause
