<?php
	//each represents a notification object
	class Notification{
		public $sender;
		public $topic;
		public $title;
		public $description;
		public $content;
		public $date;
		public $emotion;
		public $thImgSrc;
		public $imgSrc;
		public $link;
		public $priority;
		public $notificationID;
		public $replyToID;
		public $shoudDisplayXTimes;
		/*
		//constructor
		public function __construct($no, $se, $to, $ti, $de, $co, $da, $em, $th, $im, $li, $pr, $re){
    		$this->notificationID = $no;
    		$this->sender = $se;
    		$this->topic = $to;
    		$this->title = $ti;
    		$this->description = $de;
    		$this->content = $co;
    		$this->date = $da;
    		$this->emotion = $em;
    		$this->thImgSrc = $th;
    		$this->imgSrc = $im;
    		$this->link = $li;
    		$this->priority = $pr;
    		$this->replyToId = $re;
  		}
		*/
		//return as xml object
		function convert_to_XML() {
			try {
				$xml = new SimpleXMLElement("<message></message>");
				$xml->addChild("sender", $this->sender);
				$xml->addChild("topic", $this->topic);
				$xml->addChild("title", $this->title);
				$xml->addChild("description", $this->description);
				$xml->addChild("content", $this->content);
				$xml->addChild("date", $this->date);
				$xml->addChild("emotion", $this->emotion);
				$xml->addChild("thImgSrc", $this->thImgSrc);
				$xml->addChild("imgSrc", $this->imgSrc);
				$xml->addChild("link", $this->link);
				$xml->addChild("priority", $this->priority);
				$xml->addChild("notificationID", $this->notificationID);
				$xml->addChild("replyToID", $this->replyToID);
				$xml->addChild("shouldDisplayXTimes", $this->shouldDisplayXTimes);
				return $xml;
			}
			catch (Exception $e){
				echo "Exception: ". $e;
			}
			return null;
		}
	}
?>