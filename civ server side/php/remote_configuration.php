<?php
	//this script will return a json file which contains some configurations for the CIV app
	//this script accepts get variables
	$file = "remote_configuration.json";
	$censoredFile = "remote_configuration-censored.json";
	$debugFile = "remote_configuration-debug.json";
	//V2 configuration
	$fileV2 = "remote_configuration_v2.json";
	$censoredFileV2 = "remote_configuration-censored_v2.json";
	
	$version = "1.0";
	if (isset($_GET["version"])) {
		$version = $_GET["version"];
	}
	$json = json_decode(file_get_contents($fileV2), true);
	if ($json) {
		$json["app_version"] = $version;
	}
	
	if (strcasecmp($version, "2.3") == 0)
		echo file_get_contents($censoredFileV2);
	else if (strcasecmp($version, "DEBUG") == 0)
		echo file_get_contents($debugFile);
	else 
		echo json_encode($json);
?>