// Copyright © 2016-2017 Shawn Baker using the MIT License.
import UIKit
import AVFoundation
import VideoToolbox

class VideoViewController: UIViewController
{
	// constants
	let READ_SIZE = 16384
	let MAX_READ_ERRORS = 300

	// outlets
	@IBOutlet weak var statusLabel: UILabel!
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var backButton: UIButton!
	@IBOutlet weak var snapshotButton: UIButton!
	
	// instance variables
	var camera: Camera?
	var running = false
	var stopped = false
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
		super.viewDidLoad()
		statusLabel.text = "initializingVideo".local
		nameLabel.text = camera!.name
		createVideoLayer()
		createReadThread()
	}
	
	//**********************************************************************
	// viewWillDisappear
	//**********************************************************************
	override func viewWillDisappear(_ animated: Bool)
	{
		// wait for the read thread to stop
		running = false
		while !stopped
		{
			usleep(10000)
		}
		
		// terminate the video processing
		if let layer = videoLayer
		{
			layer.flush()
			layer.stopRequestingMediaData()
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
							//print("read", len)
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
					//print("done", numReadErrors)
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
			layer.enqueue(buffer)
			layer.setNeedsDisplay()
		}
		return true;
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
		
		// create the decoder parameters
		let decoderParameters = NSMutableDictionary()
		let destinationPixelBufferAttributes = NSMutableDictionary()
		destinationPixelBufferAttributes.setValue(NSNumber(value: kCVPixelFormatType_32BGRA), forKey: kCVPixelBufferPixelFormatTypeKey as String)
		
		// create the video session
		status = VTDecompressionSessionCreate(nil, formatDescription!, decoderParameters, destinationPixelBufferAttributes, nil, &videoSession)
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
}
