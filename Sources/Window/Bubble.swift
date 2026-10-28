//
//  Example
//  man
//
//  Created by man 11/11/2018.
//  Update change by Denis 28/11/2026
//  Copyright © 2020 man. All rights reserved.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass

protocol BubbleDelegate: AnyObject {
    func didTapBubble()
}

//https://httpcodes.co/status/
private var _successStatusCodes = ["200","201","202","203","204","205","206","207","208","226"]
private var _informationalStatusCodes = ["100","101","102","103","122"]
private var _redirectionStatusCodes = ["300","301","302","303","304","305","306","307","308"]

private var _width: CGFloat = 25
private var _height: CGFloat = 25

class Bubble: UIView {

    weak var delegate: BubbleDelegate?

    public var width: CGFloat = _width
    public var height: CGFloat = _height

    private var numberLabel: UILabel? = {
        return UILabel.init()
    }()
    private var networkNumber: Int = 0


    // FIX 1: safeAreaInsets yang andal.
    // `UIApplication.shared.keyWindow` deprecated sejak iOS 13 dan mengembalikan nil
    // pada app berbasis UIScene -> inset.bottom jadi 0 -> clamp bawah tidak pernah efektif.
    static var safeAreaInsets: UIEdgeInsets {
        if #available(iOS 13.0, *) {
            let windows = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
            if let window = windows.first(where: { $0.isKeyWindow }) ?? windows.first {
                return window.safeAreaInsets
            }
        }
        return UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
    }

    private var currentSafeAreaInsets: UIEdgeInsets {
        // window milik bubble sendiri (CocoaDebugWindow) paling akurat saat sudah on-screen
        return self.window?.safeAreaInsets ?? Bubble.safeAreaInsets
    }

    // margin asli CocoaDebug: width/8*4.25 == 13.28125 untuk bubble 25pt
    private var horizontalInset: CGFloat { return self.width / 8 * 4.25 }
    private var verticalInset: CGFloat { return self.height / 8 * 4.25 }

    /// Rentang Y yang sah untuk center bubble: selalu di luar area status bar
    /// dan di luar strip home indicator (tempat gesture sistem menang).
    private var allowedCenterYRange: ClosedRange<CGFloat> {
        let insets = currentSafeAreaInsets
        let screenHeight = UIScreen.main.bounds.size.height
        let minY = verticalInset + insets.top
        let maxY = screenHeight - insets.bottom - verticalInset
        return minY...max(minY, maxY)
    }


    static var originalPosition: CGPoint {
        if CocoaDebugSettings.shared.bubbleFrameX != 0 && CocoaDebugSettings.shared.bubbleFrameY != 0 {
            // FIX 2: posisi tersimpan ikut di-clamp. Tanpa ini, bubble yang sudah
            // "nyangkut" di area home indicator akan kembali ke sana tiap app launch.
            let insets = safeAreaInsets
            let verticalInset = _height / 8 * 4.25
            let minY = verticalInset + insets.top
            let maxY = max(minY, UIScreen.main.bounds.size.height - insets.bottom - verticalInset)
            let savedY = CGFloat(CocoaDebugSettings.shared.bubbleFrameY)
            return CGPoint(x: CGFloat(CocoaDebugSettings.shared.bubbleFrameX),
                           y: min(max(savedY, minY), maxY))
        }

        var h = 0
        if #available(iOS 11.0, *) {
            if safeAreaInsets.top > 24.0 {
                h = 16;
            }
        }
        return CGPoint(x: 1.875 + _width/2, y: UIScreen.main.bounds.size.height/2 - _height - CGFloat(h))
    }

    static var size: CGSize {return CGSize(width: _width, height: _height)}


    //MARK: - tool
    fileprivate func initLabelEvent(_ content: String, _ foo: Bool) {
        if content == "🚀" || content == "❌"
        {
            //step 0
            let WH: CGFloat = 20
            //step 1
            let label = UILabel()
            label.text = content
            label.font = UIFont.boldSystemFont(ofSize: 14)

            //step 2
            if foo == true {
                label.frame = CGRect(x: self.frame.size.width/2 - WH/2, y: self.frame.size.height/2 - WH/2, width: WH, height: WH)
                self.addSubview(label)
            } else {
                label.frame = CGRect(x: self.center.x - WH/2, y: self.center.y - WH/2, width: WH, height: WH)
                self.superview?.addSubview(label)
            }
            //step 3
            UIView.animate(withDuration: 0.8, animations: {
                label.frame.origin.y = foo ? -100 : (self.center.y - 100)
                label.alpha = 0
            }, completion: { _ in
                label.removeFromSuperview()
            })
        }
        else
        {
            //step 0
            let WH: CGFloat = 35
            //step 1
            let label = UILabel()
            label.text = content
            label.textAlignment = .center
            label.adjustsFontSizeToFitWidth = true
            label.font = UIFont.boldSystemFont(ofSize: 14)

            if _informationalStatusCodes.contains(content) {
                label.textColor = "#4b8af7".hexColor
            }
            else if _redirectionStatusCodes.contains(content) {
                label.textColor = "#ff9800".hexColor
            }
            else {
                label.textColor = .red
            }

            //step 3
            if foo == true {
                label.frame = CGRect(x: self.frame.size.width/2 - WH/2, y: self.frame.size.height/2 - WH/2, width: WH, height: WH)
                self.addSubview(label)
            } else {
                label.frame = CGRect(x: self.center.x - WH/2, y: self.center.y - WH/2, width: WH, height: WH)
                self.superview?.addSubview(label)
            }
            //step 4
            UIView.animate(withDuration: 0.8, animations: {
                label.frame.origin.y = foo ? -100 : (self.center.y - 100)
                label.alpha = 0
            }, completion: { _ in
                label.removeFromSuperview()
            })
        }
    }


    fileprivate func initLayer() {
        self.backgroundColor = .black
        self.layer.cornerRadius = _width/2
        self.sizeToFit()

        if let numberLabel = numberLabel {
            numberLabel.text = String(networkNumber)
            numberLabel.textColor = .white
            numberLabel.textAlignment = .center
            numberLabel.adjustsFontSizeToFitWidth = true
            numberLabel.isHidden = true
            numberLabel.frame = CGRect(x:0, y:0, width:_width, height:_height)
            self.addSubview(numberLabel)
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(Bubble.tap))
        self.addGestureRecognizer(tapGesture)

        let longTap = UILongPressGestureRecognizer.init(target: self, action: #selector(Bubble.longTap))
        self.addGestureRecognizer(longTap)
    }

    func changeSideDisplay() {
        UIView.animate(withDuration: 0.5, delay: 0.1, usingSpringWithDamping: 0.5,
                       initialSpringVelocity: 5, options: .curveEaseInOut, animations: {
                       }, completion: nil)
    }

    func updateOrientation(newSize: CGSize) {
        let oldSize = CGSize(width: newSize.height, height: newSize.width)
        let percent = center.y / oldSize.height * 100
        let newOrigin = newSize.height * percent / 100
        let originX = frame.origin.x < newSize.height / 2 ? _width/8*4.25 : newSize.width - _width/8*4.25
        self.center = CGPoint(x: originX, y: newOrigin)
    }

    //MARK: - init
    override init(frame: CGRect) {
        super.init(frame: frame)
        initLayer()

        //添加手势
        let selector = #selector(Bubble.panDidFire(panner:))
        let panGesture = UIPanGestureRecognizer(target: self, action: selector)
        self.addGestureRecognizer(panGesture)

        //notification
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "reloadHttp_CocoaDebug"), object: nil, queue: OperationQueue.main) { [weak self] notification in
            self?.reloadHttp_notification(notification)
        }

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "deleteAllLogs_CocoaDebug"), object: nil, queue: OperationQueue.main) { [weak self] _ in
            self?.deleteAllLogs_notification()
        }

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "SHOW_COCOADEBUG_FORCE"), object: nil, queue: OperationQueue.main) { [weak self] _ in
            self?.show_cocoadebug_force()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        //notification
        NotificationCenter.default.removeObserver(self)
    }

    // FIX 3: begitu safe area diketahui / berubah (rotasi, pindah scene),
    // tarik bubble kembali ke rentang yang sah.
    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        clampCenterIntoSafeArea()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        clampCenterIntoSafeArea()
    }

    private func clampCenterIntoSafeArea() {
        guard self.window != nil else {return}
        let range = allowedCenterYRange
        guard !range.contains(center.y) else {return}

        let newY = min(max(center.y, range.lowerBound), range.upperBound)
        center = CGPoint(x: center.x, y: newY)
        CocoaDebugSettings.shared.bubbleFrameX = Float(center.x)
        CocoaDebugSettings.shared.bubbleFrameY = Float(newY)
    }

    //MARK: - notification
    //网络通知
    @objc func reloadHttp_notification(_ notification: Notification) {

        guard let userInfo = notification.userInfo else {return}
        let statusCode = userInfo["statusCode"] as? String

        if _successStatusCodes.contains(statusCode ?? "") {
            self.initLabelEvent("🚀", true)
        }
        else if statusCode == "0" { //"0" means network unavailable
            self.initLabelEvent("❌", true)
        }
        else {
            guard let statusCode = statusCode else {return}
            self.initLabelEvent(statusCode, true)
        }


        self.networkNumber = (self.networkNumber ) + 1
        self.numberLabel?.text = String(networkNumber)


        if self.networkNumber == 0 {
            self.numberLabel?.isHidden = true
        } else {
            self.numberLabel?.isHidden = false
        }

        if networkNumber >= 0 && networkNumber < 10 {
            self.numberLabel?.font = UIFont.boldSystemFont(ofSize: 11)
        } else if networkNumber >= 10 && networkNumber < 100 {
            self.numberLabel?.font = UIFont.boldSystemFont(ofSize: 11)
        } else if networkNumber >= 100 && networkNumber < 1000 {
            self.numberLabel?.font = UIFont.boldSystemFont(ofSize: 9)
        } else if networkNumber >= 1000 && networkNumber < 10000 {
            self.numberLabel?.font = UIFont.boldSystemFont(ofSize: 7.5)
        } else {
            self.numberLabel?.font = UIFont.boldSystemFont(ofSize: 7)
        }
    }


    @objc func deleteAllLogs_notification() {
        self.networkNumber = 0

        self.numberLabel?.text = String(networkNumber)

        if self.networkNumber == 0 {
            self.numberLabel?.isHidden = true
        } else {
            self.numberLabel?.isHidden = false
        }
    }

    @objc func show_cocoadebug_force() {
        CocoaDebugSettings.shared.showBubbleAndWindow = !CocoaDebugSettings.shared.showBubbleAndWindow
        CocoaDebugSettings.shared.showBubbleAndWindow = !CocoaDebugSettings.shared.showBubbleAndWindow
    }


    //MARK: - target action
    @objc func tap() {
        delegate?.didTapBubble()
    }

    @objc func longTap() {
        _HttpDatasource.shared().reset()
        CocoaDebugSettings.shared.networkLastIndex = 0
        NotificationCenter.default.post(name: NSNotification.Name("deleteAllLogs_CocoaDebug"), object: nil, userInfo: nil)
    }

    @objc func panDidFire(panner: UIPanGestureRecognizer) {
        if panner.state == .began {
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveLinear, animations: { [weak self] in
                self?.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            }, completion: nil)
        }

        let offset = panner.translation(in: self.superview)
        panner.setTranslation(CGPoint.zero, in: self.superview)
        var center = self.center
        center.x += offset.x
        center.y += offset.y
        self.center = center

        if panner.state == .ended || panner.state == .cancelled {

            let location = panner.location(in: self.superview)
            let velocity = panner.velocity(in: self.superview)

            var finalX: Double = Double(horizontalInset)
            var finalY: Double = Double(location.y)

            if location.x > UIScreen.main.bounds.size.width / 2 {
                finalX = Double(UIScreen.main.bounds.size.width) - Double(horizontalInset)
            }

            self.changeSideDisplay()

            let horizentalVelocity = abs(velocity.x)
            let positionX = abs(finalX - Double(location.x))

            let velocityForce = sqrt(pow(velocity.x, 2) * pow(velocity.y, 2))

            let durationAnimation = (velocityForce > 1000.0) ? min(0.3, positionX / Double(horizentalVelocity)) : 0.3

            if velocityForce > 1000.0 {
                finalY += Double(velocity.y) * durationAnimation
            }

            // FIX 4: clamp tanpa syarat ke rentang yang sah.
            // Kode asli hanya meng-clamp kalau finalY SUDAH melewati
            // (screenHeight - verticalInset) -- ambangnya lupa mengurangi
            // insets.bottom, sehingga seluruh area home indicator dianggap valid
            // dan bubble bisa berhenti di sana, lalu tidak bisa digeser lagi
            // karena gesture sistem (swipe home) yang menang.
            let range = allowedCenterYRange
            finalY = min(max(finalY, Double(range.lowerBound)), Double(range.upperBound))

            //
            CocoaDebugSettings.shared.bubbleFrameX = Float(finalX)
            CocoaDebugSettings.shared.bubbleFrameY = Float(finalY)

            //
            UIView.animate(withDuration: durationAnimation * 5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 6, options: .allowUserInteraction, animations: { [weak self] in
                self?.center = CGPoint(x: finalX, y: finalY)
                self?.transform = CGAffineTransform.identity
            }, completion:nil)
        }
    }
}
