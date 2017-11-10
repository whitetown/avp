//
//  ViewController.swift
//  AVP
//
//  Created by Sergey Chehuta on 09/11/2017.
//  Copyright © 2017 WhiteTown. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, UITextViewDelegate, UITextFieldDelegate {

    let defaultURL = "https://www.whitetown.com/private/bow.mov"

    @IBOutlet weak var container: ContainerView!
    @IBOutlet weak var source: UITextField!
    @IBOutlet weak var bar: TrackBarView!
    @IBOutlet weak var points: UITextView!
    @IBOutlet weak var timer: UILabel!
    
    @IBOutlet  var fullHeight: NSLayoutConstraint!
    @IBOutlet  var reducedHeight: NSLayoutConstraint!

    var player : AVPlayer? = nil
    var observer : Any? = nil
    var canMoveSlider = true

    let helpLabel = UILabel()

    override func viewDidLoad()
    {
        super.viewDidLoad()

        self.source.text = defaultURL

        self.helpLabel.frame = container.frame
        self.helpLabel.numberOfLines = 0
        self.helpLabel.font = UIFont.systemFont(ofSize: 12.0)
        self.helpLabel.textAlignment = .center
        self.helpLabel.autoresizingMask = [ .flexibleWidth, .flexibleHeight, .flexibleBottomMargin ]
        self.helpLabel.text = "Enter URL and tap 'Play'\nYou can define fragments in seconds (20, 10):\n 20 seconds from the beginning, 10 seconds length"
        self.view.addSubview(self.helpLabel)
    }

    override func viewWillAppear(_ animated: Bool)
    {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillDisappear), name: Notification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppear), name: Notification.Name.UIKeyboardWillShow, object: nil)
    }

    @objc func keyboardWillAppear()
    {
        player?.pause()
        self.fullHeight.isActive = false
        self.reducedHeight.isActive = true
        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }

    @objc func keyboardWillDisappear()
    {
        self.reducedHeight.isActive = false
        self.fullHeight.isActive = true
        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }

    override func viewWillDisappear(_ animated: Bool)
    {
        NotificationCenter.default.removeObserver(self)
    }

    func playFrom(_ value : Int64)
    {
        player?.seek(to: CMTimeMake(value, 1), completionHandler: { (complete) in
            self.player?.play()
            self.canMoveSlider = true
        })
    }

    func load()
    {
        self.helpLabel.removeFromSuperview()

        var url : URL? = nil

        if let path = self.source.text {
            url = URL(string: path)
        }
        if url == nil {
            url = URL(string: defaultURL)
        }

//        url = URL.init(fileURLWithPath: "/Users/sergeychehuta/Downloads/bow.mov")

        if url == nil { /* error */ return }

        let item  = AVPlayerItem(url: url!)

        player = AVPlayer(playerItem: item)

        observer = player?.addPeriodicTimeObserver(forInterval: CMTimeMake(1,1),
                                                   queue: DispatchQueue.main) { [weak self] time in
                                                    if let canMoveSlider = self?.canMoveSlider, canMoveSlider {
                                                        self?.showTime(time)
                                                        self?.canMoveSlider = self?.bar.setSliderValue( Float( Int64(time.value) / Int64(time.timescale) ) ) ?? true
                                                    }
        }

        let playerLayer = AVPlayerLayer(player: player)

        playerLayer.backgroundColor = UIColor.black.cgColor
        playerLayer.frame = self.container.bounds
        self.container.layer.addSublayer(playerLayer)

        bar.sliderCallback = { [weak self] value in
            self?.player?.pause()
            self?.playFrom( value )
        }

        showTime(player?.currentItem?.duration ?? CMTimeMake(0, 0))
    }

    func showTime(_ time : CMTime)
    {
        if Int64(time.timescale) == 0 { return }

        let seconds = Int64(time.value) / Int64(time.timescale)
        
        timer.text = String(format: "%ld:%02d", seconds / 60, seconds % 60)
    }

    @IBAction func play(_ sender: Any?)
    {
        self.view.endEditing(true)
        if let player = player {
            if player.status != .readyToPlay { /* not ready */ return }

            bar.setString(points.text ?? "", total: player.currentItem?.duration.seconds ?? 0)
            playFrom( bar.getFirstFragment() )
            return;
        }

        stop(nil)
        load()
        if player?.status != .readyToPlay { /* not ready */ return }

        bar.setString(points.text ?? "", total: player?.currentItem?.duration.seconds ?? 0)
        playFrom( bar.getFirstFragment() )
    }

    @IBAction func stop(_ sender: Any?)
    {
        self.view.endEditing(true)
        player?.pause()
        if let sublayers = container.layer.sublayers {
            for sublayer in sublayers {
                sublayer.removeFromSuperlayer()
            }
        }
        if let observer = observer {
            player?.removeTimeObserver(observer)
        }
        bar.setString("", total: 0)
        player = nil
        timer.text = nil
    }

    @IBAction func pause(_ sender: Any?)
    {
        self.view.endEditing(true)
        player?.pause()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        self.view.endEditing(true)
        return false
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool
    {
        if text == "\n"
        {
            self.view.endEditing(true)
            return false
        }
        return true
    }

}

