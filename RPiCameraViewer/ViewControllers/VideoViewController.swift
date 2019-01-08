// Copyright © 2016-2018 Shawn Baker using the MIT License.
import UIKit
import AVFoundation
import VideoToolbox
import Photos

class VideoViewController: UIViewController
{
	// constants
	let READ_SIZE = 16384
	let MAX_READ_ERRORS = 300
	let FADE_OUT_WAIT_TIME = 8.0
	let FADE_OUT_INTERVAL = 1.0
	let FADE_IN_INTERVAL = 0.1

	// outlets
	@IBOutlet weak var imageView: UIImageView!
	@IBOutlet weak var statusLabel: UILabel!
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var closeButton: UIButton!
	@IBOutlet weak var snapshotButton: UIButton!
	
	// instance variables
	var camera: Camera?
	var fadeOutTimer: Timer?
	var running = false
	var close = false
	var dispatchGroup = DispatchGroup()
	var zoomPan: ZoomPan?
	let app = UIApplication.shared.delegate as! AppDelegate
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
		nameLabel.text = camera!.name
		zoomPan = ZoomPan(imageView)
		
		// set up the tap and double tap gesture recognizers
		let doubleTap = UITapGestureRecognizer(target: self, action: #selector(self.handleDoubleTapGesture(_:)))
		doubleTap.numberOfTapsRequired = 2
		view.addGestureRecognizer(doubleTap)
		let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTapGesture(_:)))
		tap.numberOfTapsRequired = 1
		tap.require(toFail: doubleTap)
		view.addGestureRecognizer(tap)

		// set up the pinch and pan gesture recognizers
		let pinch = UIPinchGestureRecognizer(target: zoomPan, action: #selector(zoomPan!.handlePinchGesture(_:)))
		view.addGestureRecognizer(pinch)
		let pan = UIPanGestureRecognizer(target: zoomPan, action: #selector(zoomPan!.handlePanGesture(_:)))
		pan.maximumNumberOfTouches = 2
		view.addGestureRecognizer(pan)

		// don't let the device dim or sleep while showing video
		UIApplication.shared.isIdleTimerDisabled = true
		
		// start reading the stream and passing the data to the video layer
		app.videoViewController = self
		start()
	}
	
	//**********************************************************************
	// start
	//**********************************************************************
	func start()
	{
		// set the status label
		statusLabel.text = "initializingVideo".local
		statusLabel.textColor = Utils.goodTextColor
		statusLabel.isHidden = false
		imageView.image = nil

		// start reading the stream and decoding the video
		if createReadThread()
		{
			// fade out after a while
			startFadeOutTimer()
		}
		
		// start listening for orientation changes
		NotificationCenter.default.addObserver(self, selector: #selector(orientationDidChange), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
	}
	
	//**********************************************************************
	// stop
	//**********************************************************************
	func stop()
	{
		running = false
	}
	
	//**********************************************************************
	// stopVideo
	//**********************************************************************
	func stopVideo()
	{
		// stop listening for orientation changes
		NotificationCenter.default.removeObserver(self)
		
		// stop fading out the controls
		stopFadeOutTimer()
		
		// terminate the video processing
		destroyVideoSession()
		
		// set the status label
		statusError("videoStopped".local)
		
		// close the controller if necessary
		if close
		{
			dismiss(animated: true)
		}
	}
	
	//**********************************************************************
	// statusError
	//**********************************************************************
	func statusError(_ message: String)
	{
		statusLabel.text = message
		statusLabel.textColor = Utils.badTextColor
		statusLabel.isHidden = false
		snapshotButton.isHidden = true
		stopFadeOutTimer()
	}
	
	//**********************************************************************
	// orientationDidChange
	//**********************************************************************
	@objc func orientationDidChange()
	{
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute:
		{
			self.zoomPan?.reset()
		})
	}
	
	//**********************************************************************
	// viewWillDisappear
	//**********************************************************************
	override func viewWillDisappear(_ animated: Bool)
	{
		UIApplication.shared.isIdleTimerDisabled = false
		app.videoViewController = nil
	}

	//**********************************************************************
	// handleCloseButtonTouchUpInside
	//**********************************************************************
	@IBAction func handleCloseButtonTouchUpInside(_ sender: Any)
	{
		if running
		{
			close = true
			stop()
		}
		else
		{
			dismiss(animated: true)
		}
	}

	//**********************************************************************
	// handleSnapshotButtonTouchUpInside
	//**********************************************************************
	@IBAction func handleSnapshotButtonTouchUpInside(_ sender: Any)
	{
		startFadeOutTimer()
		
		// check permissions
		let status = PHPhotoLibrary.authorizationStatus()
		if status == .authorized
		{
			takeSnapshot()
		}
		else if status == .notDetermined
		{
			PHPhotoLibrary.requestAuthorization()
			{ status in
				if status == .authorized
				{
					DispatchQueue.main.async
					{
						self.takeSnapshot()
					}
				}
			}
		}
		else
		{
			Utils.error(self, "errorNotAuthorizedToSavePhotos")
		}
	}
	
	//**********************************************************************
	// takeSnapshot
	//**********************************************************************
	func takeSnapshot()
	{
		// hide the controls
		self.nameLabel.isHidden = true
		self.closeButton.isHidden = true
		self.snapshotButton.isHidden = true
		
		// take the snapshot
		if let uiImage = Utils.getSnapshot(view)
		{
			UIImageWriteToSavedPhotosAlbum(uiImage, self, #selector(imageSaved(_:didFinishSavingWithError:contextInfo:)), nil)
		}
		
		// show the controls
		self.nameLabel.isHidden = false
		self.closeButton.isHidden = false
		self.snapshotButton.isHidden = false
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
			self.closeButton.alpha = 1.0
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
			self.closeButton.alpha = 0.0
			self.snapshotButton.alpha = 0.0
		},
		completion: nil)
	}
	
	//**********************************************************************
	// createReadThread
	//**********************************************************************
	func createReadThread() -> Bool
	{
		if camera == nil
		{
			statusError("errorNoCamera".local)
			return false
		}
		
		var address = camera!.address
		if Utils.isHostname(address)
		{
			address = Utils.resolveHostname(address)
			if address.isEmpty
			{
				let message = String(format: "errorCouldntResolveHostname".local, camera!.address)
				statusError(message)
				return false
			}
		}
		
		DispatchQueue.global(qos: .background).async
		{
			self.dispatchGroup.enter()
			self.dispatchGroup.notify(queue: .main)
			{
				self.stopVideo()
			}
			let socket = openSocket(address, Int32(self.camera!.port), Int32(self.app.settings.scanTimeout))
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
				ptr.deallocate()
			}
			self.dispatchGroup.leave()
		}
		
		return true
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
		
		// pass the sample buffer to the decoder
		if let buffer = sampleBuffer, CMSampleBufferGetNumSamples(buffer) > 0
		{
			var infoFlags = VTDecodeInfoFlags(rawValue: 0)
			status = VTDecompressionSessionDecodeFrame(videoSession!, buffer, [._EnableAsynchronousDecompression], nil, &infoFlags)
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
		DispatchQueue.main.async
		{
			self.zoomPan?.setVideoSize(CGFloat(dimensions.width), CGFloat(dimensions.height))
		}
		
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
		if let session = videoSession
		{
			VTDecompressionSessionWaitForAsynchronousFrames(session)
			VTDecompressionSessionInvalidate(session)
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
		if running, let cvImageBuffer = imageBuffer
		{
			let ciImage = CIImage(cvImageBuffer: cvImageBuffer)
			let size = CVImageBufferGetEncodedSize(cvImageBuffer)
			let context = CIContext()
			if let cgImage = context.createCGImage(ciImage, from: CGRect(origin: CGPoint.zero, size: size))
			{
				let uiImage = UIImage(cgImage: cgImage)
				DispatchQueue.main.async
				{
					self.imageView.image = uiImage
				}
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
