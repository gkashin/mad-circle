//
//  MadCircleViewController.swift
//  MadCircle
//
//  Created by Георгий Кашин on 03.04.2021.
//

import UIKit

struct MadCircleViewControllerConstants {
    static let clearButtonTitle = "Clear"
    static let minSpeed: CGFloat = 0
    static let maxSpeed: CGFloat = 1
    static let circleDiameter: CGFloat = 50
    static let circleOpacity: Float = 0.5
    
    struct Arrow {
        static let arrowOpacity: Float = 0.3
        static let arrowWidth: CGFloat = 1
        static let arrowPointerLineLength: CGFloat = 10
    }
}

final class MadCircleViewController: UIViewController {

    // MARK: Stored Properties
    private let slider = UISlider()
    private var clearButton: UIButton!
    private var madCircle: UIView!
    
    private var speed: CGFloat = MadCircleViewControllerConstants.maxSpeed
    private var colors: [UIColor] = [.systemYellow, .systemBlue, .systemGreen]
    private var locations = [CGPoint]()
    
    
    // MARK: UIViewController Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        // Take new touch location
        let newLocation = touch.location(in: view)
        // Save previous location
        let oldLocation = self.madCircle.center
        
        // If moving has not finished yet
        if madCircle.layer.animationKeys() != nil {
            // Save location to stack
            locations.append(newLocation)
        } else {
            // If not, add animation for moving
            animateMoving(from: oldLocation, to: newLocation) { [weak self] in
                guard let self = self else { return }
                // If there are locations in the stack -> call touchesEnded recursively upon completion
                self.touchesEnded(touches, with: event)
            }
        }
    }
    
    
    // MARK: Actions
    /// Remove trajectories from view
    @objc private func clearButtonTapped() {
        guard view.layer.sublayers != nil else { return }
        for subLayer in view.layer.sublayers! where subLayer is CAShapeLayer {
            subLayer.removeFromSuperlayer()
        }
    }
    
    /// Handle slider
    @objc private func sliderChangedValue(_ sender: UISlider) {
        speed = MadCircleViewControllerConstants.maxSpeed - CGFloat(slider.value)
    }
}

// MARK: - UI
private extension MadCircleViewController {
    func setupUI() {
        view.backgroundColor = .white
        setupSlider()
        setupClearButton()
        setupMadCircle()
    }
    
    func setupSlider() {
        view.addSubview(slider)
        slider.center = CGPoint(x: view.frame.width - 75, y: 75)
        slider.minimumValue = Float(MadCircleViewControllerConstants.minSpeed)
        slider.maximumValue = Float(MadCircleViewControllerConstants.maxSpeed)
        slider.thumbTintColor = colors.randomElement()
        slider.addTarget(self, action: #selector(sliderChangedValue), for: .valueChanged)
    }
    
    func setupClearButton() {
        clearButton = UIButton(frame: CGRect(x: 20, y: 0, width: 50, height: 30))
        view.addSubview(clearButton)
        clearButton.center.y = slider.center.y
        clearButton.setTitle(MadCircleViewControllerConstants.clearButtonTitle, for: .normal)
        clearButton.setTitleColor(.systemGray, for: .normal)
        clearButton.addTarget(self, action: #selector(clearButtonTapped), for: .touchUpInside)
    }
    
    func setupMadCircle() {
        madCircle = UIView(frame: CGRect(x: 0, y: 0, width: MadCircleViewControllerConstants.circleDiameter, height: MadCircleViewControllerConstants.circleDiameter))
        view.addSubview(madCircle)
        madCircle.layer.cornerRadius = 0.5 * MadCircleViewControllerConstants.circleDiameter
        madCircle.clipsToBounds = true
        madCircle.backgroundColor = colors.randomElement()
        madCircle.center = view.center
        madCircle.layer.opacity = MadCircleViewControllerConstants.circleOpacity
    }
    
    func animateMoving(from oldLocation: CGPoint, to newLocation: CGPoint, completion: @escaping () -> Void) {
        UIView.animate(withDuration: TimeInterval(speed)) { [weak self] in
            guard let self = self else { return }
            var newLocation = newLocation
            // If there are locations in the stack
            if !self.locations.isEmpty {
                // Take the first
                newLocation = self.locations.removeFirst()
            }
            // If not, take the last touch point
            self.madCircle.center = newLocation
            // Draw arrow for trajectory
            self.drawArrow(from: oldLocation, to: newLocation)
        } completion: { [weak self] _ in
            guard let self = self else { return }
            // If there are locations in the stack -> call touchesEnded recursively upon completion
            guard !self.locations.isEmpty else { return }
            completion()
        }
    }
    
    func drawArrow(from oldLocation: CGPoint, to newLocation: CGPoint) {
        let arrow = UIBezierPath()
        arrow.addArrow(start: oldLocation, end: newLocation, pointerLineLength: MadCircleViewControllerConstants.Arrow.arrowPointerLineLength, arrowAngle: CGFloat(Double.pi / 4))
        
        let arrowLayer = CAShapeLayer()
        arrowLayer.opacity = MadCircleViewControllerConstants.Arrow.arrowOpacity
        arrowLayer.lineWidth = MadCircleViewControllerConstants.Arrow.arrowWidth
        arrowLayer.lineJoin = .round
        arrowLayer.lineCap = .round
        arrowLayer.lineDashPhase = .greatestFiniteMagnitude
        arrowLayer.fillColor = UIColor.clear.cgColor
        arrowLayer.strokeColor = UIColor.systemBlue.cgColor
        arrowLayer.path = arrow.cgPath
        view.layer.addSublayer(arrowLayer)
        
        let animation = createAnimation()
        arrowLayer.add(animation, forKey: "line")
    }
    
    func createAnimation() -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = MadCircleViewControllerConstants.minSpeed
        animation.toValue = MadCircleViewControllerConstants.maxSpeed
        animation.duration = TimeInterval(speed)
        return animation
    }
}

// MARK: - Add Arrow
private extension UIBezierPath {
    /// Create path for arrow
    func addArrow(start: CGPoint, end: CGPoint, pointerLineLength: CGFloat, arrowAngle: CGFloat) {
        self.move(to: start)
        self.addLine(to: end)

        let startEndAngle = atan((end.y - start.y) / (end.x - start.x)) + ((end.x - start.x) < 0 ? CGFloat(Double.pi) : 0)
        let arrowLine1 = CGPoint(x: end.x + pointerLineLength * cos(CGFloat(Double.pi) - startEndAngle + arrowAngle), y: end.y - pointerLineLength * sin(CGFloat(Double.pi) - startEndAngle + arrowAngle))
        let arrowLine2 = CGPoint(x: end.x + pointerLineLength * cos(CGFloat(Double.pi) - startEndAngle - arrowAngle), y: end.y - pointerLineLength * sin(CGFloat(Double.pi) - startEndAngle - arrowAngle))

        self.addLine(to: arrowLine1)
        self.move(to: end)
        self.addLine(to: arrowLine2)
    }
}
