<?php
	//this function detects the creation date of a file, and the difference between that date and now
	
	//if the given file doest not exist, create it from the database
	function detect_empty_file($file){
		if (!file_exists($file)){
			create_blacklist_file($file);
		}
	}
	//if the difference is bigger than the given $period, delete this file and create a new one
	function detect_outdated_file($file, $period) {
		if (file_exists($file)){
			//the difference between now and the time that the file was last modified
			$diff = time() - filemtime($file);
			if ($diff >= $period){
				unlink($file);
				create_blacklist_file($file);
			}
		} else {
			create_blacklist_file($file);
		}				

	}
	
	//this function would create a blacklist xml file out of database
	function create_blacklist_file($file){

		//return data as xml
		include_once 'connect_db.php';
		include_once 'update_response.php';
	
		//return a list of blacklist	
		$sql = "SELECT * 
			FROM  `blacklist` 
			ORDER BY  `blacklist`.`ID` DESC 
			LIMIT 0 , 1";
		$entities = mysqli_query($mysqli, $sql);
		//construct an xml file to containt the info
		$xml = new SimpleXMLElement("<Response></Response>");
		if (mysqli_num_rows($entities) > 0){
			$xml->addChild('Success', 'TRUE');
			$threads = $xml->addChild('Threads');
			while ($entity = mysqli_fetch_array($entities, MYSQLI_BOTH))
			{
				$thread = $threads->addChild('Thread');
				$thread->addChild("ID", $entity['ID']);
				$thread->addChild("ThreadID", $entity['threadID']);
				$thread->addChild('Date', $entity['date']);
				$thread->addChild('Reason', $entity['reason']);
				$thread->addChild('Content', $entity['content']);
				$thread->addChild('Image', $entity['image']);
				$thread->addChild('Harmful', $entity['harmful']);
				$thread->addChild('Block', $entity['block']);
			}
		} else {
			$xml->addChild('Success', 'FALSE');
		}
		// save $xml as a file to the given $file
		$xml->asXML($file);
		
	}
	
	function response_file_as_xml($file){
		if (file_exists($file)){
			header('Content-Disposition: attachment; filename="response.xml"');
			header('Content-type: text/xml');
			readfile($file);
		} else {
			die("Error: File not found.");
		}
	}
	
?>