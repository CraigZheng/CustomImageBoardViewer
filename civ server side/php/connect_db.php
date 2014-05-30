<?php
	//the purpose of this file is to estabilish a mysql database connection.
	
	$mysqli = new mysqli("fdb3.awardspace.net", "1583255_civ", "httph.acfun.tvt9999", "1583255_civ");
	if ($mysqli->connect_error){
		echo('Connect Error (' .$mysqli->connect_errno. ')'.$mysqli->connect_error);
	}
	

?>