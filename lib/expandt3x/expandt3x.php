<?php
require("class.em_terconnection.php");

// default-Settings.
$unpackDir = "extension";


// Usage ausgeben
function printUsageAndDie(){
	global $argv;
	print <<<EOM
------------------------------------------------------------------------------
  _____                            _   _   _____
 | ____|_  ___ __   __ _ _ __   __| | | |_|___ /_  __
 |  _| \ \/ / '_ \ / _` | '_ \ / _` | | __| |_ \ \/ /
 | |___ >  <| |_) | (_| | | | | (_| | | |_ ___) >  <
 |_____/_/\_\ .__/ \__,_|_| |_|\__,_|  \__|____/_/\_\  Version 0.1, 04.06.2007
		   |_|

 ...written by droptix and luwo. (look at http://www.typo3.net/forum)

 Usage: expand_t3x.php [filename.t3x]  <directory> 

 * filename.t3x = Name of your t3x-file
 * directory    = optional directory of extraction (default="extension")
------------------------------------------------------------------------------

EOM;
	die();
}


// Wurde eine Datei angegeben?
if (count($argv) <=1) { printUsageAndDie(); }

// Wurde ein Auspackverzeichnis angegeben?
if ($argv[2] != '') $unpackDir=$argv[2];

// Datei aus Kommandozeile holen...
$extFile=$argv[1];
if (file_exists($extFile)) { print "\n Extract Data: '$extFile'...\n\n";}
else{ print "\n Datei: '$extFile' wurde leider nicht gefunden \n"; printUsageAndDie();}



// Start unpacking.
$fileContent = file_get_contents($extFile);
$ext = SC_mod_tools_em_terconnection::decodeExchangeData($fileContent);


function autocreate_subdirs($dir) {
	$path = array();
	$subdirs = explode("/", $dir);
	foreach ($subdirs as $subdir) {
		$path[] = $subdir;
		$fullPath = implode("/", $path);
		if ($fullPath && !file_exists($fullPath)) {
			if (mkdir($fullPath)) {
				echo sprintf("OK: created directory '%s'\n", $fullPath);
			} else {
				echo sprintf("ERROR: directory '%s' not created\n", $fullPath);
			}
		}
	}
}

// Unpack extension(s).
foreach ($ext as $e) {
	if ($e["EM_CONF"]) {

		#log2(print_r($e,true));

		$_extemconfcontent = '<?php

/***************************************************************
 * Extension Manager/Repository config file for ext "' . $e['extKey'] . '".
 *
 * Auto generated deployTYPO3' . date('d-m-Y H:i') . '
 *
 * https://github.com/Lingewoud/deployTYPO3
 *
 * Manual updates:
 * Only the data in the array - everything else is removed by next
 * writing. "version" and "dependencies" must not be touched!
 ***************************************************************/

';
		foreach($e['EM_CONF'] as $key=>$emconf){
			$_extemconfcontent .= sprintf("\$EM_CONF[\$_EXTKEY]['$key'] = '$emconf';\n");
		}

		$_extemconfcontent .= '?>';
		$e["FILES"]['ext_emconf.php']['name'] =  'ext_emconf.php';
		$e["FILES"]['ext_emconf.php']['content'] = $_extemconfcontent; 


		// Create unpack directory.
		if (!file_exists($unpackDir)) {
			mkdir($unpackDir);
		}
		// Create directories.
		$dirs = explode(",", $e["EM_CONF"]["createDirs"]);
		foreach ($dirs as $dir) {
			// Start in unpack directory if any.
			if ($unpackDir) {
				$dir = $unpackDir."/".$dir;
			}
			autocreate_subdirs($dir);
		}
		// Write files.
		foreach ($e["FILES"] as $file) {
			// Start in unpack directory.
			if (empty($unpackDir)) {
				$path = array();
			} else {
				$path = array($unpackDir);
			}
			$tmp = explode("/", $file["name"]);
			// Separate file name and rest path.
			$fileName = array_pop($tmp);
			$path = array_merge($path, $tmp);
			unset($tmp);
			// Create subdirs if neccessary.
			$dirPath = implode("/", $path);
			autocreate_subdirs($dirPath);
			// Write file.
			$path[] = $fileName;
			$fullPath = implode("/", $path);
			$handle = fopen($fullPath, "w");
			if ($handle && fwrite($handle, $file["content"])) {
				fclose($handle);
				#echo sprintf("OK: wrote file '%s'\n", $fullPath);
			} else {
				echo sprintf("ERROR: file '%s' not written\n", $fullPath);
			}
		}
	}
	else
	{
		print_r($e);
	}
}

function log2($msg)
{

	//using the date() function
	$time = date("F jS Y, h:iA");

	//$remote_addr is PHP variable to get ip address
	$ip = $REMOTE_ADDR;

	//$http_referer is PHP variable to get referer
	$referer = $HTTP_REFERER;

	//$http_user_agent is PHP variable for browser
	$browser = $HTTP_USER_AGENT;

	//what page they came from
	$page = $_SERVER['REQUEST_URI'];

	//use the fopen() function
	$fp = fopen("/tmp/jinn.log",  "a");

	//using the fputs() function
	fputs($fp, "
		Time: $time
		IP: $ip
		Referer: $referer
		Browser: $browser
		Page: $page
		Msg: $msg
		");

	fclose($fp);

}

?>

