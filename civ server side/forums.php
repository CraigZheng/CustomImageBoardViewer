<?php
	//this script will return a json file which contains some configurations for the CIV app
	//this script accepts get variables
	$bundleIdentifier = @"com.craig.ac-channel-browser";
	$file = "forums.xml";
	$censoredFile = "forums-censored.xml";
	
	//V2 for the BT isle
	$fileV2 = "forums_v2.json";
	$censoredFileV2 = "forums_v2-censored.json";

	$version = "1.0";
	if (isset($_GET["version"])) {
		$version = $_GET["version"];
	}
	//AC island
	if (strpos($version, $bundleIdentifier) !== false) {
		if (strpos($version, "DEBUG") !== false) {
			echo file_get_contents($file);
		}
		else if (strpos($version, "2.3") !== false) {
			echo file_get_contents($censoredFile);
		} else {
			echo file_get_contents($file);
		}
		return;
	}
	
	//BT island
	if (strcasecmp($version, "2.2.1") == 0)
		echo file_get_contents($fileV2);
	else 
		echo file_get_contents($fileV2);
?>