﻿package com.robotacid.gfx {
	import flash.display.MovieClip;
	
	/**
	 * ...
	 * @author Aaron Steed, robotacid.com
	 */
	public class BloodClip extends MovieClip{
		
		[Embed(source = "../../../assets/assets.swf", symbol = "BloodMC")] public static var BloodMC:Class;
		
		public static var g:Game;
		public static var h:int;
		public static var vx:Number;
		
		public var count:int;
		
		public static const DELAY:int = 1;
		
		
		public function BloodClip() {
			var anim:MovieClip = new BloodMC();
			addChild(anim);
			if(!g){
				g = Game.g;
				h = anim.height;
			}
			count = DELAY + Math.random() * DELAY;
		}
		
		public function render():void{
			if(g.frameCount % 4 == 0){
				vx = Math.random() >= 0.5 ? 5 : -5;
				var blit:BlitRect, print:BlitRect;
				if(Math.random() > 0.5){
					blit = g.smallDebrisBrs[Game.BLOOD];
					print = g.smallFadeFbrs[Game.BLOOD];
				} else {
					blit = g.bigDebrisBrs[Game.BLOOD];
					print = g.bigFadeFbrs[Game.BLOOD];
				}
				g.addDebris(parent.x, parent.y - Math.random() * h, blit, vx + (-5 + 10 * Math.random()) , 0, print, true);
				count = DELAY + Math.random() * DELAY;
			}
			x = 0;
			y = 0;
		}
		
	}

}