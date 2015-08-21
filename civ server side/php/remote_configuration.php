<?php
	//this script will return a json file which contains some configurations for the CIV app
	//this script accepts get variables
	$bundleIdentifier = @"com.craig.ac-channel-browser";
	$file = "remote_configuration.json";
	$censoredFile = "remote_configuration-censored.json";
	$debugFile = "remote_configuration-debug.json";
	//V2 configuration
	$fileV2 = "remote_configuration_v2.json";
	$censoredFileV2 = "remote_configuration-censored_v2.json";
	$debugFile = $fileV2;
	
	$version = "1.0";
	if (isset($_GET["version"])) {
		$version = $_GET["version"];
	}
	$json = json_decode(file_get_contents($file), true);
	if ($json) {
		$json["app_version"] = $version;
	}
	
	//AC island
	if (strpos($version, $bundleIdentifier) !== false) {
		if (strpos($version, "2.4") !== false) {
			echo file_get_contents($file);
		}
		else {
			echo file_get_contents($file);
		}
		return;
	}
	
	echo file_get_contents($fileV2);
?>