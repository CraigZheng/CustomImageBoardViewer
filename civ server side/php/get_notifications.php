<?php
	//this script will read a list of raw info from notification table in database
	//then construct notification objects based on the raw info
	function get_notifications()
	{
		include_once("connect_db.php");
		include_once("notification.php");

		$sql = "SELECT * 
				FROM  `notification` 
				LIMIT 0 , 1";
		$entities = mysqli_query($mysqli, $sql);
		$xml = new SimpleXMLElement('<?xml version="1.0" encoding="UTF-8"?><result></result>');
		if (mysqli_num_rows($entities) > 0){
			$xml->addChild('Success', 'TRUE');
			while ($entity = mysqli_fetch_array($entities, MYSQLI_BOTH))
				{
					/*
					$notification = new Notification($entity['notificationID'], 
													$entity['sender'], 
													$entity['topic'], 
													$entity['title'], 
													$entity['description'], 
													$entity['content'], 
													$entity['date'], 
													$entity['emotion'], 
													$entity['thImgSrc'], 
													$entity['imgSrc'], 
													$entity['link'], 
													$entity['priority'], 
													$entity['replyToID']);
					*/
					$noti = new Notification();
					$noti->notificationID = $entity['notificationID'];
					$noti->sender = $entity['sender'];
					$noti->topic = $entity['topic'];
					$noti->title = $entity['title'];
					$noti->description = $entity['description'];
					$noti->content = $entity['content'];
					$noti->date = $entity['date'];
					$noti->emotion =$entity['emotion'];
					$noti->thImgSrc = $entity['thImgSrc'];
					$noti->imgSrc = $entity['imgSrc'];
					$noti->link = $entity['link'];
					$noti->priority = $entity['priority'];
					$noti->replyToID = $entity['replyToID'];
					$noti->shouldDisplayXTimes = $entity['shouldDisplayXTimes'];
					sxml_append($xml, $noti->convert_to_XML());
				}
			} 
			else {
				$xml->addChild('Success', 'FALSE');
		}
		return $xml;
	}	
	
	//append a node into an existing xml tree
	function sxml_append(SimpleXMLElement $to, SimpleXMLElement $from) {
    	$toDom = dom_import_simplexml($to);
    	$fromDom = dom_import_simplexml($from);
    	$toDom->appendChild($toDom->ownerDocument->importNode($fromDom, true));
	}
?>