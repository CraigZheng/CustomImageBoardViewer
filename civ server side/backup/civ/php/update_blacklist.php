<?php
//allows user to add a new entry to the blacklist database, which will help the app to identify harmful contents
//every user is allow to make new entry, and moderators can perform tasks such as approve or deny user submitted entries

	//connect to DB
	include 'connect_db.php';
	include 'update_response.php';
	//get contents outta POST request
	//every POST request should contains the following: threadID(mondatory), reason, content, image(optional)
	$threadID;
	$reason = "0";
	$content = 0;
	$image = 1;
	$date = date('Y-m-d H:i:s');
	$harmful = 0;
	if (isset($_POST['threadID'])){
		$threadID = $_POST['threadID'];
	} else {
		$xml = update_failed("0000", "No thread given");
	}
	if (isset($_POST['reason'])){
		$reason = $_POST['reason'];
	}
	if (isset($_POST['content'])){
		$content = $_POST['content'];
	}
	if (isset($_POST['image'])){
		$image = $_POST['image'];
	}
	$threadID = mysqli_real_escape_string($mysqli, $threadID);
	$reason = mysqli_real_escape_string($mysqli, $reason);
	$date = mysqli_real_escape_string($mysqli, $date);
	$sql = "INSERT INTO blacklist (threadID, date, reason, content, image, harmful) VALUES ($threadID, '$date', '$reason', $content, $image, $harmful)";
	$result = mysqli_query($mysqli, $sql);
	$xml;
	if ($result){
		//successed
		$xml = update_successed($threadID, $reason, $content, $image);
	}
	else {
		//failed
		$xml = update_failed($threadID, mysqli_error($mysqli));
	}
	response_with_xml($xml);
?>