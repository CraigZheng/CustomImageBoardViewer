<?php
	//this script will return a json file which contains some configurations for the CIV app
	//this script accepts get variables
	$file = "forums.xml";
	$censoredFile = "forums-censored.xml";
	//V2 for the new isle
	$fileV2 = "forums_v2.json";
	$censoredFileV2 = "forums_v2-censored.json";
	
	$version = "1.0";
	if (isset($_GET["version"])) {
		$version = $_GET["version"];
	}
	if (strcasecmp($version, "2.2" == 0)) {
		echo file_get_contents($censoredFileV2);
	}
	else if (strcasecmp($version, "2.1") == 0)
		echo file_get_contents($censoredFile);
	else
		echo file_get_contents($file);
?>