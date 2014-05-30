<?php
//download the black list entries as an xml file
	include_once 'connect_db.php';
	include_once 'update_response.php';
	
	//return a list of blacklist	
	$sql = "SELECT * 
		FROM  `blacklist` 
		ORDER BY  `blacklist`.`ID` DESC 
		LIMIT 0 , 3";
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
	
	response_with_xml($xml);
?>