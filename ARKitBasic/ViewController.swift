//
//  ViewController.swift
//  ARKitBasic
//
//  Created by 杉浦光紀 on 2019/02/18.
//  Copyright © 2019 杉浦光紀. All rights reserved.
//

import UIKit
import ARKit
import AVFoundation

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    
    let device = MTLCreateSystemDefaultDevice()!
    var planeGeometry: ARSCNPlaneGeometry?
    var detected: Bool = false
    var startingSettingGame: Bool = false
    
    var audioPlayer: AVAudioPlayer!
    
    var baseBoxNode: SCNNode = SCNNode()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let gesture = UITapGestureRecognizer(target: self, action: #selector(tapGesture))
        sceneView.addGestureRecognizer(gesture)
        Timer.scheduledTimer(timeInterval: 20, target: self, selector: #selector(self.setGame), userInfo: nil, repeats: false)
    }
    
    @objc func tapGesture(sender: UITapGestureRecognizer) {
        print("tapped!")
        let position = SCNVector3(0, 0, -0.5)
        let sphere = SCNSphere(radius: 0.05)
        let sphereNode = SCNNode(geometry: sphere)
        if let camera = sceneView.pointOfView {
            sphereNode.position = camera.convertPosition(position, to: nil)
            sphereNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
            sphereNode.physicsBody?.isAffectedByGravity = false;
            let x = sphereNode.position.x - camera.position.x
            let y = sphereNode.position.y - camera.position.y
            let z = sphereNode.position.z - camera.position.z
            sphereNode.physicsBody?.velocity = SCNVector3(x, y, z)
            sphereNode.physicsBody?.damping = 0
            sphereNode.physicsBody?.restitution = 2.0
            sphereNode.physicsBody?.contactTestBitMask = 1
            sphereNode.physicsBody?.categoryBitMask = 0b1011
            sphereNode.name = "tama"
        }
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.blue.withAlphaComponent(0.9)
        sphereNode.geometry?.materials = [material]

        sceneView.scene.rootNode.addChildNode(sphereNode)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.vertical]
        sceneView.debugOptions = [.showFeaturePoints]
        
        sceneView.delegate = self
        
        sceneView.scene.physicsWorld.contactDelegate = self
        
        sceneView.session.run(configuration)
        
        planeGeometry = ARSCNPlaneGeometry(device: device)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Pause the view's AR session.
        sceneView.session.pause()
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {fatalError()}
        if detected == true {
            return
        }
        let extentPlane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        let extentNode = SCNNode(geometry: extentPlane)
        extentNode.simdPosition = planeAnchor.center
        extentNode.eulerAngles.x = -.pi/2
        node.addChildNode(extentNode)

        detected = true
    }
    
    var wallNode: SCNNode = SCNNode()
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if startingSettingGame == true {
            return
        }
        guard let planeAnchor = anchor as? ARPlaneAnchor else {fatalError()}
        
        if node.childNodes.isEmpty == true {
            print("empty!!!!!!!!")
            return
        }
        let obj = node.childNodes[0]
        let geo = obj.geometry as? SCNPlane
        geo?.width = CGFloat(planeAnchor.extent.x)
        geo?.height = CGFloat(planeAnchor.extent.z)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.white.withAlphaComponent(0.8)
        geo?.materials = [material]
        node.childNodes[0].geometry = geo
        node.childNodes[0].simdPosition = planeAnchor.center
        wallNode = node.childNodes[0]
    }
    
    @objc func setGame() {
        print("setting game...")
        startingSettingGame = true
        
        // ゲームの奥の壁を作る
        let wallMaterial = SCNMaterial()
        wallMaterial.metalness.intensity = 0.1
        wallMaterial.roughness.intensity = 0.5
//        wallMaterial.diffuse.contents = UIColor.black
        wallMaterial.diffuse.contents = UIImage(named: "wall.jpg")
        wallNode.geometry?.materials = [wallMaterial]
        wallNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        wallNode.physicsBody?.collisionBitMask = 0b1011
        wallNode.physicsBody?.contactTestBitMask = 1
        
        createLightNode()
        createSideWalls()
        createBlocks()
        createPlayerPanel()
    }
    
    func createSideWalls() {
        let boudingBox = wallNode.boundingBox
        let width = boudingBox.max.x-boudingBox.min.x
        let height = boudingBox.max.y - boudingBox.min.y
        let plane = SCNPlane(width: CGFloat(width), height: CGFloat(height))
        let material = SCNMaterial()
//        material.diffuse.contents = UIColor.blue
        material.diffuse.contents = UIImage(named: "wall.jpg")
        material.isDoubleSided = true
        let planeNode1 = SCNNode(geometry: plane)
        planeNode1.geometry?.materials = [material]
        planeNode1.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        planeNode1.physicsBody?.contactTestBitMask = 1
        planeNode1.physicsBody?.collisionBitMask = 0b1011
        planeNode1.name = "wall"
        
        // 一つ目右の壁
        let theta = Float.pi / 2
        var move = SCNMatrix4(m11: cos(theta), m12: 0, m13: sin(theta) * (-1), m14: 0, m21: 0, m22: 1, m23: 0, m24: 0, m31: sin(theta), m32: 0, m33: cos(theta), m34: 0, m41: boudingBox.max.x, m42: 0, m43: boudingBox.max.x, m44: 1)
        planeNode1.transform = move
        wallNode.addChildNode(planeNode1)
        
        // 二つ目左の壁
        let planeNode2 = planeNode1.clone()
//        planeNode2.position = SCNVector3(x: boudingBox.min.x, y: 0, z: 0)
        move = SCNMatrix4(m11: cos(theta), m12: 0, m13: sin(theta) * (-1), m14: 0, m21: 0, m22: 1, m23: 0, m24: 0, m31: sin(theta), m32: 0, m33: cos(theta), m34: 0, m41: boudingBox.min.x, m42: 0, m43: boudingBox.max.x, m44: 1)
        planeNode2.transform = move
        wallNode.addChildNode(planeNode2)
        
        // 三つ目上の壁
        let planeNode3 = planeNode1.clone()
        move = SCNMatrix4MakeTranslation(0, boudingBox.max.y, boudingBox.max.y)
        let rot = SCNMatrix4MakeRotation(theta, 1, 0, 0)
        planeNode3.transform = SCNMatrix4Mult(rot, move)
        wallNode.addChildNode(planeNode3)
        
        // 四つ目下の壁
        let planeNode4 = planeNode1.clone()
        move = SCNMatrix4MakeTranslation(0, boudingBox.min.y, boudingBox.max.y)
        planeNode4.transform = SCNMatrix4Mult(rot, move)
        wallNode.addChildNode(planeNode4)
    }
    
    func createPlayerPanel() {
        let player = SCNBox(width: 0.2, height: 0.2, length: 0.001, chamferRadius: 0.01)
        let playerShape = SCNPhysicsShape(geometry: player, options: [
            SCNPhysicsShape.Option.scale: 1,
            SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.convexHull,
            SCNPhysicsShape.Option.keepAsCompound: true
            ])
        let playerNode = SCNNode(geometry: player)
        playerNode.castsShadow = false
        playerNode.opacity = 0.6
        playerNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: playerShape)
        playerNode.physicsBody?.contactTestBitMask = 1
        playerNode.physicsBody?.collisionBitMask = 0b1011
        if let camera = sceneView.pointOfView {
            playerNode.transform = SCNMatrix4MakeTranslation(0, 0, 0)
            camera.addChildNode(playerNode)
        }
    }
    
    func createLightNode() {
        let lightNodeDirection = SCNNode()
        lightNodeDirection.light = SCNLight()
        lightNodeDirection.light?.type = .directional
        lightNodeDirection.light?.castsShadow = true
        lightNodeDirection.light?.intensity = 150
        
        let lightNodeOmni = SCNNode()
        lightNodeOmni.light = SCNLight()
        lightNodeOmni.light?.type = .omni
        
        if let camera = sceneView.pointOfView {
            lightNodeDirection.position = camera.position
            lightNodeOmni.position = camera.position
        }
        
        sceneView.scene.rootNode.addChildNode(lightNodeDirection)
        sceneView.scene.rootNode.addChildNode(lightNodeOmni)
    }
    
    func createBlocks() {
        let boudingBox = wallNode.boundingBox
        print(boudingBox)
        let max_X = boudingBox.max.x
        let min_X = boudingBox.min.x
        let max_Y = boudingBox.max.y
        let min_Y = boudingBox.min.y
        
        let sizeScale: Float = 4
        let width = boudingBox.max.x / sizeScale
        let height = boudingBox.max.y / sizeScale
        
        let box = SCNBox(width: CGFloat(width), height: CGFloat(height), length: 0.05, chamferRadius: 0.01)
        let boxMaterial = SCNMaterial()
        boxMaterial.diffuse.contents = UIImage(named: "block.jpg")
        box.materials = [boxMaterial]
        let blockNode = SCNNode(geometry: box)
        blockNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        blockNode.physicsBody?.contactTestBitMask = 1
        blockNode.physicsBody?.collisionBitMask = 0b1011
        blockNode.name = "block"
        
        for _ in 0..<10 {
            let blockNode1 = blockNode.clone()
            let x = Float.random(in: min_X + width/2 ... max_X - width/2)
            let y = Float.random(in: min_Y + height/2 ... max_Y - height/2)
            blockNode1.transform = SCNMatrix4MakeTranslation(x, y, 0.05)
            wallNode.addChildNode(blockNode1)
        }
    }
}

extension ViewController: SCNPhysicsContactDelegate {
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        print("衝突!!!")
        playSound(name: "collision.mp3")
        let nodeA = contact.nodeA
        let nodeB = contact.nodeB
        
        if nodeA.name == "block" {
            nodeA.removeFromParentNode()
            return
        }
        if nodeB.name == "block" {
            nodeB.removeFromParentNode()
            return
        }
    }
}

extension ViewController: AVAudioPlayerDelegate {
    func playSound(name: String) {
        let soundPath = name.split(separator: ".").map { String($0) }
        if !isValidSoundPath(soundPath) {
            print("音源ファイル名が無効です。")
            return
        }
        
        guard let path = Bundle.main.path(forResource: soundPath[0], ofType: soundPath[1]) else {
            print("音源ファイルが見つかりません")
            return
        }
        
        do {
            // AVAudioPlayerのインスタンス化
            audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
            
            // AVAudioPlayerのデリゲートをセット
            audioPlayer.delegate = self
            
            // 音声の再生
            audioPlayer.play()
        } catch {
        }
    }
    func isValidSoundPath(_ soundPath: [String]) -> Bool {
        // ここは目的とか状況によって柔軟に。
        // たとえば拡張子によって判定するとか
        return soundPath.count == 2
    }
}
