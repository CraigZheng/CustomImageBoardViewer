<?php
	//this script will return a json file which contains some configurations for the CIV app
	//this script accepts get variables
	$file = "remote_configuration.json";
	$censoredFile = "remote_configuration-censored.json";
	$debugFile = "remote_configuration-debug.json";
	$version = "1.0";
	if (isset($_GET["version"])) {
		$version = $_GET["version"];
	}
	$json = json_decode(file_get_contents($file), true);
	if ($json) {
		$json["app_version"] = $version;
	}
	
	if (strcasecmp($version, "2.2") == 0)
		echo file_get_contents($censoredFile);
	else if (strcasecmp($version, "DEBUG") == 0)
		echo file_get_contents($debugFile);
	else 
		echo json_encode($json);
?>