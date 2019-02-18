//
//  ViewController.swift
//  ARKitBasic
//
//  Created by 杉浦光紀 on 2019/02/18.
//  Copyright © 2019 杉浦光紀. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    
    let device = MTLCreateSystemDefaultDevice()!
    var planeGeometry: ARSCNPlaneGeometry?
    var detected: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let gesture = UITapGestureRecognizer(target: self, action: #selector(tapGesture))
        sceneView.addGestureRecognizer(gesture)
    }
    
    @objc func tapGesture(sender: UITapGestureRecognizer) {
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
            sphereNode.physicsBody?.restitution = 1.5
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
        
        sceneView.session.run(configuration)
        
        planeGeometry = ARSCNPlaneGeometry(device: device)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Pause the view's AR session.
        sceneView.session.pause()
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if detected == true {
            return
        }
        
        // Place content only for anchors found by plane detection.
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        planeGeometry?.update(from: planeAnchor.geometry)
        
        _ = addPlaneNode(on: node, geometry: planeGeometry!, contents: UIColor.green.withAlphaComponent(0.5))
        
        detected = true
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {fatalError()}
        planeGeometry?.update(from: planeAnchor.geometry)
    }
    
    func addPlaneNode(on node: SCNNode, geometry: SCNGeometry, contents: Any) -> SCNNode {
        guard let material = geometry.materials.first else { fatalError() }
        
        if let program = contents as? SCNProgram {
            material.program = program
        } else {
            material.diffuse.contents = contents
        }
        
        let planeNode = SCNNode(geometry: geometry)
        planeNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        
        DispatchQueue.main.async(execute: {
            node.addChildNode(planeNode)
        })
        
        return planeNode
    }

}

