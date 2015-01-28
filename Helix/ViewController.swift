//
//  ViewController.swift
//  Helix
//
//  Created by Morgan Wilde on 11/01/2015.
//  Copyright (c) 2015 Morgan Wilde. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit

class ViewController: UIViewController {

    @IBOutlet weak var controlsParent: UIView!
    @IBOutlet weak var sceneView: SCNView!
    
    var helixPitch: Float = 1
    var helixNode: SCNNode = SCNNode()
    var timer: NSTimer = NSTimer()
    var time: Float = 0
    // Animation related variables
    var settings: [String: Float] = [
        "amplitude": 1,
        "period": 5,
        "phase": 0,
        "quality": 1
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupControls()
        setupScene()
        updateHelixNode()
        setupRoom()
    }
    override func viewDidAppear(animated: Bool) {
        animationBegin()
    }
    
    func setupControls() {
        controlsParent.backgroundColor = UIColor(red: 0.25, green: 0.25, blue: 0.25, alpha: 0.8)
    }
    func setupScene() {
        let scene = SCNScene()
        
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3Make(0, 0, 50)
        scene.rootNode.addChildNode(cameraNode)
        
        sceneView.scene = scene
        sceneView.autoenablesDefaultLighting = true
        sceneView.allowsCameraControl = true
        
        sceneView.scene = scene
    }
    func setupRoom() {
        let length: Float = 40
        let lengthCG = CGFloat(length)
        let backSideGeometry = SCNPlane(width: lengthCG*2, height: lengthCG)
        //backSideGeometry.firstMaterial?.doubleSided = true
        let roofGeometry = backSideGeometry
        let floorGeometry = backSideGeometry
        let backSideNode = SCNNode(geometry: backSideGeometry)
        let roofNode = SCNNode(geometry: roofGeometry)
        let floorNode = SCNNode(geometry: floorGeometry)
        backSideNode.transform = SCNMatrix4MakeTranslation(0, 0, -length/2)
        
        let rotation = SCNMatrix4MakeRotation(Float(M_PI)/2, 1, 0, 0)
        let translation = SCNMatrix4MakeTranslation(0, 0, -length/2)
        roofNode.transform = SCNMatrix4Mult(translation, rotation)
        
        floorNode.transform = SCNMatrix4Mult(SCNMatrix4MakeTranslation(0, 0, -length/2), SCNMatrix4MakeRotation(Float(M_PI)/2, 1, 0, 0))
        floorNode.transform = SCNMatrix4Rotate(floorNode.transform, Float(M_PI), 1, 0, 0)
        
        sceneView.scene!.rootNode.addChildNode(backSideNode)
        sceneView.scene!.rootNode.addChildNode(roofNode)
        sceneView.scene!.rootNode.addChildNode(floorNode)
    }
    func updateHelixNode() {
        helixNode.removeFromParentNode()
        let quality = settings["quality"]! == 1 ? true : false
        helixNode = HelixVertexArray(width: 10, height: 30, depth: 10, pitch: helixPitch, quality: quality).getNode()
        
        // Translate
        let translationMatrix = SCNMatrix4MakeTranslation(0, 15*helixPitch - 15, 10)
        helixNode.transform = SCNMatrix4Rotate(translationMatrix, Float(M_PI), 1, 1, 0)
        
        sceneView.scene!.rootNode.addChildNode(helixNode)
    }
    
    // Animation related methods
    func animateHelix() {
        helixPitch = stepFunction(time)
        time += 1
        updateHelixNode()
    }
    func stepFunction(time: Float) -> Float {
        let radians = (30*time + 90)/180 * Float(M_PI)
        let step = 1 + 0.65 * cosf(1 * radians)

        let amplitude: Float = settings["amplitude"]! // how much the spring compresses
        let period: Float = (settings["period"]!*360/180) * Float(M_PI)
        let phase: Float = (settings["phase"]!/180) * Float(M_PI) // Starting point
        
        let omega = (2*Float(M_PI))/period

        return settings["amplitude"]! + amplitude * cosf(omega * time + phase)
    }
    
    @IBAction func animateButtonTouch(sender: AnyObject) {
        animationBegin()
    }
    func animationBegin() {
        timer.invalidate()
        time = 0
        timer = NSTimer.scheduledTimerWithTimeInterval(0.01, target: self, selector: Selector("animateHelix"), userInfo: nil, repeats: true)
    }

    @IBAction func alterAmplitude(sender: UIStepper) {
        settings["amplitude"] = Float(sender.value)
    }
    @IBAction func alterPeriod(sender: UIStepper) {
        settings["period"] = Float(sender.value)
    }
    @IBAction func alterPhase(sender: UIStepper) {
        settings["phase"] = Float(sender.value)
    }
    @IBAction func switchDefinition(sender: UISwitch) {
        settings["quality"] = sender.on ? 1 : 0
        println("switched")
    }
}

