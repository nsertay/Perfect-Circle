//
//  ViewController.swift
//  Perfect Circle
//
//  Created by Nurmukhanbet Sertay on 22.04.2023.
//

import UIKit

class ViewController: UIViewController {

    var drawingView: DrawingView!
    let blackView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
    let resultLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 50))
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
        drawingView = DrawingView(frame: view.frame)
        drawingView.backgroundColor = .white
        view.addSubview(drawingView)
        
        blackView.layer.cornerRadius = blackView.frame.width / 2
        blackView.center = self.view.center
        blackView.backgroundColor = UIColor.black
        self.view.addSubview(blackView)
        
        resultLabel.center = CGPoint(x: self.view.center.x, y: self.view.center.y + 50)
        resultLabel.textAlignment = .center
        resultLabel.textColor = .black
        resultLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        view.addSubview(resultLabel)
    }
}


class DrawingView: UIView {

    var lastPoint = CGPoint.zero
    var strokeColor = UIColor.black.cgColor
    var strokeWidth: CGFloat = 5.0
    var distance: CGFloat = 0
    var distanceArray: [Double] = []
    var lastTouchTime: TimeInterval?
    let maxTimeBetweenTouches: TimeInterval = 0.2

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        lastPoint = touch.location(in: self)
        lastTouchTime = touch.timestamp
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let currentPoint = touch.location(in: self)

        //Демонстрировать в процентах насколько круг идеален
        let idealness = calculateCircleIdealness(distances: distanceArray)
        print(idealness)
        if let vc = self.superview?.next as? ViewController {
            vc.resultLabel.text = "\(idealness) %"
        }

        //Высвечивать ошибку, если игрок рисует слишком медленно
        let timeSinceLastTouch = touch.timestamp - (lastTouchTime ?? touch.timestamp)
        if timeSinceLastTouch > maxTimeBetweenTouches {
            clear()
        }

        UIGraphicsBeginImageContext(self.frame.size)
        guard let context = UIGraphicsGetCurrentContext() else { return }
        layer.render(in: context)

        context.move(to: lastPoint)
        context.addLine(to: currentPoint)
        context.setLineCap(.round)
        context.setBlendMode(.normal)
        context.setLineWidth(strokeWidth)
        context.setStrokeColor(strokeColor)
        context.strokePath()

        layer.contents = UIGraphicsGetImageFromCurrentImageContext()?.cgImage
        UIGraphicsEndImageContext()

        lastPoint = currentPoint
        lastTouchTime = touch.timestamp

        let centerX = self.bounds.midX
        let centerY = self.bounds.midY
        let centerPoint = CGPoint(x: centerX, y: centerY)

        let vector = CGVector(dx: lastPoint.x - centerPoint.x, dy: lastPoint.y - centerPoint.y)
        distance = sqrt(vector.dx * vector.dx + vector.dy * vector.dy)
        distanceArray.append(distance)
        
        //По мере ухудшения качества круга изменять цвет в более красный
        switch distance {
        case 0...75 :
            //Высвечивать ошибку, если игрок рисует слишком близко к точке
            clear()
        case distanceArray[0]*0.77...distanceArray[0]*0.87:
            strokeColor = UIColor.yellow.cgColor
        case distanceArray[0]*0.88...distanceArray[0]*1.12:
            strokeColor = UIColor.systemGreen.cgColor
        case distanceArray[0]*1.13...distanceArray[0]*1.21:
            strokeColor = UIColor.yellow.cgColor
        default:
            strokeColor = UIColor.red.cgColor
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesMoved(touches, with: event)
        distance = 0
        distanceArray = []
        clear()
    }
    
    // MARK: - Clear
    func clear() {
        layer.contents = nil
    }
    
    // MARK: - Calculate Circle Idealness
    func calculateCircleIdealness(distances: [Double]) -> String {
        let radius = distances.reduce(0, +) / Double(distances.count)
        let variance = distances.map { pow($0 - radius, 2) }.reduce(0, +) / Double(distances.count)
        let rSquared = 1 - variance / pow(radius, 2)
        
        if rSquared > 0.95 {
            let idealnessPercent = (rSquared - 0.95) / (1 - 0.95) * 100
            let resultText = String(format: "%.2f %", idealnessPercent)
            return resultText
        } else {
            return ""
        }
    }
}

