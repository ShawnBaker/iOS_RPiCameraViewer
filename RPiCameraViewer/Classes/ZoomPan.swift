// Copyright © 2017 Shawn Baker using the MIT License.
import Foundation
import UIKit

class ZoomPan
{
	// instance variables
	var view: UIView
	var minZoom: CGFloat = 1
	var maxZoom: CGFloat = 10.0
	var videoSize = CGSize.zero
	var fitSize = CGSize.zero
	var zoom: CGFloat = 1
	var pan = CGPoint.zero
	var panStart = CGPoint.zero

	//**********************************************************************
	// init
	//**********************************************************************
	init(_ view: UIView)
	{
		self.view = view
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
		
		// initialize the zoom and pan
		setZoomPan(zoom, pan)
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
		self.zoom = max(minZoom, min(zoom, maxZoom))
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
		self.zoom = max(minZoom, min(zoom, maxZoom))
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
	private func checkPan()
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
	private func getMaxPan() -> CGPoint
	{
		let maxPan = CGPoint(x: max((fitSize.width * zoom - view.bounds.width) / 2 / zoom, 0),
							 y: max((fitSize.height * zoom - view.bounds.height) / 2 / zoom, 0))
		return maxPan
	}
	
	//**********************************************************************
	// setTransform
	//**********************************************************************
	private func setTransform()
	{
		view.transform = CGAffineTransform.init(scaleX: zoom, y: zoom).translatedBy(x: pan.x, y: pan.y)
	}
	
	//**********************************************************************
	// handlePinchGesture
	//**********************************************************************
	@objc func handlePinchGesture(_ gesture: UIPinchGestureRecognizer)
	{
		var newZoom = zoom * gesture.scale
		newZoom = max(minZoom, min(newZoom, maxZoom))
		if newZoom != zoom
		{
			let diff = (newZoom / zoom) - 1
			let location = gesture.location(in: view)
			let offset = CGPoint(x: location.x - view.bounds.midX + pan.x, y: location.y - view.bounds.midY + pan.y)
			setZoomPan(newZoom, pan.x - offset.x * diff, pan.y - offset.y * diff)
		}
		gesture.scale = 1
	}

	//**********************************************************************
	// handlePanGesture
	//**********************************************************************
	@objc func handlePanGesture(_ gesture: UIPanGestureRecognizer)
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
