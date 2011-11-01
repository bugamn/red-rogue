﻿package com.robotacid.dungeon {
	import com.robotacid.engine.Character;
	import com.robotacid.engine.Chest;
	import com.robotacid.engine.ColliderEntity;
	import com.robotacid.engine.Effect;
	import com.robotacid.engine.Entity;
	import com.robotacid.engine.Item;
	import com.robotacid.engine.MapTileConverter;
	import com.robotacid.engine.Monster;
	import com.robotacid.gfx.Renderer;
	import flash.display.DisplayObject;
	/**
	 * Creates content to place on the map for the first 20 levels to create structured
	 * play, then returns random content from the entire selection afterwards
	 *
	 * You'll notice that I'm shifting between XML and normal objects a lot. The logic behind this
	 * is that if I need to find out what's going on in a level, a quick print out of the XML renders
	 * an easily readable itinerary. And it takes up less room in the shared object.
	 *
	 * @author Aaron Steed, robotacid.com
	 */
	public class Content{
		
		public static var g:Game;
		public static var renderer:Renderer;
		
		public var chestsByLevel:Vector.<Vector.<XML>>;
		public var monstersByLevel:Vector.<Vector.<XML>>;
		
		public static const TOTAL_LEVELS:int = 20;
		
		public function Content() {
			chestsByLevel = new Vector.<Vector.<XML>>(TOTAL_LEVELS);
			monstersByLevel = new Vector.<Vector.<XML>>(TOTAL_LEVELS);
			init();
		}
		
		public function init():void{
			var equipment:Vector.<XML> = new Vector.<XML>();
			var runes:Vector.<XML> = new Vector.<XML>();
			var i:int, j:int;
			for(i = 0; i < TOTAL_LEVELS; i++){
				var quantity:int;
				var dungeonLevel:int = i + 1;
				// min: level / 2, max: (level + 2) / 2
				quantity = Math.ceil((dungeonLevel + g.random.range(3)) * 0.5);
				while(quantity--){
					equipment.push(createItemXML(dungeonLevel, g.random.value() < 0.5 ? Item.WEAPON : Item.ARMOUR));
				}
				// min: level / 2, max: (level + 1) / 2
				quantity = Math.ceil((dungeonLevel + g.random.range(2)) * 0.5);
				while(quantity--){
					runes.push(createItemXML(dungeonLevel, Item.RUNE));
				}
				// min: 5 + level * 2, max: 10 + level 3
				quantity = 5 + g.random.range(6) + dungeonLevel * (2 + g.random.range(2));
				monstersByLevel[i] = new Vector.<XML>();
				while(quantity--){
					monstersByLevel[i].push(createCharacterXML(dungeonLevel, Character.MONSTER));
				}
				
				// equipment needs to be distributed amongst monsters and
				// runes need to go in chests
				var equippedMonsters:int = g.random.range(equipment.length);
				if(monstersByLevel[i].length < equippedMonsters) equippedMonsters = monstersByLevel[i].length;
				while(equippedMonsters--){
					monstersByLevel[i][equippedMonsters].appendChild(equipment.shift());
					
					// bonus equipment - if the order of the items alternates between
					// weapons and armour, we take it as a sign to double equip the
					// monster
					if(equippedMonsters){
						monstersByLevel[i][equippedMonsters].appendChild(equipment.shift());
						equippedMonsters--;
					}
				}
				chestsByLevel[i] = new Vector.<XML>();
				// the rest goes in chests, upto 3 items can go in a chest
				while(equipment.length || runes.length){
					var chestQuantity:int = 1 + g.random.range(3);
					if(chestQuantity > equipment.length + runes.length) chestQuantity = equipment.length + runes.length;
					var chest:XML = <chest />;
					while(chestQuantity){
						if(g.random.value() < 0.5){
							if(runes.length){
								chest.appendChild(runes.shift());
								chestQuantity--;
							}
						} else {
							if(equipment.length){
								chest.appendChild(equipment.shift());
								chestQuantity--;
							}
						}
					}
					chestsByLevel[i].push(chest);
				}
			}
		}
		
		public function populateLevel(dungeonLevel:int, bitmap:DungeonBitmap, layers:Array):void{
			var r:int, c:int;
			var level:int = dungeonLevel - 1;
			var i:int;
			//trace("populating..."+dungeonLevel);
			//for(i = 0; i < monstersByLevel[level].length; i++){
				//trace(monstersByLevel[level][i].toXMLString());
			//}
			//for(i = 0; i < chestsByLevel[level].length; i++){
				//trace(chestsByLevel[level][i].toXMLString());
			//}
			if(level < TOTAL_LEVELS){
				// just going to go for a random drop for now.
				// I intend to figure out a distribution pattern later
				while(monstersByLevel[level].length){
					r = 1 + g.random.range(bitmap.height - 1);
					c = 1 + g.random.range(bitmap.width - 1);
					if(!layers[Map.ENTITIES][r][c] && layers[Map.BLOCKS][r][c] != 1 && (bitmap.bitmapData.getPixel32(c, r + 1) == DungeonBitmap.LEDGE || layers[Map.BLOCKS][r + 1][c] == 1)){
						//trace(monstersByLevel[level][0].toXMLString());
						layers[Map.ENTITIES][r][c] = convertXMLToObject(c, r, monstersByLevel[level].shift());
					}
				}
				while(chestsByLevel[level].length){
					r = 1 + g.random.range(bitmap.height - 2);
					c = 1 + g.random.range(bitmap.width - 2);
					if(layers[Map.ENTITIES][r + 1][c] != MapTileConverter.PIT && !layers[Map.ENTITIES][r][c] && layers[Map.BLOCKS][r][c] != 1 && (bitmap.bitmapData.getPixel32(c, r + 1) == DungeonBitmap.LEDGE || layers[Map.BLOCKS][r + 1][c] == 1)){
						//trace(chestsByLevel[level][0].toXMLString());
						layers[Map.ENTITIES][r][c] = convertXMLToObject(c, r, chestsByLevel[level].shift());
					}
				}
			} else {
				// TO DO!!
				
				
				// content for levels 21+ will have to be generated on the fly
				// the aim is to let the player dig for more random items should they
				// desire to - but they should encounter the level cap on their items
				// and character before long
			}
		}
		
		/* This method tracks down monsters and items and pulls them back into the content manager to be sent out
		 * again if the level is re-visited */
		public function recycleLevel():void{
			var i:int;
			var level:int = g.dungeon.level - 1;
			// no recycling the overworld
			if(level < 0) return;
			// first we check the active list of entities
			for(i = 0; i < g.entities.length; i++){
				recycleEntity(g.entities[i], level);
			}
			// now we scour the entities layer of the renderer for more entities to convert to XML
			var r:int, c:int;
			for(r = 0; r < g.mapRenderer.height; r++){
				for(c = 0; c < g.mapRenderer.width; c++){
					if(g.mapRenderer.mapArrayLayers[Map.ENTITIES][r][c] is Entity){
						recycleEntity(g.mapRenderer.mapArrayLayers[Map.ENTITIES][r][c], level);
					}
				}
			}
			//trace("recycling..." + g.dungeon.level);
			//for(i = 0; i < monstersByLevel[level].length; i++){
				//trace(monstersByLevel[level][i].toXMLString());
			//}
			//for(i = 0; i < chestsByLevel[level].length; i++){
				//trace(chestsByLevel[level][i].toXMLString());
			//}
		}
		
		/* Used in concert with the recycleLevel() method to convert level assets to XML and store them */
		public function recycleEntity(entity:Entity, level:int):void{
			var chest:XML;
			if(entity is Monster){
				monstersByLevel[level].push(entity.toXML());
			} else if(entity is Item){
				if(chestsByLevel[level].length > 0){
					chest = chestsByLevel[level][chestsByLevel[level].length - 1];
					if(chest.item.length < 1 + g.random.range(3)){
						chest.appendChild(entity.toXML());
					} else {
						chest = <chest />;
						chest.appendChild(entity.toXML());
						chestsByLevel[level].push(chest);
					}
				} else {
					chest = <chest />;
					chest.appendChild(entity.toXML());
					chestsByLevel[level].push(chest);
				}
			} else if(entity is Chest){
				chest = entity.toXML();
				if(chest) chestsByLevel[level].push(entity.toXML());
			}
		}
		
		/* Create a random character appropriate for the dungeon level */
		public static function createCharacterXML(dungeonLevel:int, type:int):XML{
			var characterXML:XML = <character />;
			var name:int = g.random.range(Character.stats["names"].length);
			var level:int = -1 + g.random.range(dungeonLevel);
			if(type == Character.MONSTER){
				while(name < 2 || name > dungeonLevel + 1){
					name = g.random.range(Character.stats["names"].length);
					if(name > dungeonLevel + 1) name = dungeonLevel + 1;
				}
			}
			characterXML.@name = name;
			characterXML.@type = type;
			characterXML.@level = level;
			return characterXML;
		}
		
		/* Create a random item appropriate for the dungeon level */
		public static function createItemXML(dungeonLevel:int, type:int):XML{
			var itemXML:XML = <item />;
			var enchantments:int = -2 + g.random.range(dungeonLevel);
			var name:int;
			var level:int = Math.min(1 + g.random.range(dungeonLevel), 20);
			var nameRange:int;
			if(type == Item.ARMOUR){
				nameRange = Item.stats["armour names"].length;
			} else if(type == Item.WEAPON){
				nameRange = Item.stats["weapon names"].length;
			} else if(type == Item.RUNE){
				nameRange = Item.stats["rune names"].length;
				level = 0;
				enchantments = 0;
			}
			if(nameRange > dungeonLevel) nameRange = dungeonLevel;
			name = g.random.range(nameRange);
			
			itemXML.@name = name;
			itemXML.@type = type;
			itemXML.@level = level;
			if(enchantments > 0){
				var runeList:Vector.<int> = new Vector.<int>();
				while(enchantments--){
					nameRange = g.random.range(Item.stats["rune names"].length);
					if(nameRange > dungeonLevel) nameRange = dungeonLevel;
					name = g.random.range(nameRange);
					runeList.push(name);
				}
				// each effect must now be given a level, for this we do a bucket sort
				// to stack the effects
				var bucket:Vector.<int> = new Vector.<int>(Item.stats["rune names"].length);
				var i:int;
				for(i = 0; i < runeList.length; i++){
					bucket[runeList[i]]++;
				}
				for(i = 0; i < bucket.length; i++){
					if(bucket[i]){
						var effectXML:XML = <effect />;
						effectXML.@name = i;
						effectXML.@level = bucket[i];
						itemXML.appendChild(effectXML);
					}
				}
			}
			return itemXML;
		}
		
		public static function convertXMLToObject(x:int, y:int, xml:XML):*{
			var objectType:String = xml.name();
			var i:int, children:XMLList, item:XML, mc:DisplayObject, obj:*;
			var name:int, level:int, type:int;
			var className:Class;
			var items:Vector.<Item>;
			if(objectType == "chest"){
				children = xml.children();
				items = new Vector.<Item>();
				for each(item in children){
					items.push(convertXMLToObject(x, y, item));
				}
				mc = new ChestMC();
				obj = new Chest(mc, x * Game.SCALE + Game.SCALE * 0.5, (y + 1) * Game.SCALE, items);
			} else if(objectType == "item"){
				name = xml.@name;
				level = xml.@level;
				type = xml.@type;
				mc = g.library.getItemGfx(name, type);
				obj = new Item(mc, name, type, level);
				
				// is this item enchanted?
				var effect:Effect;
				for each(var enchantment:XML in xml.effect){
					effect = new Effect(enchantment.@name, enchantment.@level, 0);
					effect.enchant(obj);
				}
				
				// is this item cursed?
				obj.curseState = int(xml.@curseState);
				
			} else if(objectType == "character"){
				name = xml.@name;
				level = xml.@level;
				type = xml.@type;
				if(xml.item.length()){
					items = new Vector.<Item>();
					for each(item in xml.item){
						items.push(convertXMLToObject(x, y, item));
					}
				}
				if(type == Character.MONSTER){
					mc = g.library.getCharacterGfx(name);
					obj = new Monster(mc, (x + 0.5) * Game.SCALE, (y + 1) * Game.SCALE, name, level, items);
				}
			}
			obj.mapZ = Map.ENTITIES;
			return obj;
		}
		
	}

}