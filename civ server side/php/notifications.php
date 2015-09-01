<?php
//this file would download a list of notifications as xml format
//vendor ID is used to filtout unnecessary notifications
	include_once("get_notifications.php");
	include_once("notification.php");
	
	$vendorID;
	if (isset($_POST['vendorID'])) {
		//DEBUG
		$vendorID = $_POST['vendorID'];
	} else {
	}
	download_as_xml(get_notifications());

?>

<?php
	function download_as_xml($givenXML){		
		header('Content-Disposition: attachment; filename="response.xml"');
		header('Content-type: text/xml; charset=utf-8');
		echo $givenXML->asXML();	
	}

?>