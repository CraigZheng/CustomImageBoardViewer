<?php
	//the purpose of this file is to estabilish a mysql database connection.
	
	$mysqli = new mysqli("mysql9.000webhost.com", "a6962118_zombie", "httph.acfun.tvt", "a6962118_civ");
	if ($mysqli->connect_error){
		echo('Connect Error (' .$mysqli->connect_errno. ')'.$mysqli->connect_error);
	}
	

?>