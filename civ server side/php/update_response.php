<?php
//xml response
	function update_successed($threadID, $reason, $content, $image){
		$xml = new SimpleXMLElement("<Response></Response>");
		$xml->addChild('Success', 'TRUE');
		$xml->addChild('ThreadID', $threadID);
		$xml->addChild('Reason', $reason);
		$xml->addChild('Content', $content);
		$xml->addChild('Image', $image);
		return $xml;
	}
	
	function update_failed($threadID, $message){	
		$xml = new SimpleXMLElement("<Response></Response>");
		$xml->addChild('Success', 'FALSE');
		$xml->addChild('ThreadID', $threadID);
		$xml->addChild('Message', $message);
		return $xml;
	}
	
	//response the given xml content as an xml file for client to download
	function response_with_xml($givenXML){		
		header('Content-Disposition: attachment; filename="response.xml"');
		header('Content-type: text/xml');
		echo $givenXML->asXML();
		exit();
	}
?>