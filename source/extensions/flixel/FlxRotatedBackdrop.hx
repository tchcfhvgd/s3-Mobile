package extensions.flixel;

import flixel.math.FlxMatrix;
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.FlxCamera;
import flixel.math.FlxRect;
import flixel.math.FlxAngle;
import flixel.math.FlxPoint;
import flixel.addons.display.FlxBackdrop;

using flixel.util.FlxColorTransformUtil;

// borrowed from cne
class FlxRotatedBackdrop extends FlxBackdrop
{
	/**
	 * The rotation of the of the backdrop, in degrees. Has no effect if `repeatAxes` is `NONE`.
	 */
	public var rotation(default, set):Float = 0.0;
	
	var _cosRotation:Float = 0.0;
	var _sinRotation:Float = 0.0;
	
	/**
	 * Modifies in-place
	**/
	function getRotatedView(view:FlxRect):FlxRect
	{
		if (rotation == 0) return view;
		
		return view.getRotatedBounds(rotation, FlxPoint.weak(view.width / 2, view.height / 2), view);
	}
	
	function set_rotation(value:Float):Float
	{
		if (value != rotation)
		{
			rotation = value;
			_cosRotation = Math.cos(value * FlxAngle.TO_RAD);
			_sinRotation = Math.sin(value * FlxAngle.TO_RAD);
			dirty = true;
		}
		return value;
	}
	
	override function drawComplex(camera:FlxCamera)
	{
		if (repeatAxes == NONE)
		{
			super.drawComplex(camera);
			return;
		}
		
		var drawDirect = !drawBlit;
		final graphic = drawBlit ? _blitGraphic : this.graphic;
		final frame = drawBlit ? _blitGraphic.imageFrame.frame : _frame;
		
		frame.prepareMatrix(_matrix, FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
		_matrix.translate(-origin.x, -origin.y);
		
		// The distance between repeated sprites, in screen space
		final tileSize = FlxPoint.get(frame.frame.width, frame.frame.height);
		
		if (drawDirect)
		{
			tileSize.set((frame.frame.width + spacing.x) * scale.x, (frame.frame.height + spacing.y) * scale.y);
			
			_matrix.scale(scale.x, scale.y);
			
			if (bakedRotationAngle <= 0)
			{
				updateTrig();
				
				if (angle != 0) _matrix.rotateWithTrig(_cosAngle, _sinAngle);
			}
		}
		
		var drawItem = null;
		if (FlxG.renderTile)
		{
			var isColored:Bool = (alpha != 1) || (color != 0xffffff);
			var hasColorOffsets:Bool = (colorTransform != null && colorTransform.hasRGBAOffsets());
			drawItem = camera.startQuadBatch(graphic, isColored, hasColorOffsets, blend, antialiasing, shader);
		}
		else
		{
			camera.buffer.lock();
		}
		
		getScreenPosition(_point, camera).subtractPoint(offset);
		var tilesX = 1;
		var tilesY = 1;
		var pivotX = width / 2;
		var pivotY = height / 2;
		if (repeatAxes != NONE)
		{
			final viewMargins = camera.getViewMarginRect();
			
			var view = switch (repeatAxes)
			{
				case X: FlxRect.get(viewMargins.x, 0, viewMargins.width, height);
				case Y: FlxRect.get(0, viewMargins.y, width, viewMargins.height);
				default: viewMargins; // XY
			}
			
			pivotX = view.width / 2;
			pivotY = view.height / 2;
			
			final oldViewWidth = view.width;
			final oldViewHeight = view.height;
			
			view = getRotatedView(view);
			
			// start of hack
			// TODO: fix this properly
			switch (repeatAxes)
			{
				case X:
					final widthIncrease = width * view.width / oldViewWidth;
					view.x -= widthIncrease / 2;
					view.width += widthIncrease;
				case Y:
					final heightIncrease = height * view.height / oldViewHeight;
					view.y -= heightIncrease / 2;
					view.height += heightIncrease;
				default:
			}
			// end of hack
			
			final bounds = getScreenBounds(camera);
			if (repeatAxes.x)
			{
				final origTileSizeX = (frameWidth + spacing.x) * scale.x;
				final left = modMin(bounds.right, origTileSizeX, view.left) - bounds.width;
				final right = modMax(bounds.left, origTileSizeX, view.right) + origTileSizeX;
				tilesX = Math.round((right - left) / tileSize.x);
				_point.x = left + _point.x - bounds.x;
			}
			
			if (repeatAxes.y)
			{
				final origTileSizeY = (frameHeight + spacing.y) * scale.y;
				final top = modMin(bounds.bottom, origTileSizeY, view.top) - bounds.height;
				final bottom = modMax(bounds.top, origTileSizeY, view.bottom) + origTileSizeY;
				tilesY = Math.round((bottom - top) / tileSize.y);
				_point.y = top + _point.y - bounds.y;
			}
			viewMargins.put();
			view.put();
			bounds.put();
		}
		_point.addPoint(origin);
		if (drawBlit) _point.addPoint(_blitOffset);
		
		_tileMatrix.identity();
		
		var isPixelPerfect = isPixelPerfectRender(camera);
		var shouldRotate = rotation != 0 && repeatAxes != NONE;
		
		for (tileX in 0...tilesX)
		{
			for (tileY in 0...tilesY)
			{
				_tileMatrix.copyFrom(_matrix);
				
				_tileMatrix.translate(_point.x + (tileSize.x * tileX), _point.y + (tileSize.y * tileY));
				
				if (shouldRotate)
				{
					_tileMatrix.translate(-pivotX, -pivotY);
					if (shouldRotate) _tileMatrix.rotateWithTrig(_cosRotation, _sinRotation);
					_tileMatrix.translate(pivotX, pivotY);
				}
				
				if (isPixelPerfect)
				{
					_tileMatrix.tx = Math.floor(_tileMatrix.tx);
					_tileMatrix.ty = Math.floor(_tileMatrix.ty);
				}
				
				if (FlxG.renderBlit)
				{
					final pixels = drawBlit ? _blitGraphic.bitmap : framePixels;
					camera.drawPixels(frame, pixels, _tileMatrix, colorTransform, blend, antialiasing, shader);
				}
				else
				{
					drawItem.addQuad(frame, _tileMatrix, colorTransform);
				}
			}
		}
		
		tileSize.put();
		if (FlxG.renderBlit) camera.buffer.unlock();
	}
}
