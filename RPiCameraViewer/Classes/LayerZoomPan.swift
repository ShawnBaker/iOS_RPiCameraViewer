// Copyright © 2016-2017 Shawn Baker using the MIT License.
import Foundation
import UIKit

class LayerZoomPan
{
	// instance variables
	var view: UIView
	var layer: CALayer
	var minZoom: CGFloat = 0.1
	var maxZoom: CGFloat = 10.0
	var videoSize = CGSize.zero
	var fitSize = CGSize.zero
	var zoom: CGFloat = 1
	var pan = CGPoint.zero
	var panStart = CGPoint.zero
	var zoomStart: CGFloat = 1
	var zoomCenter = CGPoint.zero

	//**********************************************************************
	// init
	//**********************************************************************
	init(_ view: UIView, _ layer: CALayer)
	{
		self.view = view
		self.layer = layer
		layer.actions = ["transform": NSNull()]
	}
	
	//**********************************************************************
	// reset
	//**********************************************************************
	func reset()
	{
		// get the fitted view size
		let viewSize = view.bounds.size
		let viewAspect = viewSize.height / viewSize.width
		let videoAspect = videoSize.height / videoSize.width
		if videoAspect < viewAspect
		{
			fitSize.width = viewSize.width
			fitSize.height = videoSize.height * viewSize.width / videoSize.width
		}
		else
		{
			fitSize.width = videoSize.width * viewSize.height / videoSize.height
			fitSize.height = viewSize.height
		}
		
		// set the layer position
		layer.position = CGPoint(x: viewSize.width / 2, y: viewSize.height / 2)
		
		// clear the transform
		setZoomPan(1, CGPoint.zero)
	}
	
	//**********************************************************************
	// setVideoSize
	//**********************************************************************
	func setVideoSize(size: CGSize)
	{
		if size != videoSize
		{
			// set the video size
			videoSize = size;
			
			// reset the view
			reset()
		}
	}
	
	//**********************************************************************
	// setVideoSize
	//**********************************************************************
	func setVideoSize(_ width: CGFloat, _ height: CGFloat)
	{
		setVideoSize(size: CGSize(width: width, height: height))
	}
	
	//**********************************************************************
	// setZoom
	//**********************************************************************
	func setZoom(_ zoom: CGFloat)
	{
		self.zoom = zoom
		checkPan()
		setTransform()
	}

	//**********************************************************************
	// setPan
	//**********************************************************************
	func setPan(_ pan: CGPoint)
	{
		self.pan = pan
		checkPan()
		setTransform()
	}

	//**********************************************************************
	// setPan
	//**********************************************************************
	func setPan(_ x: CGFloat, _ y: CGFloat)
	{
		setPan(CGPoint(x: x, y: y))
	}

	//**********************************************************************
	// setZoomPan
	//**********************************************************************
	func setZoomPan(_ zoom: CGFloat, _ pan: CGPoint)
	{
		self.zoom = zoom
		self.pan = pan
		checkPan()
		setTransform()
	}
	
	//**********************************************************************
	// setZoomPan
	//**********************************************************************
	func setZoomPan(_ zoom: CGFloat, _ panX: CGFloat, _ panY: CGFloat)
	{
		setZoomPan(zoom, CGPoint(x: panX, y: panY))
	}
	
	//**********************************************************************
	// checkPan
	//**********************************************************************
	func checkPan()
	{
		let maxPan = getMaxPan()

		if maxPan.x == 0 { pan.x = 0 }
		else if pan.x < -maxPan.x { pan.x = -maxPan.x }
		else if pan.x > maxPan.x { pan.x = maxPan.x }

		if maxPan.y == 0 { pan.y = 0 }
		else if pan.y < -maxPan.y { pan.y = -maxPan.y }
		else if pan.y > maxPan.y { pan.y = maxPan.y }
	}
	
	//**********************************************************************
	// getMaxPan
	//**********************************************************************
	func getMaxPan() -> CGPoint
	{
		let maxPan = CGPoint(x: max((fitSize.width * zoom - view.bounds.width) / 2, 0),
							 y: max((fitSize.height * zoom - view.bounds.height) / 2, 0))
		return maxPan
	}
	
	//**********************************************************************
	// setTransform
	//**********************************************************************
	func setTransform()
	{
		var transform = CATransform3DIdentity
		
		// add the panning
		if (pan.x != 0 || pan.y != 0)
		{
			transform = CATransform3DTranslate(transform, pan.x, pan.y, 0)
		}
		
		// scale relative to the center
		transform = CATransform3DScale(transform, zoom, zoom, 1)

		// set the transform
		layer.transform = transform
	}
	
	//**********************************************************************
	// handlePinchGesture
	//**********************************************************************
	func handlePinchGesture(_ gesture: UIPinchGestureRecognizer)
	{
		if gesture.state == UIGestureRecognizerState.began
		{
			zoomStart = zoom
			zoomCenter.x = view.bounds.width / 2
			zoomCenter.y = view.bounds.height / 2
		}
		
		var newZoom = zoomStart * gesture.scale
		newZoom = max(minZoom, min(newZoom, maxZoom))
		if newZoom != zoom
		{
			let location = gesture.location(in: view)
			let offset = CGPoint(x: location.x - zoomCenter.x, y: location.y - zoomCenter.y)
			let focus = CGPoint(x: (offset.x - pan.x) / zoom, y: (offset.y - pan.y) / zoom)
			setZoomPan(newZoom, offset.x - focus.x * newZoom, offset.y - focus.y * newZoom)
		}
	}
	
	//**********************************************************************
	// handlePanGesture
	//**********************************************************************
	func handlePanGesture(_ gesture: UIPanGestureRecognizer)
	{
		if gesture.state == UIGestureRecognizerState.began
		{
			panStart = pan
		}
		if (zoom > 1)
		{
			let distance = gesture.translation(in: view)
			setPan(panStart.x + distance.x, panStart.y + distance.y)
		}
	}
}
