<?php
	//this script will return a json file which contains some configurations for the CIV app
	//this script accepts get variables
	$bundleIdentifier = @"com.craig.ac-channel-browser";
	$file = "forums.xml";
	$censoredFile = "forums-censored.xml";
	
	//V2 for the BT isle
	$fileV2 = "forums_v2.json";
	$censoredFileV2 = "forums_v2-censored.json";
	
	//V3 for BT isle in the A isle's hide
	$fileV3 = "forums_v3.json";
	$fileV4 = "forums_v4.json";
	$censoredFileV2 = "forums_v2-censored.json";


	$version = "1.0";
	if (isset($_GET["version"])) {
		$version = $_GET["version"];
	}
	//AC island
	if (strpos($version, $bundleIdentifier) !== false) {
		if (floatval(str_replace($bundleIdentifier . "-", "", $version)) > 4.2) {
			echo file_get_contents($fileV4);
		} else {
			echo file_get_contents($fileV3);
		}
		return;
	}
	
	//BT island
	if (strcasecmp($version, "2.2.1") == 0)
		echo file_get_contents($fileV2);
	else 
		echo file_get_contents($fileV2);
?>