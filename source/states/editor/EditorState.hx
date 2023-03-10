package states.editor;

import sprites.Mario;
import flixel.group.FlxGroup;
import sprites.Tile;
import flixel.FlxG;
import flixel.FlxState;
import flixel.addons.display.FlxGridOverlay;
import flixel.FlxSprite;
import sprites.TileGroup;
import flixel.math.FlxPoint;
import tools.Util;
import flixel.text.FlxText;
import flixel.addons.ui.FlxUIButton;

class EditorState extends FlxState {
	var tiles:TileGroup = null;
	var selectedTile:Tile = null;
	var marioSpawn:MarioSpawn = null;
	var selectedMarioSpawn:MarioSpawn = null;

	var levelData:LevelMeta = {
		tiles: [
			for (i in 0...4)
				{
					x: i,
					y: 0,
					type: 'ground',
					id: 1
				}
		].concat([
			for (i in 0...4)
				{
					x: i,
					y: 1,
					type: 'ground',
					id: i + 4
				}
			]),
		spawn: {
			x: 1,
			y: 2
		},
		theme: "ground",
		scale: 2
	}

	var tileSize:Float = 16;

	var scrollPosition:FlxPoint = new FlxPoint(0, 0);
	var selectedTilePosition:FlxPoint = new FlxPoint(0, 0);

	var types:Array<String> = [];
	var selectedType:Int = 0;

	var cameraBounds:MinAndMax = Util.getCameraBounds();

	override public function new(data:LevelMeta = null){
		if(data != null) this.levelData = data;
		super();
	}

	override public function create():Void {
		super.create();
		bgColor = 0xff8f9aff;

		selectedTile = new Tile(0, 0, levelData.scale + 0.1);
		selectedTile.alpha = 0.4;

		selectedMarioSpawn = new MarioSpawn(0, 0, levelData.scale);
		selectedMarioSpawn.alpha = 0.4;

		types = selectedTile.anims;
		types.reverse();
		types.push('spawn');

		FlxG.mouse.visible = true;
		FlxG.mouse.useSystemCursor = true;

		tileSize = 16 * levelData.scale;

		FlxG.watch.add(FlxG.camera, 'zoom', 'zoom');
		FlxG.watch.add(scrollPosition, 'x', 'scrollX');
		FlxG.watch.add(scrollPosition, 'y', 'scrollY');
		FlxG.watch.add(cameraBounds, 'width', 'cameraWidth');
		FlxG.watch.add(cameraBounds, 'height', 'cameraHeight');
		FlxG.watch.add(FlxG.mouse, 'wheel', 'mouseScroll');
		FlxG.watch.addMouse();

		tiles = new TileGroup(levelData);
		marioSpawn = new MarioSpawn(levelData.spawn.x, levelData.spawn.y, levelData.scale);

		add(tiles);
		add(marioSpawn);
		add(selectedMarioSpawn);
		add(selectedTile);
	}

	override public function update(elapsed:Float):Void {
		super.update(elapsed);
		cameraBounds = Util.getCameraBounds();
		var x:Float = Math.floor(FlxG.mouse.x / tileSize) * tileSize;
		var y:Float = Math.floor(FlxG.mouse.y / tileSize) * tileSize;
		selectedTilePosition.x = x / tileSize;
		selectedTilePosition.y = y / tileSize;
		x += tileSize / 2;
		var subVal:Int = 7;
		x -= subVal;
		y -= subVal;
		y += tileSize / 2;
		selectedTile.x = x;
		selectedTile.y = y;
		selectedMarioSpawn.x = x;
		selectedMarioSpawn.y = y;
		if (FlxG.keys.anyPressed([A, LEFT]))
			FlxG.camera.scroll.x -= 4;
		if (FlxG.keys.anyPressed([D, RIGHT]))
			FlxG.camera.scroll.x += 4;
		if (FlxG.keys.anyPressed([UP, W]))
			FlxG.camera.scroll.y -= 4;
		if (FlxG.keys.anyPressed([S, DOWN]))
			FlxG.camera.scroll.y += 4;

		scrollPosition.x = Math.floor(FlxG.camera.scroll.x);
		scrollPosition.y = Math.floor(FlxG.camera.scroll.y);
		if (scrollPosition.x < 0)
			scrollPosition.x = 0;
		if (scrollPosition.y > 0)
			scrollPosition.y = 0;

		FlxG.camera.scroll.x = scrollPosition.x;
		FlxG.camera.scroll.y = scrollPosition.y;

		var x:Int = Std.int(selectedTilePosition.x);
		var y:Int = Std.int(FlxG.height / tileSize - selectedTilePosition.y) - 1;

		var mouseMoveInThisFrame:Int = Std.int(Util.clamp(FlxG.mouse.wheel, -1, 1));
		selectedType += mouseMoveInThisFrame;

		if (FlxG.keys.justPressed.ENTER) {
			FlxG.switchState(new states.PlayState(this.levelData, marioSpawn.x, marioSpawn.y));
		}
		if (selectedType < 0)
			selectedType = types.length - 1;
		if (selectedType >= types.length)
			selectedType = 0;
		if (types[selectedType] == 'spawn') {
			selectedTile.visible = false;
			selectedMarioSpawn.visible = true;
		} else {
			selectedTile.visible = true;
			selectedMarioSpawn.visible = false;
			selectedTile.changeType(types[selectedType]);
		}

		if (FlxG.keys.justPressed.CONTROL && FlxG.keys.justPressed.S) {
			var json:String = haxe.Json.stringify(levelData);
		}

		if (FlxG.mouse.pressed) {
			if (types[selectedType] == 'spawn') {
				levelData.spawn.x = x;
				levelData.spawn.y = y;
				marioSpawn.changePosition(x, y);
				return;
			}
			var nextId:Int = levelData.tiles[levelData.tiles.length - 1].id + 1;
			if (tiles.isTileOccupied(x, y))
				return;
			var t:TileMeta = {
				x: x,
				y: y,
				type: types[selectedType],
				id: nextId
			};
			levelData.tiles.push(t);
			tiles.addNewTile(levelData, t);
		}
		if (FlxG.mouse.pressedRight) {
			tiles.destroyTileAtPos(x, y);
			var i:Int = 0;
			for (t in levelData.tiles) {
				if (t.x == x && t.y == y) {
					levelData.tiles.splice(i, 1);
				}
				i++;
			}
		}
	}
}

class MarioSpawn extends FlxSprite {
	public function new(xPos:Float, yPos:Float, scale:Float) {
		super(0, 0);
		loadGraphic("assets/images/mario/small.png", true, 17, 18);
		animation.add("idle", [0]);
		animation.play("idle");
		this.scale.set(scale, scale);
		changePosition(xPos, yPos);
	}

	public function changePosition(xPos:Float, yPos:Float):FlxPoint {
		var w:Float = 17 * this.scale.x;
		var x:Float = (xPos) * w;
		var y:Float = (yPos) * w;
		x += w / 2;
		var subVal:Int = 3;
		x -= subVal;
		y += w / 2;
		y += subVal;
		x -= 7;
		this.x = x;
		this.y = FlxG.height - y;
		return new FlxPoint(this.x, this.y);
	}
}
