<?php
	//download a list of threads from a certain forum
	function downloadThreadList($forum){
		//$host = "http://h.acfun.tv/api/Forums";
		//$host = "http://h.acfun.tv/api/thread/root?forumName=".$forum;
		$host = "http://www.google.com";
		$list = file_get_contents($host);
		//$list = file_get_contents_curl($host);
		$list = get_data($host);
		echo $list;
	}
?>