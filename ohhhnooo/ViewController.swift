//
//  ViewController.swift
//  ohhhnooo
//
//  Created by Oliver Mahoney on 16/10/2018.
//  Copyright © 2018 Oliver Mahoney. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import SnapKit

class ViewController: UIViewController, AVAudioRecorderDelegate, AVAudioPlayerDelegate {

    var recordButton = UIButton()
    var playButton = UIButton()

    // Recorder
    var audioRecorder: AVAudioRecorder!
    var audioPlayer : AVAudioPlayer!
    var meterTimer:Timer!
    var isAudioRecordingGranted: Bool!
    var isRecording = false
    var isPlaying = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        check_record_permission()
    }
    
    func setupViews(){
        
        view.addSubview(playButton)
        playButton.setTitle("", for: .normal)
        playButton.setTitleColor(UIColor.blue, for: .normal )
        //playButton.setBackgroundImage(UIImage(imageLiteralResourceName: "mark_background.jpeg"), for: .normal);
        playButton.setImage(UIImage(imageLiteralResourceName: "mark_background.jpeg"), for: .normal)
        playButton.imageView?.contentMode = .scaleAspectFill
        playButton.addTarget(self, action: #selector(playRecording), for: .touchUpInside)
        playButton.snp.makeConstraints({ (make) in
            make.top.left.right.equalTo(view)
            make.bottom.equalTo(view).offset(-50)
        })
        
        view.addSubview(recordButton)
        recordButton.backgroundColor = UIColor.red
        recordButton.setTitle("Record New", for: .normal)
        recordButton.setTitleColor(UIColor.white, for: .normal )
        recordButton.addTarget(self, action: #selector(toggleRecording), for: .touchUpInside)
        recordButton.snp.makeConstraints({ (make) in
            make.top.equalTo(playButton.snp.bottom)
            make.left.right.equalTo(view)
            make.bottom.equalTo(view)
        })
    }
    
    @objc func playRecording(){
        if(isPlaying)
        {
            audioPlayer.stop()
            recordButton.isEnabled = true
            playButton.setTitle("Play", for: .normal)
            isPlaying = false
        }
        else
        {
            if FileManager.default.fileExists(atPath: getFileUrl().path)
            {
                recordButton.isEnabled = false
                playButton.setTitle("", for: .normal)
                prepare_play()
                audioPlayer.play()
                isPlaying = true
            }
            else
            {
                display_alert(msg_title: "Error", msg_desc: "Audio file is missing.", action_title: "OK")
            }
        }
    }
    
    func prepare_play()
    {
        do
        {
            audioPlayer = try AVAudioPlayer(contentsOf: getFileUrl())
            audioPlayer.delegate = self
            audioPlayer.prepareToPlay()
        }
        catch{
            print("Error")
        }
    }
    
    @objc func toggleRecording(){
        if(isRecording)
        {
            finishAudioRecording(success: true)
            recordButton.setTitle("Record New", for: .normal)
            playButton.isEnabled = true
            isRecording = false
        }
        else
        {
            setup_recorder()
            
            audioRecorder.record()
            meterTimer = Timer.scheduledTimer(timeInterval: 0.1, target:self, selector:#selector(self.updateAudioMeter(timer:)), userInfo:nil, repeats:true)
            recordButton.setTitle("Stop", for: .normal)
            playButton.isEnabled = false
            isRecording = true
        }
    }
    
    @objc func updateAudioMeter(timer: Timer)
    {
        if audioRecorder.isRecording
        {
            let hr = Int((audioRecorder.currentTime / 60) / 60)
            let min = Int(audioRecorder.currentTime / 60)
            let sec = Int(audioRecorder.currentTime.truncatingRemainder(dividingBy: 60))
            let totalTimeString = String(format: "%02d:%02d:%02d", hr, min, sec)
            print(totalTimeString)
            //recordingTimeLabel.text = totalTimeString
            audioRecorder.updateMeters()
        }
    }
    
    func finishAudioRecording(success: Bool)
    {
        if success
        {
            audioRecorder.stop()
            audioRecorder = nil
            meterTimer.invalidate()
            print("recorded successfully.")
        }
        else
        {
            display_alert(msg_title: "Error", msg_desc: "Recording failed.", action_title: "OK")
        }
    }
    
    func setup_recorder()
    {
        if isAudioRecordingGranted
        {
            let session = AVAudioSession.sharedInstance()
            do
            {
                try session.setCategory(AVAudioSession.Category.playAndRecord, mode: AVAudioSession.Mode.spokenAudio, options: .defaultToSpeaker)
                try session.setActive(true)
                let settings = [
                    AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                    AVSampleRateKey: 44100,
                    AVNumberOfChannelsKey: 2,
                    AVEncoderAudioQualityKey:AVAudioQuality.high.rawValue
                ]
                audioRecorder = try AVAudioRecorder(url: getFileUrl(), settings: settings)
                audioRecorder.delegate = self
                audioRecorder.isMeteringEnabled = true
                audioRecorder.prepareToRecord()
            }
            catch let error {
                display_alert(msg_title: "Error", msg_desc: error.localizedDescription, action_title: "OK")
            }
        }
        else
        {
            display_alert(msg_title: "Error", msg_desc: "Don't have access to use your microphone.", action_title: "OK")
        }
    }
    
    func getDocumentsDirectory() -> URL
    {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    func getFileUrl() -> URL
    {
        let filename = "myRecording.m4a"
        let filePath = getDocumentsDirectory().appendingPathComponent(filename)
        return filePath
    }
    
    func check_record_permission()
    {
        switch AVAudioSession.sharedInstance().recordPermission {
        case AVAudioSession.RecordPermission.granted:
            isAudioRecordingGranted = true
            break
        case AVAudioSession.RecordPermission.denied:
            isAudioRecordingGranted = false
            break
        case AVAudioSession.RecordPermission.undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission({ (allowed) in
                if allowed {
                    self.isAudioRecordingGranted = true
                } else {
                    self.isAudioRecordingGranted = false
                }
            })
            break
        default:
            break
        }
    }
    
    // MARK: Helpers
    
    func display_alert(msg_title : String , msg_desc : String ,action_title : String)
    {
        let ac = UIAlertController(title: msg_title, message: msg_desc, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: action_title, style: .default)
        {
            (result : UIAlertAction) -> Void in
            _ = self.navigationController?.popViewController(animated: true)
        })
        present(ac, animated: true)
    }
    
    // MARK: Delegate functions
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool)
    {
        if !flag
        {
            finishAudioRecording(success: false)
        }
        playButton.isEnabled = true
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool)
    {
        recordButton.isEnabled = true
    }
    
    
}

