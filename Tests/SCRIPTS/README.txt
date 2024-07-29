Práce se všemi DBS je prováděna prostřednictvím prostředí Docker. DBS se zde instalují, nastavují a spouští.
Následně se na základě nastavených portů připojí testovací prostředí YCSB k DBS, naplní ho daty a provede požadované testy.

Pro možnost běhu připravených testů je možné využít spustitelný skript PowerShellu (1) nebo ručně vkládat skripty do příkazové řádky (2).


1.)
Pro snažší práci se preferuje první možnost. Spustitelný PowerShell skript se nazývá "Automatic_YCSB_test_script.ps1".
Pro jeho běh na něj stačí pouze kliknout pravým tlačítkem a vybrat možnost "Run with PowerShell".
Případně vybrat možnost "Edit" pro spuštění prostředí Windows PowerShell ISE, ve kterém lze skript editovat, debugovat a opětovně spouštět.

Po spuštění skriptu je po uživateli požadováno, aby do konzole zadal několik základních informací.
- Nejprve název DBS (redis, aerospike, memcached, riak), kterou chce testovat.
- Následně testový scénář (Workload a, b, c).
- Poté určí potřebu provádět pouze testování vkládání dat do DBS (insertonly, 0 = ne, 1 = ano).
- Nakonec zadá počet vložených záznamů do DBS (recordcount = 100-1000000) a počet prováděných operací (operationscount = 100-1000000) definovaných vybraným scénářem.

Skript pro vybraný DBS stáhne Docker image, spustí a nastaví Docker container. Následně spustí příkazy "ycsb load" pro vložení dat do DBS a "ycsb run" pro spuštění testů.
Výsledek testů se zobrazí v konzoli ve formě tabulek. Veškeré výsledky se také ukládají do souborů umístěných ve složce "Results".
Jsou vytvořeny dva soubory: jeden pro fázi vkládání dat do DBS a druhý pro samotné testování. Soubory nesou název "'dbs_name'_load/run_'datetime'.txt".
Po dokončení testů se spuštěný Docker container zastaví a vymaže.
Docker container je přístupný na základě jeho unikátního token_id, které je vypsáno na začátku testů ve výstupu "Docker Container token: 'docker_token'".

Při spouštění skriptu v jiném adresáři než je jeho výchozí umístění je zapotřebí změnit cestu k projektu YCSB (řádek 114) a služce s výsledky (řádek 124).


2.)
Pro potřeby ručního vkládání skriptů do příkazové řádky, ať už cmd nebo PowerShell, jsou veškeré potřebné skripty popsány a k nalezení v textovém souboru "YCSB_Docker_Scripty.txt".

YCSB skripty je zapotřebí spouštět uvnitř složky "bin" umístěné v projektu YCSB.
Následně je nutné každý Docker container odstranit na konci testování pro možnost vytvoření nového containeru se stejnými porty daného DBS.
Docker container se odstraní pomocí příkazů "docker stop 'token_id'", "docker rm 'token_id'".
ID tokenu je k dispozici hned po vytvoření Docker containeru v příkazové řádce (po použití příkazu "docker run ...").



Docker:	https://www.docker.com/
YCSB:	https://github.com/brianfrankcooper/YCSB/releases/tag/0.17.0