// Copyright © 2016-2017 Shawn Baker using the MIT License.
import UIKit
import AVFoundation
import VideoToolbox

class VideoViewController: UIViewController
{
	// constants
	let READ_SIZE = 16384
	let MAX_READ_ERRORS = 300
	let FADE_OUT_WAIT_TIME = 8.0
	let FADE_OUT_INTERVAL = 1.0
	let FADE_IN_INTERVAL = 0.1

	// outlets
	@IBOutlet weak var statusLabel: UILabel!
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var backButton: UIButton!
	@IBOutlet weak var snapshotButton: UIButton!
	
	// instance variables
	var camera: Camera?
	var fadeOutTimer: Timer?
	var running = false
	var stopped = false
	var takeSnapshot = false
	var zoomPan: LayerZoomPan?
	let app = UIApplication.shared.delegate as! AppDelegate
	var videoLayer: AVSampleBufferDisplayLayer?
	var formatDescription: CMVideoFormatDescription?
	var videoSession: VTDecompressionSession?
	var fullsps: [UInt8]?
	var fullpps: [UInt8]?
	var sps: [UInt8]?
	var pps: [UInt8]?

	//**********************************************************************
	// viewDidLoad
	//**********************************************************************
	override func viewDidLoad()
	{
		// initialize the view and controls
		super.viewDidLoad()
		view.isUserInteractionEnabled = true
		view.backgroundColor = UIColor.black
		nameLabel.text = camera!.name
		statusLabel.text = "initializingVideo".local

		// handle orientation changes
		NotificationCenter.default.addObserver(self, selector: #selector(orientationDidChange), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
		
		// set up the tap and double tap gesture recognizers
		let doubleTap = UITapGestureRecognizer(target: self, action: #selector(self.handleDoubleTapGesture(_:)))
		doubleTap.numberOfTapsRequired = 2
		view.addGestureRecognizer(doubleTap)
		let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTapGesture(_:)))
		tap.numberOfTapsRequired = 1
		tap.require(toFail: doubleTap)
		view.addGestureRecognizer(tap)

		// set up the pinch and pan gesture recognizers
		let pinch = UIPinchGestureRecognizer(target: self, action: #selector(self.handlePinchGesture(_:)))
		view.addGestureRecognizer(pinch)
		let pan = UIPanGestureRecognizer(target: self, action: #selector(self.handlePanGesture(_:)))
		pan.maximumNumberOfTouches = 2
		view.addGestureRecognizer(pan)

		// start reading the stream and passing the data to the video layer
		createVideoLayer()
		createReadThread()
		
		// fade out after a while
		startFadeOutTimer()
	}
	
	//**********************************************************************
	// deinit
	//**********************************************************************
	deinit
	{
		NotificationCenter.default.removeObserver(self)
	}
	
	//**********************************************************************
	// orientationDidChange
	//**********************************************************************
	@objc func orientationDidChange()
	{
		videoLayer?.frame = view.frame
		videoLayer?.bounds = view.bounds
		zoomPan?.reset()
	}
	
	//**********************************************************************
	// viewWillDisappear
	//**********************************************************************
	override func viewWillDisappear(_ animated: Bool)
	{
		// stop fading out the controls
		stopFadeOutTimer()
		
		// wait for the read thread to stop
		running = false
		while !stopped
		{
			usleep(10000)
		}
		
		// terminate the video processing
		if let layer = videoLayer
		{
			layer.stopRequestingMediaData()
			layer.flush()
		}
		destroyVideoSession()
	}

	//**********************************************************************
	// handleBackButtonTouchUpInside
	//**********************************************************************
	@IBAction func handleBackButtonTouchUpInside(_ sender: Any)
	{
		dismiss(animated: true)
	}

	//**********************************************************************
	// handleSnapshotButtonTouchUpInside
	//**********************************************************************
	@IBAction func handleSnapshotButtonTouchUpInside(_ sender: Any)
	{
		snapshotButton.isEnabled = false
		takeSnapshot = true
		startFadeOutTimer()
	}

	//**********************************************************************
	// handleTapGesture
	//**********************************************************************
	@objc func handleTapGesture(_ tap: UITapGestureRecognizer)
	{
		fadeIn()
	}
	
	//**********************************************************************
	// handleDoubleTapGesture
	//**********************************************************************
	@objc func handleDoubleTapGesture(_ tap: UITapGestureRecognizer)
	{
		zoomPan?.setZoomPan(1, CGPoint.zero)
	}
	
	//**********************************************************************
	// handlePinchGesture
	//**********************************************************************
	@objc func handlePinchGesture(_ pinch: UIPinchGestureRecognizer)
	{
		zoomPan?.handlePinchGesture(pinch)
	}
	
	//**********************************************************************
	// handlePanGesture
	//**********************************************************************
	@objc func handlePanGesture(_ pan: UIPanGestureRecognizer)
	{
		zoomPan?.handlePanGesture(pan)
	}
	
	//**********************************************************************
	// startFadeOutTimer
	//**********************************************************************
	func startFadeOutTimer()
	{
		stopFadeOutTimer()
		fadeOutTimer = Timer.scheduledTimer(timeInterval: FADE_OUT_WAIT_TIME, target: self, selector: #selector(fadeOut), userInfo: nil, repeats: false)
	}
	
	//**********************************************************************
	// stopFadeOutTimer
	//**********************************************************************
	func stopFadeOutTimer()
	{
		if let timer = fadeOutTimer, timer.isValid
		{
			timer.invalidate()
		}
		fadeOutTimer = nil
	}
	
	//**********************************************************************
	// fadeIn
	//**********************************************************************
	func fadeIn()
	{
		stopFadeOutTimer()
		UIView.animate(withDuration: FADE_IN_INTERVAL, delay: 0, options: UIViewAnimationOptions.curveEaseIn, animations:
		{
			self.statusLabel.alpha = 1.0
			self.nameLabel.alpha = 1.0
			self.backButton.alpha = 1.0
			self.snapshotButton.alpha = 1.0
		},
		completion: { (Bool) -> Void in self.startFadeOutTimer() })
	}
	
	//**********************************************************************
	// fadeOut
	//**********************************************************************
	@objc func fadeOut()
	{
		stopFadeOutTimer()
		UIView.animate(withDuration: FADE_OUT_INTERVAL, delay: 0.0, options: UIViewAnimationOptions.curveEaseIn, animations:
		{
			self.statusLabel.alpha = 0.0
			self.nameLabel.alpha = 0.0
			self.backButton.alpha = 0.0
			self.snapshotButton.alpha = 0.0
		},
		completion: nil)
	}
	
	//**********************************************************************
	// createVideoLayer
	//**********************************************************************
	func createVideoLayer()
	{
		if videoLayer == nil
		{
			videoLayer = AVSampleBufferDisplayLayer()
			if let layer = videoLayer
			{
				layer.frame = view.frame
				layer.bounds = view.bounds
				layer.position = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
				layer.videoGravity = AVLayerVideoGravity.resizeAspect
				layer.backgroundColor = UIColor.black.cgColor

				view.layer.addSublayer(layer)
				view.bringSubview(toFront: statusLabel)
				view.bringSubview(toFront: nameLabel)
				view.bringSubview(toFront: backButton)
				view.bringSubview(toFront: snapshotButton)

				zoomPan = LayerZoomPan(view, layer)
			}
		}
	}
	
	//**********************************************************************
	// createReadThread
	//**********************************************************************
	func createReadThread()
	{
		if camera != nil
		{
			DispatchQueue.global(qos: .background).async
			{
				self.stopped = false
				let socket = openSocket(self.camera!.source.address, Int32(self.app.settings.source.port), Int32(self.app.settings.scanTimeout))
				if (socket >= 0)
				{
					var numZeroes = 0
					var numReadErrors = 0
					var nal = [UInt8]()
					let ptr = UnsafeMutablePointer<UInt8>.allocate(capacity: self.READ_SIZE)
					let buffer = UnsafeMutableBufferPointer.init(start: ptr, count: self.READ_SIZE)
					var gotHeader = false
					self.running = true
					while self.running && numReadErrors < self.MAX_READ_ERRORS
					{
						let len = readSocket(socket, ptr, Int32(self.READ_SIZE))
						if len > 0
						{
							numReadErrors = 0
							for i in 0..<len
							{
								let b = buffer[Int(i)]
								if !self.running { break }
								if b == 0
								{
									numZeroes += 1
								}
								else
								{
									if b == 1 && numZeroes >= 3
									{
										while numZeroes > 3
										{
											nal.append(0)
											numZeroes -= 1
										}
										if gotHeader
										{
											if !self.running { break }
											self.processNal(&nal)
										}
										nal = [0, 0, 0, 1]
										gotHeader = true
									}
									else
									{
										while numZeroes > 0
										{
											nal.append(0)
											numZeroes -= 1
										}
										nal.append(b)
									}
									numZeroes = 0
								}
							}
						}
						else
						{
							numReadErrors += 1
						}
					}
					closeSocket(socket)
				}
				self.stopped = true
			}
		}
	}
	
	//**********************************************************************
	// processNal
	//**********************************************************************
	func processNal(_ nal: inout [UInt8])
	{
		// replace the start code with the NAL size
		let len = nal.count - 4
		var lenBig = CFSwapInt32HostToBig(UInt32(len))
		memcpy(&nal, &lenBig, 4)
		
		// create the video session when we have the SPS and PPS records
		let nalType = nal[4] & 0x1F
		if nalType == 7
		{
			fullsps = nal
		}
		else if nalType == 8
		{
			fullpps = nal
		}
		if fullsps != nil && fullpps != nil
		{
			destroyVideoSession()
			sps = Array(fullsps![4...])
			pps = Array(fullpps![4...])
			_ = createVideoSession()
			fullsps = nil
			fullpps = nil
			DispatchQueue.main.async
			{
				self.statusLabel.isHidden = true
			}
		}
		
		// decode the video NALs
		if videoSession != nil && (nalType == 1 || nalType == 5)
		{
			_ = decodeNal(nal)
		}
	}
	
	//**********************************************************************
	// decodeNal
	//**********************************************************************
	private func decodeNal(_ nal: [UInt8]) -> Bool
	{
		// create the block buffer from the NAL data
		var blockBuffer: CMBlockBuffer? = nil
		let nalPointer = UnsafeMutablePointer<UInt8>(mutating: nal)
		var status = CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault, nalPointer, nal.count, kCFAllocatorNull, nil, 0, nal.count, 0, &blockBuffer)
		if status != kCMBlockBufferNoErr
		{
			return false
		}
		
		// create the sample buffer from the block buffer
		var sampleBuffer: CMSampleBuffer?
		let sampleSizeArray = [nal.count]
		status = CMSampleBufferCreateReady(kCFAllocatorDefault, blockBuffer, formatDescription, 1, 0, nil, 1, sampleSizeArray, &sampleBuffer)
		if status != noErr
		{
			return false
		}
		if let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer!, true)
		{
			let dictionary = unsafeBitCast(CFArrayGetValueAtIndex(attachments, 0), to: CFMutableDictionary.self)
			CFDictionarySetValue(dictionary, Unmanaged.passUnretained(kCMSampleAttachmentKey_DisplayImmediately).toOpaque(),
								 Unmanaged.passUnretained(kCFBooleanTrue).toOpaque())
		}
		
		// pass the sample buffer to the video layer
		if let buffer = sampleBuffer, let layer = videoLayer, layer.isReadyForMoreMediaData
		{
			if takeSnapshot
			{
				var infoFlags = VTDecodeInfoFlags(rawValue: 0)
				status = VTDecompressionSessionDecodeFrame(videoSession!, buffer, [._EnableAsynchronousDecompression], nil, &infoFlags)
			}
			
			layer.enqueue(buffer)
			layer.setNeedsDisplay()
		}
		return true
	}

	//**********************************************************************
	// createVideoSession
	//**********************************************************************
	private func createVideoSession() -> Bool
	{
		// create a new format description with the SPS and PPS records
		formatDescription = nil
		let parameters = [UnsafePointer<UInt8>(pps!), UnsafePointer<UInt8>(sps!)]
		let sizes = [pps!.count, sps!.count]
		var status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault, 2, UnsafePointer(parameters), sizes, 4, &formatDescription)
		if status != noErr
		{
			return false
		}
		let dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription!)
		zoomPan?.setVideoSize(CGFloat(dimensions.width), CGFloat(dimensions.height))
		
		// create the decoder parameters
		let decoderParameters = NSMutableDictionary()
		let destinationPixelBufferAttributes = NSMutableDictionary()
		destinationPixelBufferAttributes.setValue(NSNumber(value: kCVPixelFormatType_32BGRA), forKey: kCVPixelBufferPixelFormatTypeKey as String)
		
		// create the callback for getting snapshots
		var callback = VTDecompressionOutputCallbackRecord()
		callback.decompressionOutputCallback = globalDecompressionCallback
		callback.decompressionOutputRefCon = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
		
		// create the video session
		status = VTDecompressionSessionCreate(nil, formatDescription!, decoderParameters, destinationPixelBufferAttributes, &callback, &videoSession)
		return status == noErr
	}

	//**********************************************************************
	// destroyVideoSession
	//**********************************************************************
	func destroyVideoSession()
	{
		if videoSession != nil
		{
			VTDecompressionSessionInvalidate(videoSession!)
			videoSession = nil
		}
		sps = nil
		pps = nil
		formatDescription = nil
	}
	
	//**********************************************************************
	// decompressionCallback
	//**********************************************************************
	func decompressionCallback(_ sourceFrameRefCon: UnsafeMutableRawPointer?, _ status: OSStatus, _ infoFlags: VTDecodeInfoFlags, _ imageBuffer: CVImageBuffer?, _ presentationTimeStamp: CMTime, _ presentationDuration: CMTime)
	{
		if takeSnapshot, let cvImageBuffer = imageBuffer
		{
			let ciImage = CIImage(cvImageBuffer: cvImageBuffer)
			let size = CVImageBufferGetEncodedSize(cvImageBuffer)
			let context = CIContext()
			if let cgImage = context.createCGImage(ciImage, from: CGRect(origin: CGPoint.zero, size: size))
			{
				let uiImage = UIImage(cgImage: cgImage)
				UIImageWriteToSavedPhotosAlbum(uiImage, self, #selector(imageSaved(_:didFinishSavingWithError:contextInfo:)), nil)
			}
			takeSnapshot = false
			DispatchQueue.main.async
			{
				self.snapshotButton.isEnabled = true
			}
		}
	}
	
	//**********************************************************************
	// imageSaved
	//**********************************************************************
	@objc func imageSaved(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer)
	{
		if let error = error
		{
			let ac = UIAlertController(title: "Save Error", message: error.localizedDescription, preferredStyle: .alert)
			ac.addAction(UIAlertAction(title: "OK", style: .default))
			present(ac, animated: true)
		}
		else
		{
			AudioServicesPlaySystemSoundWithCompletion(SystemSoundID(1108), nil)
		}
	}
}

//**********************************************************************
// globalDecompressionCallback
//**********************************************************************
private func globalDecompressionCallback(_ decompressionOutputRefCon: UnsafeMutableRawPointer?, _ sourceFrameRefCon: UnsafeMutableRawPointer?, _ status: OSStatus, _ infoFlags: VTDecodeInfoFlags, _ imageBuffer: CVImageBuffer?, _ presentationTimeStamp: CMTime, _ presentationDuration: CMTime) -> Void
{
	let videoController: VideoViewController = unsafeBitCast(decompressionOutputRefCon, to: VideoViewController.self)
	videoController.decompressionCallback(sourceFrameRefCon, status, infoFlags, imageBuffer, presentationTimeStamp, presentationDuration)
}
